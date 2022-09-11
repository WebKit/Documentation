# Migration

WebKit has moved away from Subversion to Git, and contributors will need to migrate their local checkouts and workflows to GitHub. To determine which migration workflow you need, run the following command in your WebKit repository:

```
git remote -v
```

If you see something like:
```
fatal: not a git repository (or any parent up to mount point /Volumes)
Stopping at filesystem boundary (GIT_DISCOVERY_ACROSS_FILESYSTEM not set).
```
you have a [Subversion checkout](/WebKit/WebKit/wiki/Migration#subversion) and need to migrate to a GitHub checkout.

If you see something like:
```
origin    https://git.webkit.org/git/WebKit-https (fetch)
origin    https://git.webkit.org/git/WebKit-https (push)
```
or:
```
origin    https://git.webkit.org/git/WebKit (fetch)
origin    https://git.webkit.org/git/WebKit (push)
```
you have an [obsolete git mirror](/WebKit/WebKit/wiki/Migration#obsolete-mirror) for how to deal with patches uploaded to bugzilla.) and need to migrate to a GitHub checkout.

If you see something like:
```
origin    git@github.com:WebKit/WebKit.git (fetch)
origin    git@github.com:WebKit/WebKit.git (push)
```
you already have a GitHub checkout, and can skip to [setting up your checkout](/WebKit/WebKit/wiki/Contributing#setup).

## Subversion

Migrating from a Subversion checkout involves first cloning the WebKit repository with `git clone https://github.com/WebKit/WebKit.git <local path>`. A SSH based clone will work as well, but will require an [SSH key to be uploaded](https://github.com/settings/keys).

After your clone completes, [set up your checkout](/WebKit/WebKit/wiki/Contributing#setup). If you don't have local changes in your Subversion checkout, no more migration work is required. If you do have local changes, use `Tools/Scripts/svn-create-patch` to save those changes in a local `.patch` file and then run `Tools/Scripts/svn-apply` to apply that patch to your new GitHub clone. See [below](/WebKit/WebKit/wiki/Migration#webkit-patch) for how to deal with patches uploaded to bugzilla.

## Obsolete Mirror

The repository hosted via [github.com/WebKit/WebKit](https://github.com/WebKit/WebKit) has different commits from the ones hosted on [git.webkit.org](https://git.webkit.org). While it is possible convert an existing checkout, the WebKit team recomends that you freshly clone the WebKit repository with `git clone https://github.com/WebKit/WebKit.git <local path>`. A SSH based clone will work as well, but will require an [SSH key to be uploaded](https://github.com/settings/keys).

After your clone completes, [set up your checkout](/WebKit/WebKit/wiki/Contributing#setup). The WebKit team has not built automation to assist in migrating branches from [git.webkit.org](https://git.webkit.org) checkouts to [github.com/WebKit/WebKit](https://github.com/WebKit/WebKit) ones. However, the content on disk in both repositories is identical. That means that something like `git -C <oldpath> diff HEAD~1 | git -C <newpath> apply` will apply a commit from one checkout to the other, assuming the diff of the commit you're moving applies to commit you have checked out.

See [below](/WebKit/WebKit/wiki/Migration#webkit-patch) for how to deal with patches uploaded to bugzilla.

## webkit-patch

While `Tools/Scripts/webkit-patch` is being replaced by `Tools/Scripts/git-webkit` for developement workflows, `webkit-patch` does continue to work on GitHub based checkouts. In particular:
```
Tools/Scripts/webkit-patch apply-from-bug 238981
```
will apply the patch uploaded to [bug 238981](https://bugs.webkit.org/show_bug.cgi?id=238981) to a user's local checkout, even if that checkout is a GitHub based checkout. Simlarly, this command:
```
Tools/Scripts/webkit-patch upload
```
will upload local changes to the bugzilla bug mentioned in modified `ChangeLog` files, even if those local changes are committed to a pull request branch.

## webkit-patch Reverse Look-up

The table bellow includes a number of common `webkit-patch` commands and their `git-webkit` equivalences.

| `webkit-patch` | `git-webkit` | Description |
| --- | --- | --- |
| `webkit-patch apply-attachment` | `git-webkit checkout pr-#` | Get another contributor's unlanded change |
| `webkit-patch clean` | `git-webkit clean` | Discard uncommitted local changes |
| `webkit-patch create-revert <revisions>` | `git-webkit revert --pr <hash/identifier>` | Upload a proposal to revert a landed change |
| `webkit-patch help -a` | `git-webkit --help` | Print program help message |
| `webkit-patch land` | `git-webkit land` | Land a local change via Commit/Merge Queue |
| `webkit-patch land-unsafe` | `git-webkit land --unsafe` | Land a local change manually/via Unsafe Merge Queue |
| `webkit-patch prepare-revert <revisions>` | `git-webkit revert <hash/identifier>` | Revert a landed change locally |
| `webkit-patch setup-git-clone` | `git-webkit setup` | Configure a local checkout for development |
| `webkit-patch upload` | `git-webkit pr` | Upload a change for review |

