# Testing

A deep dive into WebKit's Tests.

## Correctness Testing in WebKit

WebKit is really big on test driven development, we have many types of tests.

* **JavaScript tests** - Resides in top-level [JSTests](https://github.com/WebKit/WebKit/tree/main/JSTests) directory.
    This is the primary method of testing JavaScriptCore. Use `Tools/Scripts/run-javascriptcore-tests` to run these tests.
* **Layout tests** - Resides in top-level [LayoutTests](https://github.com/WebKit/WebKit/tree/main/LayoutTests) directory.
    This is the primary method of testing WebCore.
    If you’re making code changes to WebCore, you typically run these tests. Use `Tools/Scripts/run-webkit-tests` to run these.
    Pass `-1` to run tests using WebKitLegacy (a.k.a. WebKit1).
    [WebKitTestRunner](https://github.com/WebKit/WebKit/tree/main/Tools/WebKitTestRunner) is used to run these tests for WebKit2,
    and [DumpRenderTree](https://github.com/WebKit/WebKit/tree/main/Tools/DumpRenderTree) is used to these tests for WebKit1.
    There are a few styles of layout tests but all of them have a test file and expected result (ends with -expected.txt),
    and the test passes if the test file’s output matches that of the expected result.
* **API tests** - Reside in [Tools/TestWebKitAPI](https://github.com/WebKit/WebKit/tree/main/Tools/TestWebKitAPI),
    these are [GTests](https://en.wikipedia.org/wiki/Google_Test) that test APIs exposed by JavaScriptCore,
    WebKitLegacy, and WebKit layers as well as unit tests for selected WTF classes.
    WebKit does not use [XCTests](https://developer.apple.com/documentation/xctest).
    Use `Tools/Scripts/run-api-tests` to run these tests.
    Because these API tests are sequentially, it’s preferable to write layout tests when possible.
* **Bindings tests** - Reside in [Source/WebCore/bindings/scripts/test](https://github.com/WebKit/WebKit/tree/main/Source/WebCore/bindings/scripts/test),
    these are tests for WebCore’s binding code generator.
    Use `Tools/Scripts/run-bindings-tests` to run these tests.
* **webkitpy tests** - Tests for WebKit’s various Python scripts in [Tools/Scripts/webkitpy](https://github.com/WebKit/WebKit/tree/main/Tools/Scripts/webkitpy).
    Use `Tools/Scripts/test-webkitpy` to run these tests.
* **webkitperl tests** - Tests for WebKit’s various Perl scripts in [Tools/Scripts/webkitperl](https://github.com/WebKit/WebKit/tree/main/Tools/Scripts/webkitperl).
    Use `Tools/Scripts/test-webkitperl` to run these tests.

## Performance Testing in WebKit

The WebKit project has a "no performance regression" policy.
We maintain the performance of the following of the benchmarks and are located under [PerformanceTests](https://github.com/WebKit/WebKit/tree/main/PerformanceTests).
If your patch regresses one of these benchmarks even slightly (less than 1%), it will get reverted.

* **JetStream2** - Measures JavaScript and WASM performance.
* **MotionMark** - Measures graphics performance.
* **Speedometer 3** - Measures WebKit’s performance for complex web apps.

The following are benchmarks maintained by Apple's WebKit team but not available to other open source contributors
since Apple doesn't have the right to redistribute the content.
If your WebKit patch regresses one of these tests, your patch may still get reverted.

* **RAMification** - Apple's internal JavaScript memory benchmark.
* **ScrollPerf** - Apple's internal scrolling performance tests.
* **PLT** - Apple's internal page load time tests.
* **Membuster / PLUM** - Apple's internal memory tests. Membuster for macOS and PLUM for iOS and iPadOS.

## Layout Tests: Tests of the Web for the Web

Layout tests are WebKit tests written using Web technology such as HTML, CSS, and JavaScript,
and it’s the primary mechanism by which much of WebCore is tested.
Relevant layout test should be ran while you’re making code changes to WebCore and before uploading a patch to [bugs.webkit.org](https://bugs.webkit.org/).
While [bugs.webkit.org](https://bugs.webkit.org/)’s Early Warning System will build and run tests on a set of configurations,
individual patch authors are ultimately responsible for any test failures that their patches cause.

### Test Files and Expected Files

#### Directory Structure

[LayoutTests](https://github.com/WebKit/WebKit/tree/main/LayoutTests) directory is organized by the category of tests.
For example, [LayoutTests/accessibility](https://github.com/WebKit/WebKit/tree/main/LayoutTests/accessibility) contains accessibility related tests,
and [LayoutTests/fast/dom/HTMLAnchorElement](https://github.com/WebKit/WebKit/tree/main/LayoutTests/fast/dom/HTMLAnchorElement) contains
tests for [the HTML anchor element](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/a).

Any file that ends in `.html`, `.htm`, `.shtml`, `.xhtml`, `.mht`, `.xht`, `.xml`, `.svg`, or `.php` is considered as a test
unless it’s preceded with `-ref`, `-notref`, `-expected`, or `-expected-mismatch` (these are used for ref tests; explained later).
It’s accompanied by another file of the same name except it ends in `-expected.txt` or `-expected.png`.
These are called *expected results* and constitutes the baseline output of a given test.
When layout tests are ran, the test runner generates an output in the form of a plain text file and/or an PNG image,
and it is compared against these expected results.

In the case expected results may differ from one platform to another,
the expected results for each test is stored in [LayoutTests/platform](https://github.com/WebKit/WebKit/tree/main/LayoutTests/platform).
The expected result of a given test exists in the corresponding directory in
each subdirectory of [LayoutTests/platform](https://github.com/WebKit/WebKit/tree/main/LayoutTests/platform).
For example, the expected result of [LayoutTests/svg/W3C-SVG-1.1/animate-elem-46-t.svg](https://github.com/WebKit/WebKit/blob/main/LayoutTests/svg/W3C-SVG-1.1/animate-elem-46-t.svg)
for macOS Mojave is located at [LayoutTests/platform/mac-mojave/svg/W3C-SVG-1.1/animate-elem-46-t-expected.txt](https://github.com/WebKit/WebKit/blob/main/LayoutTests/platform/mac-mojave/svg/W3C-SVG-1.1/animate-elem-46-t-expected.txt).

These platform directories have a fallback order.
For example, running tests for WebKit2 on macOS Catalina will use the following fallback path from the most specific to most generic:

* platform/mac-catalina-wk2 - Results for WebKit2 on macOS Catalina.
* platform/mac-catalina - Results for WebKit2 and WebKitLegacy on macOS Catalina.
* platform/mac-wk2 - Results for WebKit2 on all macOS.
* platform/mac - Results for all macOS.
* platform/wk2 - Results for WebKit2 on every operating system.
* generic - Next to the test file.

#### Imported Tests

Tests under [LayoutTests/imported](https://github.com/WebKit/WebKit/tree/main/LayoutTests/imported) are imported from other repositories.
**They should not be modified by WebKit patches** unless the change is made in respective repositories first.

Most notable is [Web Platform Tests](https://web-platform-tests.org/),
which are imported under [LayoutTests/imported/w3c/web-platform-tests](https://github.com/WebKit/WebKit/tree/main/LayoutTests/imported/w3c/web-platform-tests).
These are cross browser vendor tests developed by W3C. Mozilla, Google, and Apple all contribute many tests to this shared test repository.

#### HTTP Tests

To open tests under [LayoutTests/http](https://github.com/WebKit/WebKit/tree/main/LayoutTests/http) or
[LayoutTests/imported/w3c/web-platform-tests](https://github.com/WebKit/WebKit/tree/main/LayoutTests/imported/w3c/web-platform-tests),
use [Tools/Scripts/open-layout-test](https://github.com/WebKit/WebKit/blob/main/Tools/Scripts/open-layout-test) with the path to a test.

You can also manually start HTTP servers with [`Tools/Scripts/run-webkit-httpd`](https://github.com/WebKit/WebKit/blob/main/Tools/Scripts/run-webkit-httpd).
To stop the HTTP servers, exit the script (e.g. Control + C on macOS).

Tests under [LayoutTests/http](https://github.com/WebKit/WebKit/tree/main/LayoutTests/http) are accessible at [http://127.0.0.1:8000](http://127.0.0.1:8000)
except tests in [LayoutTests/http/wpt](https://github.com/WebKit/WebKit/tree/main/LayoutTests/http/wpt),
which are available at [http://localhost:8800/WebKit/](http://localhost:8800/WebKit/) instead.

The [Web Platform Tests](https://web-platform-tests.org/) imported under
[LayoutTests/imported/w3c/web-platform-tests](https://github.com/WebKit/WebKit/tree/main/LayoutTests/imported/w3c/web-platform-tests)
are accessible under HTTP at [http://localhost:8800/](http://localhost:8800/) and HTTPS at [http://localhost:9443/](http://localhost:9443/)

Note that it's important to use the exact host names such as `127.0.0.1` and `localhost` above verbatim
since some tests rely on or test same-origin or cross-origin behaviors based on those host names.

## How We Manage Tests That Fail

The primary function of the LayoutTests is as a regression test suite.
This means that, while we care about whether a page is being rendered correctly,
we care more about whether the page is being rendered the way we expect it to.
In other words, we look more for changes in behavior than we do for correctness.

All layout tests have "expected results", which may be one of several forms.
The test may produce a text file containing JavaScript log messages, or a text rendering of the Render Tree.
It may also produce a screen capture of the rendered page as PNG files (if you are running with `--pixel-tests` enabled).
For WebAudio tests, we can produce WAV files instead of either text or PNG files.
For any of these types of tests, there are files checked into the LayoutTests directory named `-expected.{txt,png,wav}`.
In many cases, the output is expected to be generic and match on any WebKit port.
Lastly, we also support the concept of "reference tests",
which check that two pages are rendered identically (pixel-by-pixel).
As long as the two tests' output match, the tests pass.
For more on reference tests, see the [Reference Tests](#reference-tests) section above.

When the output doesn't match, there are two potential reasons for it:

1. **The port is performing "correctly"**, but the output simply won't match the generic version.
   The usual reason for this is for things like form controls,
   which are rendered differently on each platform.
2. **The port is performing "incorrectly"** (i.e., the test is failing).

In the first case, the convention is to check in a platform-specific `-expected` file that overrides the generic one.
In the second case, you have one of two options:

* Check in a new baseline as a platform-specific file and file a bug to track the incorrectness.
  Some types of failures (like crashes and timeouts) can't be handled this way, of course.
* Add an entry to the TestExpectations file (see below).

## TestExpectations File

The TestExpectations files are used to suppress known failures.
They are found in platform-specific directories under LayoutTests.
Ports may use one or more files which are used in order,
with later files overriding earlier ones.
The location of the generic file is `LayoutTests/TestExpectations`.

### Syntax

The syntax of the file is roughly one expectation per line.
An expectation can apply to either a directory of tests, or a specific test.
Lines prefixed with `#` are treated as comments, and blank lines are allowed as well.

The syntax of a line is:

```
[ bugs ] [ "[" modifiers "]" ] test_name [ "[" expectations "]" ]
```

* Tokens are separated by whitespace.
* The brackets delimiting the modifiers and expectations from the bugs and the test name are not optional;
  however, the bugs, modifiers, and expectations components are optional.
  In other words, if you want to specify modifiers or expectations, you must enclose them in brackets.
* Lines are expected to have one or more bug identifiers, and the linter will complain about lines missing them.
  Bug identifiers are of the form `webkit.org/b/12345` or `Bug(username)`.
* If no modifiers are specified, the test applies to all of the configurations applicable to that file.
* **Modifiers** can be one or more of the tags listed below. Not all modifiers make sense on all ports or in all lines.
  For macOS, you can specify an OS name followed by a `+` to indicate that OS version and all later OS versions.

    Platform modifiers:

    * `Mac`, `iOS`, `visionOS`, `watchOS`
    * Specific macOS versions (e.g. `Sonoma`, `Ventura`, `Monterey`)
    * `Win`
    * `Linux`
    * Architecture: `x86_64`, `x86`, `arm64`
    * Configuration: `Release`, `Debug`

* **Expectations** can be one or more of:
  `Crash`, `Failure`, `ImageOnlyFailure`, `Pass`, `Slow`, `Skip`, `Timeout`, `WontFix`, `Missing`.
  If multiple expectations are listed, the test is considered "flaky"
  and any of those results will be considered as expected.

For example:

```
webkit.org/b/12345 [ Win Debug ] fast/html/keygen.html [ Crash ]
```

This indicates that the `fast/html/keygen.html` test file is expected to crash
when run in the Debug configuration on Windows,
and the tracking bug for this crash is bug #12345 in the WebKit bug repository.
Note that the test will still be run, so that we can notice if it doesn't actually crash.

Assuming you're running a debug build on a specific macOS version,
the following lines are all equivalent (in terms of whether the test is performed and its expected outcome):

```
fast/html/keygen.html
Bug(darin) fast/html/keygen.html
fast/html/keygen.html [ Skip ]
fast/html/keygen.html [ WontFix ]
Bug(darin) fast/html/keygen.html [ Skip ]
```

### Semantics

* `WontFix` implies `Skip` and also indicates that we don't have any plans to make the test pass.
* `WontFix` and `Skip` must be used by themselves
  and cannot be specified alongside `Crash` or another expectation keyword.
* `Slow` means that we expect the test to run slowly and will use a longer, port-specific timeout.
  A given line cannot have both `Slow` and `Timeout`.
* If no expectation keyword is specified, then the `Skip` keyword is implied.

When parsing the file, two rules determine if an expectation line applies to the current run:

1. If the configuration parameters don't match the configuration of the current run, the expectation is ignored.
2. Expectations that match more of a test name are used before expectations that match less of a test name.

For example, if you had the following lines in your file,
and you were running a debug build on a specific macOS version:

```
webkit.org/b/12345 [ Mac ] fast/html [ Failure ]
webkit.org/b/12345 [ Mac ] fast/html/keygen.html [ Pass ]
webkit.org/b/12345 [ Win ] fast/forms/submit.html [ ImageOnlyFailure ]
webkit.org/b/12345 fast/html/section-element.html [ Failure Crash ]
```

You'd expect:

* `fast/html/article-element.html` to fail with a text diff (since it is in the `fast/html` directory).
* `fast/html/keygen.html` to pass (since the exact match on the test name takes precedence).
* `fast/forms/submit.html` to pass (since the `Win` configuration parameters don't match).
* `fast/html/section-element.html` to either crash or produce a text (or image and text) failure,
  but not time out or pass.

Duplicate expectations are not allowed within a single file and will generate warnings.
Ports may use multiple TestExpectations files,
and entries in a later file override entries in an earlier file.
The list of files used by a port is determined by the port's implementation of `expectations_files()`
in `Tools/Scripts/webkitpy/port/{mac,win,gtk,etc.}.py`.
A generic TestExpectations file always applies, and is applied before port-specific files.

You can determine which expectations files apply (in which order)
for a given platform/port by running:

```sh
webkit-patch print-expectations --paths --platform <platform>
```

You can verify that any changes you've made to an expectations file are correct by running:

```sh
run-webkit-tests --lint-test-files
```

This will cycle through all of the possible combinations of configurations looking for problems.

### Rules of Thumb for Suppressing Failures

Here are some rules of thumb to apply when adding new expectations:

* Only use `WontFix` when you know for sure we will never implement the capability tested by the test.
* Use `Skip` when the test:
    * Throws a JavaScript exception and makes a text-only test manifest as a pixel test.
      This usually manifests as a "Missing test expectations" failure.
    * Disrupts running of the other tests.
      Please make sure to assign Priority 1 to the associated bug.
* Try to specify platforms and configurations as accurately as possible.
  If a test passes on all but one platform, it should only have that platform listed.
* If a test fails intermittently, use multiple expectations (e.g. `[ Pass Failure ]`).

## Running Layout Tests

To run layout tests, use `Tools/Scripts/run-webkit-tests`.
It optionally takes file paths to a test file or directory and options on how to run a test.
For example, in order to just run `LayoutTests/fast/dom/Element/element-traversal.html`, do:

```sh
Tools/Scripts/run-webkit-tests fast/dom/Element/element-traversal.html
```

Because there are 50,000+ tests in WebKit,
you typically want to run a subset of tests that are relevant to your code change
(e.g. `LayoutTests/storage/indexeddb/` if you’re working on IndexedDB) while developing the code change,
and run all layout tests at the end on your local machine or rely on the Early Warning System on [bugs.webkit.org](https://bugs.webkit.org/) for more thorough testing.

Specify `--debug` or `--release` to use either release or debug build.
To run tests using iOS simulator, you can specify either `--ios-simulator`, `--iphone-simulator`,
or `--ipad-simulator` based on whichever simulator is desired.

By default, `run-webkit-tests` will run all the tests you specified once in the lexicological order of test paths
relative to `LayoutTests` directory and retry any tests that have failed.
If you know the test is going to fail and don’t want retries, specify `--no-retry-failures`.

Because there are so many tests, `run-webkit-tests` will runs tests in different directories in parallel
(i.e. all tests in a single directory is ran sequentially one after another).
You can control the number of parallel test runners using `--child-processes` option.

`run-webkit-tests` has many options.
Use `--help` to enumerate all the supported options.

### Repeating Layout Tests

When you’re investigating flaky tests or crashes, it might be desirable to adjust this.
`--iterations X` option will specify the number of times the list of tests are ran.
For example, if we are running tests A, B, C and `--iterations 3` is specified,
`run-webkit-tests` will run: A, B, C, A, B, C, A, B, C.
Similarly, `--repeat-each` option will specify the number of times each test is repeated before moving onto next test.
For example, if we’re running tests A, B, C, and `--repeat-each 3` is specified, `run-webkit-tests` will run: A, A, A, B, B, B, C, C, C.
`--exit-after-n-failures` option will specify the total number of test failures before `run-webkit-tests` will stop.
In particular, `--exit-after-n-failures=1` is useful when investigating a flaky failure
so that `run-webkit-tests` will stop when the failure actually happens for the first time.

### Test Results

Whenever tests do fail, run-webkit-tests will store results in `WebKitBuild/Debug/layout-test-results`
mirroring the same directory structure as `LayoutTests`.
For example, the actual output produced for `LayoutTests/editing/inserting/typing-001.html`,
if failed, will appear in `WebKitBuild/Debug/layout-test-results/editing/inserting/typing-001-actual.txt`.
run-webkit-tests also generates a web page with the summary of results in
`WebKitBuild/Debug/layout-test-results/results.html` and automatically tries to open it in Safari using the local build of WebKit.

> If Safari fails to launch, specify `--no-show-results` and open results.html file manually.

#### Updating Expected Results

If you’ve updated a test content or test’s output changes with your code change (e.g. more test case passes),
then you may have to update `-expected.txt` file accompanying the test.
To do that, first run the test once to make sure the diff and new output makes sense in results.html,
and run the test again with `--reset-results`.
This will update the matching `-expected.txt` file.

You may need to manually copy the new result to other -expected.txt files that exist under `LayoutTests` for other platforms and configurations.
Find other `-expected.txt` files when you’re doing this.

When a new test is added, `run-webkit-tests` will automatically generate new `-expected.txt` file for your test.
You can disable this feature by specifying `--no-new-test-results` e.g. when the test is still under development.

### Different Styles of Layout Tests

There are multiple styles of layout tests in WebKit.

#### **Render tree dumps**

This is the oldest style of layout tests, and the default mode of layout tests.
It’s a text serialization of WebKit’s render tree and its output looks like
[this](https://github.com/WebKit/WebKit/blob/main/LayoutTests/platform/mac/fast/dom/anchor-text-expected.txt):

```
layer at (0,0) size 800x600
  RenderView at (0,0) size 800x600
layer at (0,0) size 800x600
  RenderBlock {HTML} at (0,0) size 800x600
    RenderBody {BODY} at (8,8) size 784x584
      RenderInline {A} at (0,0) size 238x18 [color=#0000EE]
        RenderInline {B} at (0,0) size 238x18
          RenderText {#text} at (0,0) size 238x18
            text run at (0,0) width 238: "the second copy should not be bold"
      RenderText {#text} at (237,0) size 5x18
        text run at (237,0) width 5: " "
      RenderText {#text} at (241,0) size 227x18
        text run at (241,0) width 227: "the second copy should not be bold"
```

This style of layout tests is discouraged today because its outputs are highly dependent on each platform,
and end up requiring a specific expected result in each platform.
But they’re still useful when testing new rendering and layout feature or bugs thereof.

These tests also have accompanying `-expected.png` files but `run-webkit-tests` doesn't check the PNG output against the expected result by default.
To do this check, pass `--pixel`.
Unfortunately, many *pixel tests* will fail because we have not been updating the expected PNG results a good chunk of the last decade.
However, these pixel results might be useful when diagnosing a new test failure.
For this reason, `run-webkit-tests` will automatically generate PNG results when retrying the test,
effectively enabling `--pixel` option for retries.

#### dumpAsText test

These are tests that uses the plain text serialization of the test page as the output (as if the entire page’s content is copied as plain text).
All these tests call `testRunner.dumpAsText` to trigger this behavior.
The output typically contains a log of text or other informative output scripts in the page produced.
For example, [LayoutTests/fast/dom/anchor-toString.html](https://github.com/WebKit/WebKit/blob/main/LayoutTests/fast/dom/anchor-toString.html) is written as follows:

```html
<a href="http://localhost/sometestfile.html" id="anchor">
A link!
</a>
<br>
<br>
<script>
    {
        if (window.testRunner)
            testRunner.dumpAsText();

        var anchor = document.getElementById("anchor");
        document.write("Writing just the anchor object - " + anchor);

        var anchorString = String(anchor);
        document.write("<br><br>Writing the result of the String(anchor) - " + anchorString);

        var anchorToString = anchor.toString();
        document.write("<br><br>Writing the result of the anchor's toString() method - " + anchorToString);
    }
</script>
```

 and generates the following [output](https://github.com/WebKit/WebKit/blob/main/LayoutTests/fast/dom/anchor-toString-expected.txt):

```
A link! 

Writing just the anchor object - http://localhost/sometestfile.html

Writing the result of the String(anchor) - http://localhost/sometestfile.html

Writing the result of the anchor's toString() method - http://localhost/sometestfile.html
```

#### js-test.js and js-test-pre.js tests

These are variants of dumpAsText test which uses WebKit’s assertion library:
[LayoutTests/resources/js-test.js](https://github.com/WebKit/WebKit/blob/main/LayoutTests/resources/js-test.js)
and [LayoutTests/resources/js-test-pre.js](https://github.com/WebKit/WebKit/blob/main/LayoutTests/resources/js-test-pre.js).
It consists of shouldX function calls which takes two JavaScript code snippet which are then executed and outputs of which are compared.
js-test.js is simply a new variant of js-test-pre.js that doesn’t require
the inclusion of [LayoutTests/resources/js-test-post.js](https://github.com/WebKit/WebKit/blob/main/LayoutTests/resources/js-test-post.js) at the end.
**Use js-test.js in new tests**, not js-test-pre.js.

For example, [LayoutTests/fast/dom/Comment/remove.html](https://github.com/WebKit/WebKit/blob/main/LayoutTests/fast/dom/Comment/remove.html)
which tests [remove()](https://developer.mozilla.org/en-US/docs/Web/API/ChildNode/remove) method
on [Comment node](https://developer.mozilla.org/en-US/docs/Web/API/Comment) is written as:

```html
<!DOCTYPE html>
<script src="../../../resources/js-test-pre.js"></script>
<div id="test"></div>
<script>

description('This tests the DOM 4 remove method on a Comment.');

var testDiv = document.getElementById('test');
var comment = document.createComment('Comment');
testDiv.appendChild(comment);
shouldBe('testDiv.childNodes.length', '1');
comment.remove();
shouldBe('testDiv.childNodes.length', '0');
comment.remove();
shouldBe('testDiv.childNodes.length', '0');

</script>
<script src="../../../resources/js-test-post.js"></script>
```

with the following [expected result](https://github.com/WebKit/WebKit/blob/main/LayoutTests/fast/dom/Comment/remove-expected.txt) (output):

```
This tests the DOM 4 remove method on a Comment.

On success, you will see a series of "PASS" messages, followed by "TEST COMPLETE".


PASS testDiv.childNodes.length is 1
PASS testDiv.childNodes.length is 0
PASS testDiv.childNodes.length is 0
PASS successfullyParsed is true

TEST COMPLETE
```

`description` function specifies the description of this test, and subsequent shouldBe calls takes two strings,
both of which are evaluated as JavaScript and then compared.

Some old js-test-pre.js tests may put its test code in a separate JS file but we don’t do that anymore to keep all the test code in one place.

[js-test.js](https://github.com/WebKit/WebKit/blob/main/LayoutTests/resources/js-test.js) and [js-test-pre.js](https://github.com/WebKit/WebKit/blob/main/LayoutTests/resources/js-test-pre.js) provide all kinds of other assertion and helper functions.
Here are some examples:

* `debug(msg)` - Inserts a debug / log string in the output.
* `evalAndLog(code)` - Similar to `debug()` but evaluates code as JavaScript.
* `shouldNotBe(a, b)` - Generates `PASS` if the results of evaluating `a` and `b` differ.
* `shouldBeTrue(code)` - Shorthand for `shouldBe(code, 'true')`.
* `shouldBeFalse(code)` - Shorthand for `shouldBe(code, 'false')`.
* `shouldBeNaN(code)` - Shorthand for `shouldBe(code, 'NaN')`.
* `shouldBeNull(code)` - Shorthand for `shouldBe(code, 'null')`.
* `shouldBeZero(code)` - Shorthand for `shouldBe(code, '0')`.
* `shouldBeEqualToString(code, string)` - Similar to `shouldBe` but the second argument is not evaluated as string.
* `finishJSTest()` - When js-test.js style test needs to do some async work, define the global variable named jsTestIsAsync and set it to true. When the test is done, call this function to notify the test runner (don’t call `testRunner.notifyDone` mentioned later directly). See [an example](https://github.com/WebKit/WebKit/blob/main/LayoutTests/fast/dom/iframe-innerWidth.html).

**It’s important to note that these shouldX functions only add output strings that say PASS or FAIL. If the expected result also contains the same FAIL strings, then run-webkit-tests will consider the whole test file to have passed.**

Another way to think about this is that `-expected.txt` files are baseline outputs, and baseline outputs can contain known failures.

There is a helper script to create a template for a new js-test.js test. The following will create new test named `new-test.html` in [LayoutTests/fast/dom](https://github.com/WebKit/WebKit/tree/main/LayoutTests/fast/dom):

```sh
Tools/Scripts/make-new-script-test fast/dom/new-test.html
```

#### dump-as-markup.js Tests

A dump-as-markup.js test is yet another variant of dumpAsText test,
which uses [LayoutTests/resources/dump-as-markup.js](https://github.com/WebKit/WebKit/blob/main/LayoutTests/resources/dump-as-markup.js).
This style of test is used when it’s desirable to compare the state of the DOM tree before and after some operations.
For example, many tests under [LayoutTests/editing](https://github.com/WebKit/WebKit/tree/main/LayoutTests/editing)
use this style of testing to test complex DOM mutation operations such as pasting HTML from the users’ clipboard.
dump-as-markup.js adds `Markup` on the global object and exposes a few helper functions.
Like js-test.js tests, a test description can be specified via `Markup.description`.
The test then involves `Markup.dump(node, description)` to serialize the state of DOM tree as plain text
where `element` is either a DOM [node](https://developer.mozilla.org/en-US/docs/Web/API/Node)
under which the state should be serialized or its [id](https://developer.mozilla.org/en-US/docs/Web/HTML/Global_attributes/id).

For example, [LayoutTests/editing/inserting/insert-list-in-table-cell-01.html](https://github.com/WebKit/WebKit/blob/main/LayoutTests/editing/inserting/insert-list-in-table-cell-01.html) is written as follows:

```html
<!DOCTYPE html>
<div id="container" contenteditable="true"><table border="1"><tr><td id="element">fsdf</td><td>fsdf</td></tr><tr><td>gghfg</td><td>fsfg</td></tr></table></div>
<script src="../editing.js"></script>
<script src="../../resources/dump-as-markup.js"></script>
<script>
    Markup.description('Insert list items in a single table cell:');

    var e = document.getElementById("element");
    setSelectionCommand(e, 0, e, 1);
    Markup.dump('container', 'Before');

    document.execCommand("insertOrderedList");
    Markup.dump('container', 'After');
</script>
```

with the following [expected result](https://github.com/WebKit/WebKit/blob/main/LayoutTests/editing/inserting/insert-list-in-table-cell-01-expected.txt):

```
Insert list items in a single table cell:

Before:
| <table>
|   border="1"
|   <tbody>
|     <tr>
|       <td>
|         id="element"
|         "<#selection-anchor>fsdf<#selection-focus>"
|       <td>
|         "fsdf"
|     <tr>
|       <td>
|         "gghfg"
|       <td>
|         "fsfg"

After:
| <table>
|   border="1"
|   <tbody>
|     <tr>
|       <td>
|         id="element"
|         <ol>
|           <li>
|             "<#selection-anchor>fsdf<#selection-focus>"
|             <br>
|       <td>
|         "fsdf"
|     <tr>
|       <td>
|         "gghfg"
|       <td>
|         "fsfg"
```

#### testharness.js Tests

This is yet another variant of dumpAsText test which uses the test harness of [Web Platform Tests](https://web-platform-tests.org/), 
which is [W3C](https://www.w3.org/)’s official tests for the Web.
There is an [extensive documentation](https://web-platform-tests.org/writing-tests/testharness-api.html) on how this harness works.

> As mentioned above, do not modify tests in [LayoutTests/imported/w3c/web-platform-tests](https://github.com/WebKit/WebKit/tree/main/LayoutTests/imported/w3c/web-platform-tests)
unless the same test changes are made in Web Platform Tests’ primary repository.

#### Reference Tests

Reference tests are special in that they don’t have accompanying `-expected.txt` files.
Instead, they have a matching or mismatching expected result file.
Both the test file and the accompanying matching or mismatching expected result generate PNG outputs.
The test passes if the PNG outputs of the test and the matching expected result are the same; the test fails otherwise.
For a test with a mismatching expected result, the test passes if the PNG outputs of the test and the mismatching expected result are not the same, and fails if they are the same.

A matching expected result or a mismatching expected result can be specified in a few ways:

* The file with the same name as the test name except it ends with  `-expected.*` or `-ref.*` is a matching expected result for the test.
* The file with the same name as the test name except it ends with  `-expected-mismatch.*` or `-notref.*` is a matching expected result for the test.
* The file specified by a HTML link element in the test file with `match` relation: `<link rel=match href=X>` where X is the relative file path is a matching expected result.
* The file specified by a HTML link element in the test file with `mismatch` relation: `<link rel=mismatch href=X>` where X is the relative file path is a mismatching expected result.

For example, [LayoutTests/imported/w3c/web-platform-tests/html/rendering/replaced-elements/images/space.html](https://github.com/WebKit/WebKit/blob/main/LayoutTests/imported/w3c/web-platform-tests/html/rendering/replaced-elements/images/space.html) specifies [space-ref.html](https://github.com/WebKit/WebKit/blob/main/LayoutTests/imported/w3c/web-platform-tests/html/rendering/replaced-elements/images/space-ref.html) in the same directory as the matching expected result as follows:

```html
<!doctype html>
<meta charset=utf-8>
<title>img hspace/vspace</title>
<link rel=match href=space-ref.html>
<style>
span { background: blue; }
</style>
<div style=width:400px;>
<p><span><img src=/images/green.png></span>
<p><span><img src=/images/green.png hspace=10></span>
<p><span><img src=/images/green.png vspace=10></span>
<p><span><img src=/images/green.png hspace=10%></span>
<p><span><img src=/images/green.png vspace=10%></span>
</div>
```

### Test Runners

Most layout tests are designed to be runnable inside a browser but run-webkit-tests uses a special program to run them.
Our continuous integration system as well as the Early Warning System uses run-webkit-tests to run layout tests.
In WebKit2, this is appropriately named [WebKitTestRunner](https://github.com/WebKit/WebKit/tree/main/Tools/WebKitTestRunner).
In WebKit1 or WebKitLegacy, it’s [DumpRenderTree](https://github.com/WebKit/WebKit/tree/main/Tools/DumpRenderTree),
which is named after the very first type of layout tests, which generated the text representation of the render tree.

#### Extra Interfaces Available in Test Runners

Both WebKitTestRunner and DumpRenderTree expose a few extra interfaces to JavaScript on `window` (i.e. global object) in order to emulate user inputs,
enable or disable a feature, or to improve the reliability of testing.

* **[GCController](https://github.com/WebKit/WebKit/blob/main/Tools/WebKitTestRunner/InjectedBundle/Bindings/GCController.idl)**
    - `GCController.collect()` triggers a synchronous full garbage collection.
    This function is useful for testing crashes or erroneous premature collection of JS wrappers and leaks.
* **[testRunner](https://github.com/WebKit/WebKit/blob/main/Tools/WebKitTestRunner/InjectedBundle/Bindings/TestRunner.idl)**
    - TestRunner interface exposes many methods to control the behaviors of WebKitTestRunner and DumpRenderTree.
    Some the most commonly used methods are as follows:
    * `waitUntilDone()` / `notifyDone()` - These functions are useful when writing tests that involve asynchronous tasks
        which may require the test to continue running beyond when it finished loading.
        `testRunner.waitUntilDone()` makes WebKitTestRunner and DumpRenderTree not end the test when a layout test has finished loading.
        The test continues until `testRunner.notifyDone()` is called.
    * `dumpAsText(boolean dumpPixels)` - Makes WebKitTestRunner and DumpRenderTree output the plain text of the loaded page instead of the state of the render tree.
    * `overridePreference(DOMString preference, DOMString value)` - Overrides WebKit’s [preferences](https://github.com/WebKit/WebKit/tree/main/Source/WTF/Scripts/Preferences).
        For WebKitLegacy, these are defined in [Source/WebKitLegacy/mac/WebView/WebPreferences.h](https://github.com/WebKit/WebKit/tree/main/Source/WebKitLegacy/mac/WebView/WebPreferences.h) for macOS
        and [Source/WebKitLegacy/win/WebPreferences.h](https://github.com/WebKit/WebKit/tree/main/Source/WebKitLegacy/win/WebPreferences.h) for Windows.
* **[eventSender](https://github.com/WebKit/WebKit/blob/main/Tools/WebKitTestRunner/InjectedBundle/Bindings/EventSendingController.idl)**
    - Exposes methods to emulate mouse, keyboard, and touch actions.
    **Use [ui-helpers.js](https://github.com/WebKit/WebKit/blob/main/LayoutTests/resources/ui-helper.js) script** instead of directly calling methods on this function.
    This will ensure the test will be most compatible with all the test configurations we have.
* [**UIScriptController**](https://github.com/WebKit/WebKit/tree/main/Tools/TestRunnerShared/UIScriptContext/Bindings/UIScriptController.idl)
     - Exposes methods to emulate user inputs like eventSender mostly on iOS WebKit2.
     **Use [ui-helpers.js](https://github.com/WebKit/WebKit/blob/main/LayoutTests/resources/ui-helper.js) script** instead of directly calling methods on this function.
     This will ensure the test will be most compatible with all the test configurations we have.
* **[textInputController](https://github.com/WebKit/WebKit/blob/main/Tools/WebKitTestRunner/InjectedBundle/Bindings/TextInputController.idl)**
    - Exposes methods to test [input methods](https://en.wikipedia.org/wiki/Input_method).

Additionally, [WebCore/testing](https://github.com/WebKit/WebKit/tree/main/Source/WebCore/testing) exposes a few testing hooks to test its internals:

* **[internals](https://github.com/WebKit/WebKit/blob/main/Source/WebCore/testing/Internals.idl)**
    - Exposes various hooks into WebCore that shouldn’t be part of WebKit or WebKitLegacy API.
* [**internals.settings**](https://github.com/WebKit/WebKit/blob/main/Source/WebCore/testing/InternalSettings.idl)
    - Exposes various WebCore settings and let tests override them.
    Note that WebKit layer code may depend on preferences in UI process and the aforementioned `testRunner.overridePreference` may need to be used instead.
    It’s in fact preferable to override the equivalent preference via `testRunner.overridePreference`
    unless you know for sure WebKit or WebKitLegacy layer of code isn’t affected by the setting you’re overriding.

#### Enabling or Disabling a Feature in Test Runners

FIXME: Mention test-runner-options

### Test Harness Scripts

FIXME: Write about dump-as-markup.js, and ui-helper.js

### Investigating Test Failures Observed on Bots

There are multiple tools to investigate test failures happening on our continuous integration system
([build.webkit.org](https://build.webkit.org/)).
The most notable is flakiness dashboard:
[results.webkit.org](https://results.webkit.org/)

FIXME: Write how to investigate a test failure.


## Dive into API tests

FIXME: Talk about how to debug API tests.

