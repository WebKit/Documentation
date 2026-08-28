# Writing Web Inspector Tests

This page describes how various parts of the Web Inspector are tested.

-----

## Types of Tests

There are several types of inspector tests:

 * **Protocol Tests** exercise the **inspector backend** independently of any particular frontend.
 * **Frontend Tests** exercise the **models and controllers** underlying the Web Inspector user interface.
 * **Manual Tests** exercise the user interface in ways that are difficult to automate or require infrastructure that doesn't exist yet.
 * **Library Tests** exercise subsystems such as pretty printing or the protocol generator in isolation from a running Web Inspector instance.

To date, the Web Inspector has no automated tests that exercise the user interface. In practice, the Inspector UI changes frequently, so such tests tend to be brittle, and have traditionally not been worth the trouble of maintaining.

## How Tests Execute

 Each test is an HTML file in a per-domain directory within `LayoutTests/inspector/` or `LayoutTests/http/tests/inspector/` (for tests that load files over HTTP). Some tests may additionally include external files, which are included in special `resources/` directories that are automatically excluded from the test search path. All tests must decide which test harness to use by including either `protocol-test.js` or `inspector-test.js`.

 When the test page finishes loading, it calls the `runTest()` method provided, which signals the test harness to set up a test inspector instance that inspects the test page. Each test page defines a special `test()` method, which is automatically marshalled and injected into the Inspector instance's context. Most scripts execute in the inspector's JavaScript context, and occasionally evaluate some code in the test page's context to log test results and to trigger specific inspectable behaviors.

## Protocol Tests

Protocol tests are appropriate for testing inspector features that require the use of a few commands and events between the backend and frontend, and do not require the inspected page to be reloaded. Protocol tests are fairly low-level, and exercise the Inspector backend independent of a particular frontend and its controllers and models. In other words, you cannot test Managers or other classes in the WebInspector namespace using a protocol test.

The `protocol-test.js` stub creates a dummy inspector frontend by using `window.open()` from the test page, and establishes bidirectional communication with the __child__ inspector page using `window.postMessage` and a `message` event handler. The "inspector" page that is loaded into the iframe is located at `Source/WebInspectorUI/Base/TestStub.html`. The code that runs inside the Inspector frame (i.e., code within the test() method) has access to the protocol test harness, whose methods are prefixed with `ProtocolTest`. Protocol-specific methods for sending commands and awaiting on events are available in the InspectorProtocol namespace.

## Frontend Tests

Frontend tests exercise the functionality of models and controllers specific to WebInspectorUI (the user interface included in WebKit trunk). They use a real, headless Web Inspector frontend that persists across navigations of the inspected (test) page.

The `inspector-test.js` stub creates a real (for WebKit2, separate process) inspector frontend. Instead of the normal Web Inspector base page (`Main.html`), it loads a smaller version (`Test.html`) which does not load Views and other code not used by tests. The code that runs inside the Inspector (i.e., code within the test() method) has access to the frontend test harness, whose methods are prefixed with `InspectorTest`. Like ordinary Web Inspector code, injected inspector code has full access to models and controllers in the `WebInspector` namespace. (However, as noted above, not all files are loaded in the test version of the Inspector. You may need to add additional files to `Test.html` when testing new code or adding inter-class dependencies.)

## Manual Tests

A manual test requires manual interaction with a test page to exercise specific behaviors. The test page should describe the necessary interaction steps, and the expected output/behavior.

## Library Tests

 * Pretty printing tests: these cover behavior of our pretty-printing code, and should be converted into layout tests.
 * Protocol generator tests: these test inputs to the generator are designed to detect changes in the protocol generator's code generation routines. They do not contain any assertions. To run the tests, execute `Tools/Scripts/run-inspector-generator-tests`.
 * TODO: do we have other ad-hoc tests?

-----

## How to Write Tests

The properties that we strive for when writing inspector tests are:

 * **consistent**: a test should be consistent between runs, and not sporadically fail or time out.
 * **robust**: a test should be robust to underlying changes in data structures or other minor changes to the code being exercised. It should not require frequent adjustments.
 * **high coverage**: to uncover bugs and unaddressed situations, a test should exercise as many normal and exceptional code paths as possible.
 * **self-documenting**: a test should act as executable documentation for the expected and unexpected use cases or behaviors of the code being exercised.

