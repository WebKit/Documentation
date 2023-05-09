# Source Control

The information outlined in this section is intended for a future where Git is the source of truth for the project.

## Commit Representation

The WebKit project heavily relies on a linear, ordered history on the `main` branch to track regressions in the project. Historically, [Subversion](https://subversion.apache.org)'s revisions were used across our commit messages, bug tracking and services to achieve this goal. Our migration to `git` has required a new solution, because while `git` is capable on enforcing a linear and ordered history (so long as [merge commits](#merge-commits) are banned), `git` commits are traditionally represented as hashes, which are not trivially orderable the way [Subversion](https://subversion.apache.org)'s revisions are.

The WebKit teams has instead adopted a system where commits are represented based on their relationship to the default branch and number of ancestors they have, we have dubbed this representation the [commit identifier](#identifiers). Most tooling accepts `git` hashes, [Subversion](https://subversion.apache.org) revisions and identifiers, although the `Tools/Scripts/git-webkit` script can convert between the three representations locally, if the need arises.

To use this commit representation for local development, `Tools/Scripts/git-webkit` implements a `blame` and `log` sub-command that include [commit identifiers](#identifiers) and [Subversion](https://subversion.apache.org) revisions, if available.

```
Tools/Scripts/git-webkit blame Makefile

230258@main (Keith Rollin    2020-10-08 19:10:32 +0000  1) MODULES = Source Tools
184786@main (Jonathan Bedard 2017-02-02 18:42:02 +0000  2) 
229628@main (Keith Rollin    2020-09-22 18:37:51 +0000  3) define build_target_for_each_module
229628@main (Keith Rollin    2020-09-22 18:37:51 +0000  4)      for dir in $(MODULES); do \
229628@main (Keith Rollin    2020-09-22 18:37:51 +0000  5)              ${MAKE} $@ -C $$dir PATH_FROM_ROOT=$(PATH_FROM_ROOT)/$${dir}; \
229628@main (Keith Rollin    2020-09-22 18:37:51 +0000  6)              exit_status=$$?; \
229628@main (Keith Rollin    2020-09-22 18:37:51 +0000  7)              [ $$exit_status -ne 0 ] && exit $$exit_status; \
229628@main (Keith Rollin    2020-09-22 18:37:51 +0000  8)      done; true
229628@main (Keith Rollin    2020-09-22 18:37:51 +0000  9) endef
...
```

```
Tools/Scripts/git-webkit log

commit 240867@main (989ff515ce6e103271072dd1b397ac43572a910c, r281493)
Author: Adrian Perez de Castro <aperez@igalia.com>
Date:   Tue Aug 24 13:48:35 2021 +0000

    Non-unified build fixes, late August 2021
    https://bugs.webkit.org/show_bug.cgi?id=229440
    
    Unreviewed non-unified build fixes.
...
```

## Identifiers

Identifiers are the term the WebKit Team uses to refer to the representation of a commit our team has developed which uniquely identifies a commit based on that commit's relationship to the default branch and the number of ancestors that commit has.

Commit identifiers are of the following form:
```
<branch-point>.<number>@<branch>
```
where the `branch` is the name of a `git` branch the commit is on, the `number` is the number of ancestors that commit has (if the commit is on the default branch) or the number of ancestors that commit has since diverging from the default branch (if the commit is _not_ on the default branch) and `branch-point` optionally displays the number of ancestors on the default branch a commit has (only relevant for commits _not_ on the default branch).

The timeline bellow shows what identifiers looks like with multiple branches:
```
                      ———— o ————————————— o
                    /      |               |
                   /  101.2@branch-b  101.3@branch-b
                  ——————— o ———————————— o
                /         |              |
           /   101.1@branch-a  101.2@branch-a
——— o ———————— o ———————— o ——————— o ——————— o
    |          |          |         |         |
 100@main   101@main   102@main  103@main  104@main
```

It is worth noting that commits, especially those on branches, have multiple valid identifiers. In the above example, `101.1@branch-a` could also be referred to as `101.1@branch-b` and `101@main` could be referred to as `101.0@branch-a`. The WebKit team has defined the [canonical](#canonicalization) identifier for a given commit to be that commit's identifier on the least specific branch that commit is on. The metric for branch specificity is outlined in `Tools/Scripts/libraries/webkitscmpy/webkitscmpy/scm_base.py`, but can essentially be thought of like this:
```
default branch                               (least specific)
production branches
    "a" branch name
    "z" branch name
development branches (eng/*, dev/*. ect.)
    "a" branch name
    "z" branch name                          (most specific)
```

Conversion between native `git` refs and identifiers can be done with `Tools/Scripts/git-webkit find`:
```
Tools/Scripts/git-webkit find safari-611-branch

Title: Unreviewed build fix, rdar://problem/76412930
Author: Russell Epstein <repstein@apple.com>
Date: Fri Apr 16 14:34:51 2021
Revision: 276171
Hash: 67dd5465d8f5
Identifier: 232923.433@remotes/fork/safari-611-branch
```

```
git-webkit find 232923.400@safari-611-branch

Title: Revert "Cherry-pick r271794. rdar://problem/76375364"
Author: Commit Queue <commit-queue@webkit.org>
Date: Thu Apr 15 13:15:48 2021
Revision: 276064
Hash: dd1f0d38426c
Identifier: 232923.400@remotes/fork/safari-611-branch
```

Or through [commits.webkit.org](https://commits.webkit.org) if no checkout is available:
```
curl https://commits.webkit.org/safari-612-branch/json

{
    "author": {
        "emails": [
            "repstein@apple.com"
        ],
        "name": "Russell Epstein"
    },
    "branch": "safari-612-branch",
    "hash": "76f038bbe2889a3714c6176b3c9e35b404c57e35",
    "identifier": "240672.6@safari-612-branch",
    "message": "Versioning.\n\nWebKit-7612.2.1\n\nCanonical link: https://commits.webkit.org/240672.6@safari-612-branch\ngit-svn-id: https://svn.webkit.org/repository/webkit/branches/safari-612-branch@281269 268f45cc-cd09-0410-ab3c-d52691b4dbfc",
    "order": 0,
    "repository_id": "webkit",
    "revision": 281269,
    "timestamp": 1629406217
}
```

## Branch Management

The WebKit project aims to keep branches clean, development should be primarily done on forks of the repository owned by developers instead of on the WebKit repository itself. Branches pushed to the WebKit repository should either be production branches or temporary branches owned by automation.

### Production Branches

Most WebKit development should be done on `main`, which is our default branch. Note that [Subversion](https://subversion.apache.org)'s `trunk` branch tracked the same set of commits that the modern `main` branch does. `main` is protected by Commit Queue, as outlined in the [Permissions](#permissions) heading.

Other production branches are managed by specific platforms as part of their release cycle. Most notably, the `safari-*-branch` set of branches correspond to versions of WebKit released by Apple.

### Temporary Branches

Branches may be added, temporarily, by automation and contributors interacting with automation. The branches are expected to be deleted within 48 hours of being added to the project. Commit Queue is the most notable example of this. Branches named `commit-queue/*` and `fast-commit-queue/*` represent code to be committed to a production branch after passing a verification process. (NB, work in progress)

### Merge Commits

**The WebKit project forbids merge-commits on production branches.**

Merge-commits are a type of commit where a `git` commit may have multiple parents, the history of a merge commit looks something like this:
```
                  ——— o ———————————— o ————
                /                           \
           /                             \ 
——— o ———————— o ———————— o ——————— o ——————— o ——————— o
```

Merge-commits make bisection difficult, and make it hard for humans to reason about the code in a specific commit when working backwards. As a result, all production branches forbid merge commits.

## Permissions

Only [administers](https://github.com/orgs/WebKit/teams/administrators) and [Commit Queue](https://github.com/webkit-commit-queue) have direct access to `main`. Instead, committers are granted access to push branches named `commit-queue/*` and `fast-commit-queue`, which are then checked before being rebased and landed on `main` (NB, work in progress).

Branches matching `safari-*-branch` are managed by [Apple's Integrators](https://github.com/orgs/WebKit/teams/apple-integrators).

## Canonicalization

To make [identifiers](#identifiers) easier to user, Commit Queue adds those identifiers to commit messages via a link to [commits.webkit.org](https://commits.webkit.org). We call this process "canonicalization." In addition to adding identifiers to commit messages, canonicalization attempts to parse the commit message to correctly attribute changes which may be authored and committed by different contributors.

The task of canonicalization is owned by Commit Queue and is done immediately before pushing changes to a production branch. Canonicalization should not be preformed on non-production branches.

