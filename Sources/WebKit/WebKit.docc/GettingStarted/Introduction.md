# Introduction to WebKit

 WebKit is an open-source Web browser engine.
 It’s a framework in macOS and iOS, and used by many first party and third party applications including Safari, Mail, Notes, Books, News, and App Store.

## What is WebKit?

The WebKit codebase is mostly written in C++ with bits of C and assembly, primarily in JavaScriptCore, and some Objective-C to integrate with Cocoa platforms.

It primarily consists of the following components, each inside its own directory in [Source](https://github.com/WebKit/WebKit/tree/main/Source):

* **bmalloc** - WebKit’s malloc implementation as a bump pointer allocator. It provides an important security feature, called IsoHeap,
    which segregates each type of object into its own page to prevent type confusion attacks upon use-after-free.
* **WTF** - Stands for Web Template Framework. WebKit’s template library.
    The rest of the WebKit codebase is built using this template library in addition to, and often in place of, similar class templates in the C++ standard library.
    It contains common container classes such as Vector, HashMap (unordered), HashSet, and smart pointer types such as Ref, RefPtr, and WeakPtr used throughout the rest of WebKit.
* **JavaScriptCore** - WebKit’s JavaScript engine; often abbreviated as JSC.
    JSC parses JavaScript and generates byte code, which is then executed by one of the following four tiers.
    Many tiers are needed to balance between compilation time and execution time.
    Also see Phil's blog post about [Speculation in JavaScriptCore](https://webkit.org/blog/10308/speculation-in-javascriptcore/).
    * **Interpreter** - This tier reads and executes instructions in byte code in C++.
    * **Baseline JIT** - The first Just In Time compiler tier serves as the profiler as well as a significant speed up from the interpreter.
    * **DFG JIT** - Data Flow Graph Just In Time compiler uses the data flow analysis to generate optimized machine code.
    * **FTL JIT** - Faster than Light Just In Time compiler which uses [B3 backend](https://webkit.org/blog/5852/introducing-the-b3-jit-compiler/).
        It’s the fastest tier of JSC.
    JavaScriptCode also implements JavaScriptCore API for macOS and iOS applications.
* **WebCore** - The largest component of WebKit, this layer implements most of the Web APIs and their behaviors.
    Most importantly, this component implements HTML, XML, and CSS parsers and implements HTML, SVG, and MathML elements as well as CSS.
    It also implements [CSS JIT](https://webkit.org/blog/3271/webkit-css-selector-jit-compiler/), the only Just In Time compiler for CSS in existence.
    It works with a few tree data structures:
    * **Document Object Model** - This is the tree data structure we create from parsing HTML.
    * **Render Tree** - This tree represents the visual representation of each element in DOM tree computed from CSS and also stores the geometric layout information of each element.
* **WebCore/PAL and WebCore/platform** - Whilst technically a part of WebCore, this is a platform abstraction layer for WebCore
    so that the rest of WebCore code can remain platform independent / agnostic across all the platforms WebKit can run on: macOS, iOS, Windows, Linux, etc...
    Historically, most of this code resided in WebCore/platform.
    There is an ongoing multi-year project to slowly migrate code to PAL as we remove the reverse dependencies to WebCore.
* **WebKitLegacy** (a.k.a. WebKit1) - This layer interfaces WebCore with the rest of operating systems in single process and implements WebView on macOS and UIWebView on iOS.
* **WebKit** (a.k.a. WebKit2) - This layer implements the multi-process architecture of WebKit, and implements WKWebView on macOS and iOS.
    WebKit’s multi-process architecture consists of the following processes:
    * **UI process** - This is the application process. e.g. Safari and Mail
    * **WebContent process** - This process loads & runs code loaded from websites.
        Each tab in Safari typically has its own WebContent process.
        This is important to keep each tab responsive and protect websites from one another.
    * **Networking process** - This process is responsible for handling network requests as well as storage management.
        All WebContent processes in a single session (default vs. private browsing) share a single networking session in the networking process.
* **WebInspector / WebDriver** - WebKit’s developer tool & automation tool for Web developers.

## Contributing to WebKit

There are many ways to get involved and contribute to the WebKit Project.
Filing a new bug, fixing a bug, or adding a new feature.

There are three different kinds of contributors in the WebKit project.

 * Contributor - This category encompasses everyone. Anyone who files a bug or contributes a code change or reviews a code change is considered as a contributor
 * Committer - A committer is someone who has write access to [WebKit's repository](https://github.com/WebKit/WebKit).
 * Reviewer - A reviewer is someone who has the right to review and approve code changes other contributors proposed.

See [Commit and Review Policy](https://webkit.org/commit-and-review-policy/) for more details on how to become a committer or a reviewer.

### Staying in Touch

Before getting in touch with WebKit developers using any of the avenues below, make sure that you have checked our page on how to ask [questions about WebKit](https://webkit.org/asking-questions/).

You can find WebKit developers, testers, and other interested parties on the [#WebKit Slack workspace](https://webkit.slack.com/).
[Join the WebKit slack](https://join.slack.com/t/webkit/shared_invite/enQtOTU3NzQ3NTAzNjA0LTc5NmZlZWIwN2MxN2VjODVjNzEyZjBkOWQ4NTM3OTk0ZTc0ZGRjY2MyYmY2MWY1N2IzNTI2MTIwOGVjNzVhMWE),
and stay in touch.


## Getting started with WebKit

### Adding Tools to PATH

For convenience, you can add `Tools/Scripts/` to your path as follows in `~/.zshrc` like so:

```sh
export PATH=$PATH:/Volumes/Data/webkit/Tools/Scripts/
```

where `/Volumes/Data/webkit` is the path to a WebKit checkout.

This will allow you to run various tools you by name instead of typing the full path of the script.

### Updating checkouts

There is a script to update a WebKit checkout: `Tools/Scripts/update-webkit`.

That will replace your old pull request with a new one with the new changes, while also updating the pull request's description with your current commit message.