With these properties in mind, here are a few hints for writing good tests:

 * Use good names in the test filename (`inspector/domain/description-of-test.html`), test suite name (`Domain.descriptionOfTest`), and in each test case's name (`TestSomethingInteresting`) and description (`"This test ensures something interesting"`).
 * Use `AsyncTestSuite` (documented below) to avoid common pitfalls involved in testing asynchronous code, such as when testing the result of a command sent to the inspector backend.
 * Use assertions to test invariants, pre-conditions, and post-conditions. Assertions should not need to be changed unless the code under test changes in significant ways.
 * Assertions should always document the expected condition in the message, usually using obligatory language such as "should be", "should contain", "should not", etc. For example, the following shows a good and bad assertion message:

```
InspectorTest.expectThat(fontFamilyNames.length >= 5, "Has at least 5 fonts"); // BAD!
InspectorTest.expectThat(fontFamilyNames.length >= 5, "Family names list should contain at least 5 fonts"); // GOOD!
```

* Use `expectThat` instead of `assert` whenever possible. The former will always add output to the test, prefixing the condition with `PASS:` or `FAIL:`; the latter only produces output when the condition evaluates to false. Why should the default be to always log? For someone trying to understand how a test works or debug a failing test, the extra output is very helpful in understanding control flow.
* Log runtime states sparingly, and only those that may help to diagnose a failing test. Logging runtime states can make tests more self-documenting at the expense of reducing robustness. For example, if a test logs source code locations, these could change (and cause the test to fail) if text is added to or removed from relevant file. It is better to assert actual output against known-good outputs. Don't dump runtime state that is machine-dependent.

## Assertion Matchers

```
InspectorTest.expectThat
InspectorTest.expectFalse
InspectorTest.expectNull
InspectorTest.expectNotNull
InspectorTest.expectEqual
InspectorTest.expectNotEqual
InspectorTest.expectShallowEqual
InspectorTest.expectNotShallowEqual
InspectorTest.expectEqualWithAccuracy
InspectorTest.expectLessThan
InspectorTest.expectLessThanOrEqual
InspectorTest.expectGreaterThan
InspectorTest.expectGreaterThanOrEqual
```

## Important Test Fixtures

Common to both protocol tests and frontend tests are the `TestHarness` and `TestSuite` classes. TestHarness and its subclasses (bound to the globals ProtocolTest or InspectorTest) provide basic mechanisms for logging, asserting, and starting or stopping the test. Protocol and frontend tests each have their own subclass of `TestHarness` which contains methods specific to one environment.

`TestSuite` and its subclasses `AsyncTestSuite` and `SyncTestSuite` help us to write robust, well-documented, and fast tests. All new tests should use these classes. Each test file consists of one (or more) test suite(s). A suite consists of multiple test cases which execute sequentially in the order that they are added. If a test case fails, later test cases are skipped to avoid spurious failures caused by dependencies between test cases. Test cases are added to the suite imperatively, and then executed using the `runTestCases()` or `runTestCasesAndFinish()` methods. This allows for programmatic construction of test suites that exercise code using many different inputs.

A `SyncTestSuite` executes its test cases synchronously, one after another in a loop. It is usually used for unit tests that do not require communication with the backend. Each test case provides a test method which takes no arguments and returns `true` or `false` to indicate test success or failure, respectively.

An `AsyncTestSuite` executes its test cases asynchronously, one after another, by chaining together promises created for each test. Each test case provides a test method which takes two callback arguments: `resolve` and `reject`. At runtime, each test method is turned into a Promise; like a Promise, the test signals success by calling `resolve()`, and signals failure by calling `reject()` or throwing an `Error` instance.

## How to Debug Tests

In general, the strategies for [wiki:"WebInspectorDebugging" debugging the Web Inspector] and debugging WebCore/WebKit2 apply the same to debugging inspector tests. Sometimes, tests can be more difficult to debug because the test harness' marshalling code can be broken by incorrectly written tests or bugs in the test harness. The test stubs provide several flags that enable extra or more reliable logging for debug purposes. Flags can be set in the corresponding `Test/TestStub.html` file for all test runs, or at the top of a `test()` method to only affect one test.

