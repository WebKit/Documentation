# Web Inspector Testing

Web Inspector tests are layout tests that exercise the browser developer tools built into WebKit. They live under `LayoutTests/inspector/` and run via `run-webkit-tests`. Each test opens a Web Inspector frontend connected to the test page, runs JavaScript in the frontend context, and produces text output compared against an `-expected.txt` baseline.

The architecture has two sides:

- **The test page** -- the HTML file loaded by the test runner. It defines a `test()` function and includes one of two harness scripts.
- **The inspector frontend** -- a separate JavaScript context where `WI.*` is available. Your `test()` function is serialized and evaluated here.

The `test()` function does not run in the page. It runs inside the inspector. This is the single most important thing to understand.

## Your First Test

Create `LayoutTests/inspector/unit-tests/my-first-test.html`:

```html
<!DOCTYPE html>
<html>
<head>
<script src="../../http/tests/inspector/resources/inspector-test.js"></script>
<script>
function test()
{
    let suite = InspectorTest.createSyncSuite("MyFirstTest");

    suite.addTestCase({
        name: "AddingNumbers",
        test() {
            InspectorTest.expectEqual(1 + 1, 2, "1 + 1 should equal 2.");
            return true;
        }
    });

    suite.runTestCasesAndFinish();
}
</script>
</head>
<body onload="runTest()">
<p>Basic arithmetic assertions.</p>
</body>
</html>
```

The matching `my-first-test-expected.txt`:

```
Basic arithmetic assertions.


== Running test suite: MyFirstTest
-- Running test case: AddingNumbers
PASS: 1 + 1 should equal 2.

```

Run it:

```bash
Tools/Scripts/run-webkit-tests inspector/unit-tests/my-first-test.html
```

Every inspector test follows this pattern: include a harness script, define `test()` with suites and test cases, and trigger via `<body onload="runTest()">`.

## Two Harnesses

| Harness | Script | Global | Use when |
|---------|--------|--------|----------|
| **Frontend** | `inspector-test.js` | `InspectorTest` | You need `WI.*` managers, model objects, or the event system |
| **Protocol** | `protocol-test.js` | `ProtocolTest` | You need raw protocol messages via `InspectorProtocol` |

Frontend tests load the full inspector frontend. Protocol tests load a minimal stub (`TestStub.js`) with only `InspectorProtocol` and `ProtocolTest` -- no `WI.*` namespace.

## Async Tests with Protocol Agents

Most real tests are asynchronous:

```html
<script src="../../http/tests/inspector/resources/inspector-test.js"></script>
<script>
function test()
{
    let suite = InspectorTest.createAsyncSuite("Runtime.BasicEvaluate");

    suite.addTestCase({
        name: "EvaluateExpression",
        async test() {
            let response = await WI.mainTarget.RuntimeAgent.evaluate("2 + 3");
            InspectorTest.expectEqual(response.result.value, 5, "2 + 3 should equal 5.");
        }
    });

    suite.runTestCasesAndFinish();
}
</script>
```

Key differences from sync tests: use `createAsyncSuite`, mark `test()` as `async`, and protocol agents (`RuntimeAgent`, `DOMAgent`, etc.) return promises. Access agents through the target -- `WI.mainTarget.RuntimeAgent` -- rather than bare globals; using the agent directly without a target is deprecated.

## Testing with Page Content

Functions defined outside `test()` run on the **test page**. Use `evaluateInPage()` to bridge from the inspector context:

```javascript
// Page-side (in <script>, outside test()):
function updateElement() {
    document.getElementById("target").setAttribute("data-value", "updated");
}

// Inspector-side (inside test()):
suite.addTestCase({
    name: "DOM.AttributeChanged",
    async test() {
        await Promise.all([
            node.awaitEvent(WI.DOMNode.Event.AttributeModified),
            InspectorTest.evaluateInPage("updateElement()")
        ]);
        InspectorTest.pass("Attribute modification event received.");
    }
});
```

The `Promise.all` pattern -- listening for an event while triggering the action -- is the standard way to avoid race conditions. Set up the listener before triggering the action.

## Protocol Tests

Protocol tests use `InspectorProtocol` for raw message sending:

```javascript
// awaitCommand -- returns a Promise resolving with the result
let {root} = await InspectorProtocol.awaitCommand({
    method: "DOM.getDocument", params: {}
});

// awaitEvent -- one-shot event listener returning a Promise
let event = await InspectorProtocol.awaitEvent({event: "Debugger.scriptParsed"});

// addEventListener / removeEventListener for persistent listeners
InspectorProtocol.addEventListener("Network.requestWillBeSent", handler);

// Unconditional pass (useful for event-driven tests)
ProtocolTest.pass("Event received successfully.");
```

## Test Suites and Test Cases

### AsyncTestSuite (most common)

Created via `InspectorTest.createAsyncSuite("Name")` or `ProtocolTest.createAsyncSuite("Name")`. Test cases run sequentially. Default timeout: 10 seconds (override with `timeout` property; `-1` disables).

### SyncTestSuite

Created via `InspectorTest.createSyncSuite("Name")`. Test functions must be non-async and `return true` for success.

### Test Case Shape

