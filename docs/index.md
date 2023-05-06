---
hide:
  - navigation
---

# WebKit Overview

WebKit is a cross-platform web browser engine. On iOS and macOS, it powers Safari, Mail, iBooks, and many other applications.

## Getting Up and Running

#### Downloading the Source Code

```sh
git clone https://github.com/WebKit/WebKit.git WebKit
```

#### Building WebKit

Compilation instructions are for macOS. For other platforms additional instructions may be found [here](Build & Debug/BuildOptions.md).

```sh
cd WebKit
Tools/Scripts/build-webkit
```

#### Running Minibrowser

```sh
Tools/Scripts/run-minibrowser
```

#### (Optional) Add Scripts Directory to your PATH

```sh
export PATH=$PATH:`pwd`/Tools/Scripts
```

## Contribute

Congratulations! You’re up and running. Now you can begin coding in WebKit and contribute your fixes and new features to the project. 
For details on submitting your code to the project, read [Contributing Code](Getting Started/ContributingCode).

## Feature Status

Visit [WebKit Feature Status](https://webkit.org/status/) page to see which Web API has been implemented, in development, or under consideration.

## Trying the Latest

On macOS, [download Safari Technology Preview](https://webkit.org/downloads/) to test the latest version of WebKit. 
On Linux, download [Epiphany Technology Preview](https://webkitgtk.org/epiphany-tech-preview). 
On Windows, you will have to build it yourself.

## Reporting Bugs

1. [Search WebKit Bugzilla](https://bugs.webkit.org/query.cgi?format=specific&product=WebKit) to see if there is an existing report for the bug you've encountered.
2. [Create a Bugzilla account](https://bugs.webkit.org/createaccount.cgi) to to report bugs (and to comment on them) if you haven't done so already.
3. File a bug in accordance with [our guidelines](https://webkit.org/bug-report-guidelines/).

Once your bug is filed, you will receive email when it is updated at each stage in the [bug life cycle](https://webkit.org/bug-life-cycle). 
After the bug is considered fixed, you may be asked to download the [latest nightly](https://webkit.org/nightly) and confirm that the fix works for you.

## Staying in Touch

Before getting in touch with WebKit developers using any of the avenues below, make sure that you have checked our page on how to ask [questions about WebKit](https://webkit.org/asking-questions/).

You can find WebKit developers, testers, and other interested parties on the [#WebKit Slack workspace](https://webkit.slack.com/).
[Join the WebKit slack](https://join.slack.com/t/webkit/shared_invite/enQtOTU3NzQ3NTAzNjA0LTc5NmZlZWIwN2MxN2VjODVjNzEyZjBkOWQ4NTM3OTk0ZTc0ZGRjY2MyYmY2MWY1N2IzNTI2MTIwOGVjNzVhMWE),
and stay in touch.