For protocol tests:

```
// Debug logging is synchronous on the test page.
ProtocolTest.forceDebugLogging = false;

// Tee all TestHarness commands to stderr from within the Inspector.
ProtocolTest.dumpActivityToSystemConsole = false;

// Best used in combination with dumpActivityToSystemConsole.
ProtocolTest.dumpInspectorProtocolMessages = false;

// Enables all of the above.
ProtocolTest.debug();
```

For frontend tests:

```
// Debug logging is synchronous on the test page.
InspectorTest.forceDebugLogging = false;

// Tee all TestHarness commands to stderr from within the Inspector.
InspectorTest.dumpActivityToSystemConsole = false;

// Best used in combination with dumpActivityToSystemConsole.
InspectorBackend.dumpInspectorProtocolMessages = false;

// Enables all of the above.
InspectorTest.debug();
```

### Attaching a Debugger to Tests with DumpRenderTree (WebKit1)

```
$ DYLD_FRAMEWORK_PATH=WebKitBuild/Debug lldb -- WebKitBuild/Debug/DumpRenderTree
(lldb) run LayoutTests/inspector/dom/focus.html
```

To run DumpRenderTree in "server mode", which the run-webkit-tests uses to run multiple tests without restarting the process, make a file called "tests-to-run.txt" with one test per line, and launch this way instead:

```
(lldb) process launch -i tests-to-run.txt "-"
```

### Attaching a Debugger to Tests with WebKitTestRunner (WebKit2)

TODO

# Example Test (uses inspector-test.js, AsyncTestSuite)

```
<!DOCTYPE html>
<html>
<head>
<script src="../../http/tests/inspector/resources/inspector-test.js"></script>
<script>
function test()
{
    let addedStyleSheet;
    let mainFrame = WebInspector.frameResourceManager.mainFrame;

    let suite = InspectorTest.createAsyncSuite("CSS.createStyleSheet");

    suite.addTestCase({
        name: "CheckNoStyleSheets",
        description: "Ensure there are no stylesheets.",
        test: (resolve, reject) => {
            InspectorTest.expectThat(WebInspector.cssStyleManager.styleSheets.length === 0, "Should be no stylesheets.");
            resolve();
        }
    });

    for (let i = 1; i <= 3; ++i) {
        suite.addTestCase({
            name: "CreateInspectorStyleSheetCall" + i,
            description: "Should create a new inspector stylesheet.",
            test: (resolve, reject) => {
                CSSAgent.createStyleSheet(mainFrame.id);
                WebInspector.cssStyleManager.singleFireEventListener(WebInspector.CSSStyleManager.Event.StyleSheetAdded, function(event) {
                    InspectorTest.expectThat(WebInspector.cssStyleManager.styleSheets.length === i, "Should increase the list of stylesheets.");
                    InspectorTest.expectThat(event.data.styleSheet.origin === WebInspector.CSSStyleSheet.Type.Inspector, "Added StyleSheet origin should be 'inspector'.");
                    InspectorTest.expectThat(event.data.styleSheet.isInspectorStyleSheet(), "StyleSheet.isInspectorStyleSheet() should be true.");
                    InspectorTest.expectThat(event.data.styleSheet.parentFrame === mainFrame, "Added StyleSheet frame should be the main frame.");
                    if (addedStyleSheet)
                        InspectorTest.expectThat(event.data.styleSheet !== addedStyleSheet, "Added StyleSheet should be different from the last added stylesheet.");
                    addedStyleSheet = event.data.styleSheet;
                    resolve();
                });
            }
        });
    }

    WebInspector.cssStyleManager.singleFireEventListener(WebInspector.CSSStyleManager.Event.StyleSheetRemoved, function(event) {
        InspectorTest.assert(false, "Should not be removing any StyleSheets in this test.");
    });

    suite.runTestCasesAndFinish();
}
</script>
</head>
<body onload="runTest()">
    <p>Test CSS.createStyleSheet.</p>
</body>
</html>
```