```javascript
{
    name: "SuiteName.TestCaseName",   // Required
    description: "What this tests.",   // Optional (does not appear in output)
    test() { ... },                    // Required (sync or async)
    setup() { ... },                   // Optional, runs before test
    teardown() { ... },                // Optional, runs after test
    timeout: 10000,                    // Optional (ms), -1 to disable
}
```

If `setup` throws, both `test` and `teardown` are skipped. A failing test case does not abort the suite -- remaining cases continue.

Always end with `suite.runTestCasesAndFinish()`.

## Assertion API

Available on both `InspectorTest` and `ProtocolTest`. Each logs `PASS:` or `FAIL:` with diagnostics.

### Truthiness and Existence

| Method | Passes when |
|--------|-------------|
| `expectThat(actual, msg)` | `!!actual` is true |
| `expectFalse(actual, msg)` | `!actual` is true |
| `expectNull(actual, msg)` | `actual === null` |
| `expectNotNull(actual, msg)` | `actual !== null` |
| `expectEmpty(actual, msg)` | Array/Set/Map/object has no entries |
| `expectNotEmpty(actual, msg)` | Has entries |

### Equality and Comparison

| Method | Passes when |
|--------|-------------|
| `expectEqual(actual, expected, msg)` | `actual === expected` |
| `expectNotEqual(actual, expected, msg)` | `actual !== expected` |
| `expectShallowEqual(actual, expected, msg)` | `Object.shallowEqual(actual, expected)` |
| `expectEqualWithAccuracy(actual, expected, accuracy, msg)` | `\|actual - expected\| <= accuracy` |
| `expectLessThan(actual, expected, msg)` | `actual < expected` |
| `expectGreaterThan(actual, expected, msg)` | `actual > expected` |
| `expectException(work)` | `work()` throws or rejects |

### Manual and Logging

| Method | Description |
|--------|-------------|
| `pass(msg)` / `fail(msg)` | Unconditional PASS/FAIL |
| `assert(condition, msg)` | Logs `ASSERT: msg` only on failure |
| `log(msg)` | Write to test output |
| `json(obj)` | Pretty-printed JSON to test output |

## Helper Scripts and TestPage.registerInitializer

Shared utilities in `resources/` directories use `TestPage.registerInitializer` to inject code into the inspector frontend:

```javascript
// resources/my-helpers.js
TestPage.registerInitializer(() => {
    window.myHelper = function() {
        InspectorTest.log("Helper called!");
    };
});
```

Include before the test script. The initializer is stringified and evaluated in the frontend before `test()` runs.

## Site Isolation Test Patterns

Tests under `http/tests/site-isolation/inspector/` verify inspector behavior with cross-process iframes. Key patterns:

- **Cross-origin iframes** use `localhost` vs `127.0.0.1` (both served by the test HTTP server). Note that `127.0.0.1` is the default origin for tests under `http/tests/`.
- **Await new targets** via `WI.targetManager.awaitEvent(WI.TargetManager.Event.TargetAdded)`
- **Use `StableIdMap`** for deterministic output (target/frame IDs change between runs)

## Writing Deterministic Output

| Problem | Solution |
|---------|----------|
| Object/target IDs change | `StableIdMap` assigns sequential integers |
| File paths differ | `TestHarness.sanitizeURL()` strips to filename |
| Stack traces | `suppressStackTraces = true` |
| Nondeterministic ordering | Collect into a set, check membership |

## Debugging Tests

```javascript
InspectorBackend.dumpInspectorProtocolMessages = true;                      // protocol traffic to stderr
InspectorBackend.filterMultiplexingBackendInspectorProtocolMessages = false; // include SI routing
InspectorTest.forceDebugLogging = true;                                     // log() to stderr
InspectorTest.dumpActivityToSystemConsole = true;                           // lifecycle to stderr
```

Or use the shortcut: `InspectorTest.debug()` / `ProtocolTest.debug()`.

**Verify event names before use:** `grep -r "WI.ClassName.Event.Name" Source/WebInspectorUI/`

## Running Tests

```bash
Tools/Scripts/run-webkit-tests inspector/                                    # all
Tools/Scripts/run-webkit-tests inspector/dom/attributeModified.html          # single
Tools/Scripts/run-webkit-tests http/tests/site-isolation/inspector/          # SI tests
Tools/Scripts/run-webkit-tests -v inspector/unit-tests/                      # verbose
Tools/Scripts/run-webkit-tests --reset-results inspector/my-test.html       # rebaseline
```

## Common Patterns

**Parameterized test cases** -- factory function:

```javascript
function addTestCase({name, expression, expected}) {
    suite.addTestCase({
        name,
        async test() {
            let response = await WI.mainTarget.RuntimeAgent.evaluate(expression);
            InspectorTest.expectEqual(response.result.value, expected, `${expression} = ${expected}.`);
        }
    });
}
```

**WebKitTestRunner options** via HTML comment: `<!DOCTYPE html> <!-- webkit-test-runner [ jscOptions=--useShadowRealm=1 ] -->`

**Dispatching events from page to frontend:**

```javascript
// Page-side:
TestPage.dispatchEventToFrontend("TestPage-myEvent", {data: 123});
// Inspector-side:
let event = await InspectorTest.awaitEvent("TestPage-myEvent");
```
