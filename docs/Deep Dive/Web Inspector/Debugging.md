# Debugging Web Inspector

This guide covers techniques for debugging the Web Inspector frontend itself -- the JavaScript application that provides WebKit's developer tools UI. It is organized around problems you will encounter when developing and testing Web Inspector.

Throughout this guide, "engineering build" means a Debug or Release build where `COMBINE_INSPECTOR_RESOURCES=NO`. The `Debug/Bootstrap.js` file is included and sets `WI.isEngineeringBuild = true`, which enables Engineering and Debug settings panes, the Debug UI toggle, and the "inspect inspector" button. Production builds combine all JS/CSS into `Main.js`/`Main.css` and strip the `Debug/` directory entirely.

## "My change isn't showing up"

You edited a JavaScript or CSS file under `Source/WebInspectorUI/UserInterface/`, but Web Inspector still shows the old behavior.

**Root cause:** Inspector frontend files are copied from the source tree into the framework bundle during the build. Editing a source file does not update the running copy.

**Fast JS-only rebuild:**

```bash
make -C Source/WebInspectorUI/
```

This invokes `copy-user-interface-resources.pl` to re-copy files. It completes nearly instantly because no compilation is involved -- just file copies via `ditto`. This is dramatically faster than a full `make GROUP=webkit debug` (~60 seconds).

For a fully automated workflow, use the `watch-webinspectorui` script, which watches for file changes and re-copies automatically:

```bash
Tools/Scripts/watch-webinspectorui
```

After rebuilding, reload the Inspector to pick up changes:

- Press **Option + Shift + Command + R** (calls `InspectorFrontendHost.reopen()`)
- Or right-click in the Inspector (with Debug UI enabled) and choose **"Reload Web Inspector"**

**When you need a full rebuild:** If you changed C++ code in `Source/WebKit/`, `Source/WebCore/inspector/`, or `Source/JavaScriptCore/inspector/`, use `make GROUP=webkit debug`.

## "I need to see protocol messages"

You suspect protocol commands are not being sent, events are not arriving, or parameters are wrong.

### Option 1: Debug UI toggle (engineering builds)

1. Press **Option + Shift + Command + D** to reveal the Debug UI.
2. Click the **console icon button** in the tab bar:
   - **Click** = filtered logging (hides `(multi)` target messages).
   - **Shift-click** = unfiltered logging (shows everything). Button turns **purple**.
   - **Click again** = off.

Messages appear in the Inspector console. To view them, open Inspector^2 (see below).

### Option 2: Settings tab (engineering builds)

Open Settings (gear icon). Under **Debug > Protocol Logging:**

| Setting | Effect |
|---------|--------|
| **Messages** | Logs all protocol messages (`InspectorBackend.dumpInspectorProtocolMessages`) |
| **Time Stats** | Adds RTT and dispatch timing per message |
| **Log as Text** | Forces JSON strings instead of expandable objects |

### Option 3: Programmatic flags

```javascript
InspectorBackend.dumpInspectorProtocolMessages = true;
InspectorBackend.filterMultiplexingBackendInspectorProtocolMessages = false;
InspectorBackend.dumpInspectorTimeStats = true;
```

Each logged message is formatted by `LoggingProtocolTracer` as:

```
request (page-1): {"id":42,"method":"DOM.getDocument","params":{}}
response (page-1): {"id":42,"result":{"root":{...}}}
event (page-1): {"method":"DOM.documentUpdated","params":{}}
```

Target identifiers: `(multi)` = multiplexing backend, `(page-N)` = page target, `(frame-N)` = frame target (Site Isolation), `(worker-N)` = worker target.

### Option 4: Capture a protocol trace

In engineering builds with Debug UI enabled, right-click > **Protocol Debugging > Capture Trace**. Perform actions, then right-click > **Export Trace...** to save as JSON.

## "I need to set a breakpoint in Inspector JS code"

Web Inspector is itself a web page rendered by a WKWebView. You can open a second instance to debug the first ("Inspector^2").

### Method 1: Debug UI button (engineering builds)

1. Open Web Inspector on any page.
2. Press **Option + Shift + Command + D** to enable Debug UI.
3. Click the **numbered button** in the tab bar (shows "2"). A new Inspector window opens.

Under the hood, the button calls `InspectorFrontendHost.inspectInspector()`, which enables `developerExtrasEnabled` on the Inspector's page and opens a new inspector controller.

### Method 2: Settings (all builds)

Open Settings > **Experimental** > check **"Allow Inspecting Web Inspector"**. In engineering builds, the numbered button appears in Debug UI. In non-engineering builds, use Safari's **Develop** menu -- the Inspector's WebContent process appears as an inspectable target.

### Method 3: defaults write (release builds)

```bash
defaults write com.apple.Safari WebKitDebugWebInspectorEngineeringSettingsAllowed -bool true
```

### Inspection levels

Each nested inspector has an `inspectionLevel` property (via `InspectorFrontendHost.inspectionLevel`). Level 1 is the normal Inspector; level 2 is Inspector^2. Each level gets its own preferences namespace, so settings do not collide.

## "My test is timing out"

Inspector layout tests are asynchronous. Common timeout causes: waiting for events that never fire (wrong event name or wrong class), unresolved promises, or silently swallowed exceptions.

### Step 1: Enable debug logging

Call `InspectorTest.debug()`:

```javascript
function test()
{
    InspectorTest.debug();
    // ... rest of test
}
```

This enables both `dumpActivityToSystemConsole` (tees output to stderr) and `dumpInspectorProtocolMessages` (logs all protocol traffic).

For maximum visibility, set all flags individually:

