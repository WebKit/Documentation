# Getting Started Contributing

WebKit has a rigorous code contribution process and policy in place to maintain the quality of code.

## Getting Setup to Contribute

Please run this command below to setup your environment to make pull requests.

```Bash
git webkit setup
```

The `setup` sub-command of [git-webkit](https://github.com/WebKit/WebKit/tree/main/Tools/Scripts/git-webkit) configures your local WebKit checkout for contributing code to the WebKit project. This script will occasionally prompt the user for input. The script does the following:

* Set your [name](/Deep Dive/GitHub/GitConfig.html#username) and [email address](/Deep Dive/GitHub/GitConfig.html#useremail) for the WebKit repository
* [Make Objective-C diffs easier to digest](/Deep Dive/GitHub/GitConfig.html#diff)
* Setup a commit message generator
* Set an [editor for commit messages](/Deep Dive/GitHub/GitConfig.html#coreeditor)
* Store a [GitHub API token](https://github.com/settings/tokens) in your system credential store
* Configure `git` to use the [GitHub API token](https://github.com/settings/tokens) when prompted for credentials, if using the HTTPS remote
* Create a [user owned fork](/Deep Dive/GitHub/GitConfig.html#Forking) of the WebKit repository

## Submitting a pull request

Firstly, please make sure you [file a bug](https://bugs.webkit.org) for the thing you are adding or fixing! Or, find a bug that you think is relevant to the fix you are making.

Assuming you are working off "main" branch, once your patch is working and [tests are passing](#correctness-testing-in-webkit), simply run:

```Bash
git webkit pr --issue <your bug number here>
```

That will pull down the details from [bugs.webkit.org](https://bugs.webkit.org), create a new git branch, and generate a commit message for you.
If necessary, please add additional details describing what you've added, modified, or fixed.

Once your pull request is on GitHub, the Early Warning System (a.k.a. EWS) will automatically build and run tests against your code change.
This allows contributors to find build or test failures before committing code changes to the WebKit’s repository.

Note, if you'd like to submit a draft pull request, you can do so by running:

```Bash
git webkit pr --draft
```

## Addressing review feedback

After you receive review feedback on GitHub, you should collaborate with the reviewer to address the feedback.

Once done, you can update your pull request to include the changes by again simply running:

```Bash
git webkit pr
```

## Landing Changes

### Merge-Queue

To land a pull request, add the [`merge-queue`](https://github.com/WebKit/WebKit/labels?q=merge-queue) or [`unsafe-merge-queue`](https://github.com/WebKit/WebKit/labels?q=unfsafe-merge-queue) label to your pull request. These labels will put your pull request into the [Merge-Queue](https://ews-build.webkit.org/#/builders/74) and [Unsafe-Merge-Queue](https://ews-build.webkit.org/#/builders/75), respectively, which will commit your pull request to the WebKit repository

[Unsafe-Merge-Queue](https://ews-build.webkit.org/#/builders/75) inserts reviewer information into a commit's message and modified change logs. We then check to ensure that a pull request has been reviewed by checking the commit message before landing the change. [Unsafe-Merge-Queue](https://ews-build.webkit.org/#/builders/75) _does not_ validate that a pull request builds.

Along with the actions performed by [Unsafe-Merge-Queue](https://ews-build.webkit.org/#/builders/75), [Merge-Queue](https://ews-build.webkit.org/#/builders/74) will validate that a pull request builds and run layout tests before landing the change.

### git-webkit land

_Landing should be achieved via merge-queue, this outlines the current behavior of `git-webkit land`_

To land a change, run `git-webkit land` from the branch to be landed. Note that only a [committer](https://github.com/orgs/WebKit/teams/committers) has the privileges to commit a change to the WebKit repository. `git-webkit land` does the following:

* Check to ensure a pull-request is approved and not blocked
* Insert reviewer names into the commit message
* Rebase the pull-request against its parent branch
* [Canonicalize](/Deep Dive/GitHub/Source Control#canonicalization) the commits to be landed
* Update the pull-request with the landed commit

## Coding style

Code you write must follow WebKit’s [coding style guideline](https://webkit.org/contributing-code/#code-style-guidelines).
You can run `Tools/Scripts/check-webkit-style` to check whether your code follows the coding guidelines or not
(it can report false positives or false negatives).
If you use `Tools/Scripts/webkit-patch upload` to upload your patch,
it automatically runs the style checker against the code you changed so there is no need to run `check-webkit-style` separately.

The style checker cannot automatically fix the code style issues it finds. Supposing your patch was already commited as HEAD of your PR branch, you can re-format the code and amend your patch, as shown below:

```shell
Tools/Scripts/webkit-patch format -g HEAD
git commit -a --amend --no-edit
```

Then you can try `Tools/Scripts/webkit-patch upload` again.

Some older parts of the codebase do not follow these guidelines.
If you are modifying such code, it is generally best to clean it up to comply with the current guidelines.

## Convenience Tools

`Tools/Scripts/webkit-patch` provides a lot of utility functions like applying the latest patch on [bugs.webkit.org](https://bugs.webkit.org/) (`apply-from-bug`)
and uploading a patch (`upload --git-commit=<commit hash>`) to a [bugs.webkit.org](https://bugs.webkit.org/) bug.
Use `--all-commands` to the list of all commands this tool supports.

## Regression Tests

Once you have made a code change, you need to run the aforementioned tests (layout tests, API tests, etc...)
to make sure your code change doesn’t break existing functionality.
These days, uploading a patch on [bugs.webkit.org](https://bugs.webkit.org/) triggers the Early Warning System (a.k.a. EWS).

For any bug fix or a feature addition, there should be a new test demonstrating the behavior change caused by the code change.
If no such test can be written in a reasonable manner (e.g. the fix for a hard-to-reproduce race condition),
then the reason writing a tests is impractical should be explained in the accompanying commit message.

Any patch which introduces new test failures or performance regressions may be reverted.
It’s in your interest to wait for the Early Warning System to fully build and test your patch on all relevant platforms.

## Commit messages

Commit messages serve as change logs, providing historical documentation for all changes to the WebKit project.
Running `git-webkit setup` configures your git hooks to properly generate commit messages.

The first line shall contain a short description of the commit message (this should be the same as the Summary field in Bugzilla).
On the next line, enter the Bugzilla URL. 
Below the "Reviewed by" line, enter a detailed description of your changes. 
There will be a list of files and functions modified at the bottom of the commit message.
You are encouraged to add comments here as well. (See the commit below for reference).
Do not worry about the “Reviewed by NOBODY (OOPS!)” line, GitHub will update this field upon merging.

```
Allow downsampling when invoking Remove Background or Copy Subject
https://bugs.webkit.org/show_bug.cgi?id=242048

Reviewed by NOBODY (OOPS!).

Soft-link `vk_cgImageRemoveBackgroundWithDownsizing` from VisionKitCore, and call into it to perform
background removal when performing Remove Background or Copy Subject, if available. On recent builds
of Ventura and iOS 16, VisionKit will automatically reject hi-res (> 12MP) images from running
through subject analysis; for clients such as WebKit, this new SPI allows us to opt into
downsampling these large images, instead of failing outright.

* Source/WebCore/PAL/pal/cocoa/VisionKitCoreSoftLink.h:
* Source/WebCore/PAL/pal/cocoa/VisionKitCoreSoftLink.mm:
* Source/WebCore/PAL/pal/spi/cocoa/VisionKitCoreSPI.h:
* Source/WebKit/Platform/cocoa/ImageAnalysisUtilities.h:
* Source/WebKit/Platform/cocoa/ImageAnalysisUtilities.mm:
(WebKit::requestBackgroundRemoval):

Refactor the code so that we call `vk_cgImageRemoveBackgroundWithDownsizing` if it's available, and
otherwise fall back to `vk_cgImageRemoveBackground`.

* Source/WebKit/UIProcess/ios/WKContentViewInteraction.mm:
(-[WKContentView doAfterComputingImageAnalysisResultsForBackgroundRemoval:]):
(-[WKContentView _completeImageAnalysisRequestForContextMenu:requestIdentifier:hasTextResults:]):
(-[WKContentView imageAnalysisGestureDidTimeOut:]):
* Source/WebKit/UIProcess/mac/WebContextMenuProxyMac.mm:
(WebKit::WebContextMenuProxyMac::appendMarkupItemToControlledImageMenuIfNeeded):
(WebKit::WebContextMenuProxyMac::getContextMenuFromItems):

Additionally, remove the `cropRect` completion handler argument, since the new SPI function no
longer provides this information. The `cropRect` argument was also unused after removing support for
revealing the subject, in `249582@main`.
```

The “No new tests. (OOPS!)” line will appear if `git webkit commit` did not detect the addition of new tests.
If your patch does not require test cases (or test cases are not possible), remove this line and explain why you didn’t write tests.
Otherwise all changes require test cases which should be mentioned in the commit message.
