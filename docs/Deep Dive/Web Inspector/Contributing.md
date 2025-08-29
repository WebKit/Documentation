# Contributing to Web Inspector

## Modifying the Web Inspector

The Web Inspector user interface is implemented using JavaScript, CSS, and HTML. So, it's relatively easy to dig into the Web Inspector's sources and fix bugs or add new features.

This wiki page documents the minimal steps required to modify styles used by the Web Inspector and submit your changes as a patch for review.

Let's say, we don't like red color for CSS property names, and we would prefer property names to be purple instead. Let's get started!

## Inspect The Inspector

Since the Web Inspector UI is just another web page, we can inspect the Web Inspector with a second-level Web Inspector instance to quickly see what's going on. This requires a few magic settings to enable the "Inspect..." context menu on the Web Inspector window.

For the Mac port, set the following defaults to allow inspecting the inspector.

```
defaults write NSGlobalDomain WebKitDebugDeveloperExtrasEnabled -bool YES
```


After updating these settings, run the [https://developer.apple.com/safari/technology-preview/ Safari Technology Preview]. Then, open the Web Inspector and right-click to inspect the inspector itself.

By inspecting the CSS property names in the second-level inspector, we quickly find that the colors are defined by rules in `Source/WebInspectorUI/UserInterface/Views/SpreadsheetCSSStyleDeclarationEditor.css`. 
To create and submit a patch with our changes, we must to create an accompanying Bugzilla bug, and compute the diff of our changes against WebKit trunk.

## Create / Update a Bug Report

 * [Existing Web Inspector Bugs](https://bugs.webkit.org/buglist.cgi?query_format=advanced&short_desc_type=allwordssubstr&short_desc=&component=Web+Inspector&long_desc_type=substring&long_desc=&bug_file_loc_type=allwordssubstr&bug_file_loc=&keywords_type=allwords&keywords=&bug_status=UNCONFIRMED&bug_status=NEW&bug_status=ASSIGNED&bug_status=REOPENED&emailassigned_to1=1&emailtype1=substring&email1=&emailassigned_to2=1&emailreporter2=1&emailcc2=1&emailtype2=substring&email2=&bugidtype=include&bug_id=&votes=&chfieldfrom=&chfieldto=Now&chfieldvalue=&cmdtype=doit&order=Reuse+same+sort+as+last+time&field0-0-0=noop&type0-0-0=noop&value0-0-0=)
 * [Create New Web Inspector Bug](http://webkit.org/new-inspector-bug)

The WebKit project uses "bugs" in Bugzilla for fixes, new features, and any other code changes. Every commit must have an accompanying Bugzilla bug.

So, the first step is to ensure that your proposed enhancement or fix has an associated bug.

Once you find or create a bug report, make sure to add a comment stating your intent to work on the bug. 
This step is very important; comments on bugs in the Web Inspector Bugzilla component will automatically notify Web Inspector reviewers.

This will allow them to answer any questions you may have about a proposed fix, and give feedback, pointers, and guidance for solving the issue.

## Now Do Your Hacking

 1.  [Get the Code](https://webkit.org/getting-the-code/)

```
git clone https://github.com/WebKit/WebKit.git WebKit
cd WebKit
git checkout -b purple_css_values
```

 2. [Build WebKit](http://webkit.org/building/build.html)

```
Tools/Scripts/build-webkit --release
```

 A clean build takes 20-80 minutes depending on the vintage of your machine.

 3. [Run it](http://webkit.org/building/run.html)
 
```
Tools/Scripts/run-minibrowser --release
```

 4. Edit `Source/WebInspectorUI/UserInterface/Views/SpreadsheetCSSStyleDeclarationEditor.css` within the repo.

 5. Run `make -C Source/WebInspectorUI release` to copy files from `Source/WebInspectorUI/UserInterface` to the build directory. Do it after every time you modify Inspector's files.

 6. Look at your changes

```
git status
git diff Source/WebInspectorUI/
```

 7. [Submit a PR](https://webkit.org/contributing-code/#overview) and wait for a review!

```
git add -u
git commit
Tools/Scripts/git-webkit pull-request
```

If you have any questions there are always people willing to help! Just jump onto [webkit.slack.com](https://webkit.slack.com), #webkit-inspector channel.