```javascript
InspectorTest.forceDebugLogging = true;
InspectorTest.dumpActivityToSystemConsole = true;
InspectorBackend.dumpInspectorProtocolMessages = true;
InspectorBackend.filterMultiplexingBackendInspectorProtocolMessages = false;
```

| Flag | Effect |
|------|--------|
| `forceDebugLogging` | Routes `log()` through `debugLog()` (synchronous stderr). Survives timeouts. |
| `dumpActivityToSystemConsole` | Tees `addResult`, `completeTest` calls to stderr |
| `dumpInspectorProtocolMessages` | Logs every protocol message to stderr |
| `filterMultiplexingBackendInspectorProtocolMessages` | When `false`, includes `(multi)` messages |

For **protocol tests**: use `ProtocolTest.debug()` or the equivalent `ProtocolTest.*` flags.

### Step 2: Verify event names exist

```bash
grep -r "WI.Frame.Event.ExecutionContextChanged" Source/WebInspectorUI/
```

If zero results, the event does not exist on that class. Check adjacent classes -- naming is inconsistent (e.g., `WI.Frame.Event` vs. `WI.FrameTarget.Event` vs. `WI.Target.Event`).

## "I can't read the stack traces"

Stack frames reference `Main.js` at high line numbers, or all Inspector code appears in a single file.

**Root cause:** The build combined all JavaScript into `Main.js`. Controlled by:

| Setting | Base.xcconfig (Production) | DebugRelease.xcconfig (Engineering) |
|---------|---------------------------|-------------------------------------|
| `COMBINE_INSPECTOR_RESOURCES` | `YES` | `NO` |
| `COMBINE_TEST_RESOURCES` | `NO` | `YES` |

Note the inversion: engineering builds keep Inspector resources separate but combine test resources.

**Solution:** Use a Debug or Release engineering build.

## "I need to debug Inspector C++ backend code"

### Identifying the correct process

| Code location | Process |
|--------------|---------|
| `Source/WebKit/UIProcess/Inspector/` | UI Process (Safari/MiniBrowser) |
| `Source/WebCore/inspector/agents/` | Inspected WebContent Process |
| `Source/WebKit/WebProcess/Inspector/WebInspectorUI.cpp` | Inspector's own WebContent Process |
| `Source/JavaScriptCore/inspector/` | WebContent Process (JSC layer) |

### System console logging

In debug builds, Inspector `console.log()` output is routed to the system console automatically. For release builds:

```bash
defaults write com.apple.Safari WebKitDebugLogsPageMessagesToSystemConsoleEnabled -bool true
```

### WebKit logging channels

```bash
defaults write com.apple.Safari WebKit2Logging "Inspector=debug"
defaults write com.apple.Safari WebCoreLogging "Inspector=debug"
```

Replace `com.apple.Safari` with the appropriate bundle identifier.

## Debugging in iOS Simulator

1. Build: `Tools/Scripts/build-webkit --debug --ios-simulator`
2. Launch: `Tools/Scripts/run-safari --debug --ios-simulator`
3. On Mac, open Safari > **Develop > Simulator** to see inspectable pages.

The Inspector frontend runs on macOS, connecting via the remote inspector protocol (`RemoteWebInspectorUI`/`RemoteWebInspectorUIProxy`).

## Engineering and Debug settings reference

### Engineering pane

Available when `WI.engineeringSettingsAllowed()` returns true:

| Setting | Description |
|---------|-------------|
| Allow editing UserAgent shadow trees | Permits DOM editing of browser-generated shadow DOM |
| Show WebKit-internal execution contexts | Reveals internal contexts in the console picker |
| Show WebKit-internal scripts | Shows internal scripts in the Sources tab |
| Pause in WebKit-internal scripts | Allows breakpoints in internal scripts |
| Show Internal Objects (Heap Snapshot) | Displays JSC-internal heap objects |
| Show Private Symbols (Heap Snapshot) | Displays private symbol properties |

### Debug pane

Available in engineering builds when Debug UI is enabled. Toggle Debug UI via:

- **Keyboard:** Option + Shift + Command + D
- **Settings:** Engineering → **Show Debug UI** checkbox

| Setting | Description |
|---------|-------------|
| Messages | Log all protocol messages to console |
| Time Stats | Log protocol message timing data |
| Log as Text | Force JSON text output instead of structured objects |
| Outline focused element | Draw outline around focused Inspector UI element |
| Layout Flashing | Draw borders when views perform layout |
| Style editing debug mode | Enable verbose CSS editing logging |
| Report Uncaught Exceptions | Show dialog on uncaught frontend exceptions |
| Layout Direction | Override layout direction (LTR/RTL/System) |

## Quick reference

| I want to... | Do this |
|--------------|---------|
| Rebuild after changing Inspector JS/CSS | `make -C Source/WebInspectorUI/` |
| Rebuild after changing Inspector C++ | `make GROUP=webkit debug` |
| Reload Inspector without restarting page | Option + Shift + Cmd + R |
| Toggle Debug UI | Option + Shift + Cmd + D |
| See protocol messages interactively | Debug UI > click console icon |
| See protocol messages in a test | `InspectorTest.debug()` or `ProtocolTest.debug()` |
| Debug Inspector JS with a debugger | Settings > Experimental > "Allow Inspecting Web Inspector" |
| Get readable stack traces | Use a Debug or Release build (`COMBINE_INSPECTOR_RESOURCES=NO`) |
| Enable C++ logging | `defaults write <bundle-id> WebKit2Logging "Inspector=debug"` |
| Enable engineering settings in release | `defaults write <bundle-id> WebKitDebugWebInspectorEngineeringSettingsAllowed -bool true` |
| Verify an event name exists | `grep -r "WI.ClassName.Event.Name" Source/WebInspectorUI/` |
| Capture protocol traffic to file | Debug UI > right-click > Protocol Debugging > Capture Trace |
