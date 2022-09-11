# Git Config

The WebKit project outlines a simplified recommended setup. This section outlines in greater detail other configuration options certain contributors may prefer.

## Remotes

### Forking

Since `git` is a decentralized version control system, a local copy can work with any remote that has the same set of shas. GitHub pull requests take advantage of this. After running [`git-webkit setup`](/WebKit/WebKit/wiki/Contributing#setup), the `.git/config` in the local WebKit repository should look something like this:

```
[remote "origin"]
    url = https://github.com/WebKit/WebKit.git
    fetch = +refs/heads/*:refs/remotes/origin/*
[remote "<username>"]
    url = https://github.com/<username>/WebKit.git
    fetch = +refs/heads/*:refs/remotes/<username>/*
[remote "fork"]
    url = https://github.com/<username>/WebKit.git
    fetch = +refs/heads/*:refs/remotes/fork/*
```

Now, if a contributor runs `git push fork eng/some-branch`, `eng/some-branch` will be pushed to the remote `fork`, which should correspond to that contributor's personal fork of the WebKit project on GitHub. Likewise, running `git checkout remotes/fork/eng/some-branch` will checkout `eng/some-branch` according to that contributor's `fork` remote.

[`git-webkit setup`](/WebKit/WebKit/wiki/Contributing#setup) also configures a remote with a contributors GitHub username. This is because if other contributors would like to checkout code from a pull request which they do not own, contributors will need to add this:

```
[remote "<username>"]
    url = https://github.com/<username>/WebKit.git
    fetch = +refs/heads/*:refs/remotes/<username>/*
```

to their `.git/config` and run `git checkout remotes/<username>/eng/some-branch`. This is what `git-webkit checkout pr-#` and EWS machines do to retrieve a contributor's change.

## Configuration Options

[`git-webkit setup`](/WebKit/WebKit/wiki/Contributing#setup) automatically sets or prompts the contributor to define a number of `git` configuration options. Most contributors  should use the defaults recommended by [`git-webkit setup`](/WebKit/WebKit/wiki/Contributing#setup). This section defines, in detail, what an option does and why the WebKit project recommends a certain setting.

### user.email

Prompts:
```
Set '<email>' as the git user email for this repository
Enter git user email for this repository: 
```

The `user.email` option is usually configured globally, and will become the contact information in `git` when authoring or committing a change. This is also the part of a commit that GitHub uses when attributing commits to specific users. The email a contributor defines here should be one of that contributor's emails in GitHub so that changes are correctly attributed to the contributor.

The WebKit project asks contributors to define this value for their WebKit repository specifically because a contributor's reported email may change over time, and may even differ between machines. [`git-webkit setup`'s](/WebKit/WebKit/wiki/Contributing#setup) prompt is an effort to make contributors think about what their reported contact information for this specific checkout should be.

Note that the author and committer listed in a `git` commit can easily be spoofed, so `user.email` plays no part in authentication. It is strictly for communication to other contributors.

### user.name

Prompts:
```
Set '<name>' as the git user name for this repository
Enter git user name for this repository: 
```

The `user.name` option is usually configured globally, and will become the listed name in `git` when authoring or committing a change. The name a contributor defines here should be one that individual expects other contributors to use when interacting with them.

Note that the author and committer listed in a `git` commit can easily be spoofed, so `user.name` plays no part in authentication. It is strictly for communication to other contributors.

### pull.rebase

When a contributor is updating a branch from a remote, a local branch may have commits that do not exist on the remote. This usually happens when a contributor is committing local changes. `git` supports "rebasing" and "merging" in these cases.

"rebasing" means updating the local branch reference to match the remote and then re-applying local commits on top of the tip of the updated branch. For changes which are small relative to the size of the repository, this is the cleanest method of applying local changes to an updated branch.

"merging" means creating a new "merge commit" which has both the most recent commit from the newly updated remote and the most recent local commit as its parents. This technique is useful if the number and magnitude of local commits are large relative to the size of the repository. Note that many project explicitly ban pushing merge commits because they can make bisection and reasoning about continuous integration difficult.

The `pull.rebase` configuration will automatically use a `rebase` workflow when running `git pull`. The WebKit project strongly recommends a `rebase` workflow and does not allow merge commits on `main` and other protected branches.

### color.status/color.diff/color.branch

Prompts:
```
Auto-color status, diff, and branch for this repository?
```

Applies coloring to various `git` commands, most notably `git log` and `git diff`. A number of `git-webkit` commands also use this configuration setting when deciding when to display color. Most users will want to use `auto`, although contributors who are colorblind may wish to either customize these colors or disable them completely.

### diff.*

`diff` options will apply to different file types and modify the output of `git diff` to be more human-readable.

### core.editor

Prompts:
```
Pick a commit message editor for this repository:
    1) [default]
    2) Sublime
    3) vi
    4) open
```

When creating or editing commit messages, `git` will invoke an external editor. By default on most systems, this is `vi`. The `core.editor` option lets a user of `git` change what editor they would like to use globally or within a repository. Note that the invocation of the editor should block until the user closes the editor.

### merge.*

`git` does basic automatic conflict resolution, but certain types of files may be difficult to resolve with what `git` provides. Specifying a `merge.driver` for a category of files can help automatically resolve conflicts in these files when running `git` commands, most notable, `git pull`. This is most common with frequently changing versioning files or ChangeLogs.

## WebKit Options

[`git-webkit`] respects a few options that are specific to the `webkitscmpy` library. [`git-webkit setup`](/WebKit/WebKit/wiki/Contributing#setup) does automatically configure some of these, [`metadata/project_config`](/WebKit/WebKit/blob/main/metadata/project_config) also contains a few default values for the project.

### webkitscmpy.pull-request

When responding to review feedback, contributors can either append commits to their original changes or force push and overwrite existing commits. `git-webkit pull-request` supports both workflows, and the `webkitscmpy.pull-request` option can be set to either `overwrite` or `append` to control which workflow `git-webkit` assumes a contributor is using.

### webkitscmpy.history

Prompts:
```
Would you like to create new branches to retain history when you overwrite
a pull request branch?
    1) [when-user-owned]
    2) disabled
    3) always
    4) never
```

Managing pull requests often involves force pushing. This may result in historical changes being lost as a contributor responds to feedback. `git-webkit` supports saving old branches for the duration of a pull request. Some projects may wish to aggressively disable this option with `never` because contributors do not own user-specific forks. `when-user-owned` is generally considered the default option, which will create history branches only when a contributor owns a remote fork and is using the `overwrite` workflow.

