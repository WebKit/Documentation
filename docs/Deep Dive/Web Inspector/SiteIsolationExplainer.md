# Web Inspector and Site Isolation

_Last updated 2026-02-26._

This document explains how Site Isolation affects the architecture of Web Inspector in WebKit,
describes the design changes made to support cross-process inspection, and outlines the work
remaining. For a primer on Site Isolation itself — RemoteFrames, BrowsingContextGroups, and
provisional navigation — see [Site Isolation](../SiteIsolation.md).

**Contents:**
- [Background: Inspector Agents and the Single-Process Assumption](#background-inspector-agents-and-the-single-process-assumption)
- [Background: The Inspector Target System](#background-the-inspector-target-system)
- [Two Modes of Operation](#two-modes-of-operation)
- [Architecture: Target-Based Multiplexing](#architecture-target-based-multiplexing)
- [The BackendDispatcher Fallback Chain](#the-backenddispatcher-fallback-chain)
- [Frame Target Lifecycle](#frame-target-lifecycle)
- [Domain Implementation: Console](#domain-implementation-console)
- [Domain Implementation: Network (In Progress)](#domain-implementation-network-in-progress)
- [Domain Implementation: Page (In Progress)](#domain-implementation-page-in-progress)
- [Security: Inspector-Only IPC Interfaces](#security-inspector-only-ipc-interfaces)
- [Compatibility with Legacy Backends](#compatibility-with-legacy-backends)
- [Open Questions](#open-questions)
- [Key Source Files](#key-source-files)

---

## Background: Inspector Agents and the Single-Process Assumption

Web Inspector's backend is organized as a collection of _agents_, each responsible for one
protocol domain (`Network`, `Page`, `DOM`, `Debugger`, etc.). Historically, all agents for a
given inspected page lived in a single `WebCore::Page` in a single WebContent Process. A single
`InspectorBackend` handled all commands; `InspectorBackendDispatcher` routed each JSON-RPC
command to the correct agent.

`PageInspectorController` owns the agents and the `BackendDispatcher` for a `Page`. Commands
from the frontend arrive as JSON strings, get parsed in UIProcess, and are dispatched to the
correct `PageInspectorController` via the target routing system.

This design works perfectly when all frames share one process — but breaks down under Site
Isolation, where a `WebPageProxy` may have its frames distributed across several WebContent
Processes, each with its own `Page` and `PageInspectorController`.

---

## Background: The Inspector Target System

To persist a debugging session across WebProcess swaps (introduced with PSON), the concept of
_inspector targets_ was introduced. A target is an opaque handle that:

1. Provides a stable `targetId` the frontend can route commands to across process swaps.
2. Allows the same protocol interfaces to be reused across execution context types (Page,
   Worker, JSContext, Frame).
3. Lets the frontend reason about the capabilities of each backend independently.

`WebPageInspectorController` in UIProcess manages the set of active targets. The `Target`
domain in `InspectorTargetAgent` exposes target lifecycle events (`Target.targetCreated`,
`Target.targetDestroyed`) to the frontend, and routes incoming commands to the correct target's
`BackendDispatcher`.

Before Site Isolation work, there were three target types involved in web browsing:

- **`Page`** — legacy direct-backend target (pre-PSON and WebKitLegacy). No sub-targets.
- **`WebPage`** — represents a `WebPageProxy`. May have transient worker sub-targets.
- **`Worker`** — represents a dedicated Web Worker spawned from a Page.

Site Isolation adds a fourth:

- **`Frame`** — represents an individual `WebFrameProxy` / `LocalFrame`, each potentially in
  its own WebContent Process.

---

## Two Modes of Operation

### Mode 1: SI-disabled and WebKitLegacy

When Site Isolation is off, the architecture is essentially unchanged from the pre-SI model:

- One `WebPageInspectorTargetProxy` (type `WebPage`) is created to manage the lifetime
  of the underlying `Page`, `Frame`, and `Worker` targets in the inspected webpage.
- One `PageInspectorTargetProxy` (type `Page`) is created for the one
  `PageInspectorController`.
- All agents live in one `PageInspectorController` in one WebContent Process.
- `didCreateFrame` on `WebPageInspectorController` is a no-op — no frame targets are created.
- Commands are routed through the page target to `PageInspectorController`.

### Mode 2: SI-enabled

When Site Isolation is enabled, each `WebFrameProxy` gets its own inspector target:

- Each `WebFrameProxy` creation triggers a `FrameInspectorTargetProxy` (type `Frame`) and `WI.FrameTarget` in the frontend. 
- One `PageInspectorTargetProxy` (type `Page`) still exists per web page.
- Frames intuitively belong to
  a page and frames can have subframes, but these relationships are treated as optional data fields that do not factor into the Target lifetime semantics.
- Each frame target corresponds to a `FrameInspectorController` in the owning WebContent Process.
- Commands targeted at a frame ID are routed to the correct `FrameInspectorTargetProxy`,
  which sends them over IPC to the `FrameInspectorController` in that process.

The key callsite is in `WebFrameProxy`'s constructor
(`UIProcess/WebFrameProxy.cpp`):

```cpp
page.inspectorController().didCreateFrame(*this);
```

And in the destructor, the target is torn down symmetrically:

```cpp
page->inspectorController().willDestroyFrame(*this);
```

This means frame targets are always present in the backend when frames exist, regardless of whether a
frontend is connected — consistent with how page and worker targets behave.

---

## Architecture: Target-Based Multiplexing

```
UIProcess
┌─────────────────────────────────────────────────────────┐
│  WebPageInspectorController                             │
│  ├── PageInspectorTargetProxy  (type: Page)             │
│  │     └── PageInspectorController  (in WCP-A)          │
│  ├── FrameInspectorTargetProxy  frame-1 (main)          │
│  │     └── FrameInspectorController  (in WCP-A)         │
│  └── FrameInspectorTargetProxy  frame-2 (cross-origin)  │
│        └── FrameInspectorController  (in WCP-B)         │
└─────────────────────────────────────────────────────────┘
         IPC ↕                    IPC ↕
  WebContent Process A      WebContent Process B
  PageInspectorController   PageInspectorController (not exposed)
  FrameInspectorController  FrameInspectorController
```

`InspectorTargetAgent` (in `JavaScriptCore/inspector/agents/InspectorTargetAgent.cpp`) is the
glue layer. It receives all incoming commands from the frontend, looks up the target by `targetId`,
and calls `sendMessageToTarget()` on the appropriate `InspectorTargetProxy`.

For frame targets, `FrameInspectorTargetProxy::sendMessageToTarget()` sends the message over
IPC to `FrameInspectorTarget` in the WebContent Process, which calls
`FrameInspectorController::dispatchMessageFromFrontend()`.

---

## The BackendDispatcher Fallback Chain

`FrameInspectorController` owns agents for a single frame. Not every domain has been moved to
per-frame agents yet — only `Console` is fully per-frame today. For unimplemented domains,
commands must fall through to the page-level `PageInspectorController`.

This is accomplished by passing the parent `BackendDispatcher` as a fallback when
constructing the frame-level one (`FrameInspectorController.cpp`):

```cpp
FrameInspectorController::FrameInspectorController(
    LocalFrame& frame, PageInspectorController& parentPageController)
    : m_backendDispatcher(BackendDispatcher::create(
        m_frontendRouter.copyRef(),
        &parentPageController.backendDispatcher()))  // <-- fallback
```

When `BackendDispatcher::dispatch()` receives a command for a domain not registered in
the frame-level dispatcher, it forwards the call to its fallback dispatcher — the page-level
`BackendDispatcher`. This makes per-domain migration incremental: a domain can be moved from
`PageInspectorController` to `FrameInspectorController` independently, and the fallback chain
ensures correct routing at every intermediate state.

`InstrumentingAgents` uses the same fallback pattern: a frame's `InstrumentingAgents` holds a
pointer to the parent page's `InstrumentingAgents`. When instrumentation fires in the frame
process (e.g., a network event), it first notifies frame-level agents and then falls through to
page-level agents for any domain not yet migrated.

```
Command from frontend
        │
        ▼
FrameInspectorController.backendDispatcher
        │
        │  domain registered at frame level?
        ├── yes ──► frame-level agent handles it
        │
        └── no ───► fallback to PageInspectorController.backendDispatcher
                           │
                           ▼
                    page-level agent handles it
```

---

## Frame Target Lifecycle

### Creation

`WebFrameProxy` is created in UIProcess whenever a new frame is established (both same-process
and cross-process frames). Its constructor calls `didCreateFrame()`, which calls
`addTarget()` in `WebPageInspectorController`. If a frontend is connected, this fires
`Target.targetCreated` to notify the frontend immediately.

### Connection (WebProcess side)

When a frontend connects and enumerates targets, `FrameInspectorTargetProxy::connect()`
sends an IPC message to the WebContent Process hosting the frame. On the WebProcess side,
`FrameInspectorTarget::connect()` (`WebProcess/Inspector/WebFrameInspectorTarget.cpp`)
creates a `UIProcessForwardingFrontendChannel` and connects it to `FrameInspectorController`:

```cpp
void FrameInspectorTarget::connect(
    Inspector::FrontendChannel::ConnectionType connectionType)
{
    if (m_channel)
        return;

    Ref frame = m_frame.get();
    m_channel = makeUnique<UIProcessForwardingFrontendChannel>(
        frame, identifier(), connectionType);

    if (RefPtr coreFrame = frame->coreLocalFrame())
        coreFrame->protectedInspectorController()->connectFrontend(*m_channel);
}
```

### Events flowing back to UIProcess

When a frame-level agent emits an event (e.g., `Console.messageAdded`),
`UIProcessForwardingFrontendChannel::sendMessageToFrontend()` sends it over IPC to UIProcess
(`WebProcess/Inspector/UIProcessForwardingFrontendChannel.cpp`):

```cpp
void UIProcessForwardingFrontendChannel::sendMessageToFrontend(
    const String& message)
{
    if (RefPtr page = protectedFrame()->page())
        page->send(Messages::WebPageProxy::SendMessageToInspectorFrontend(
            m_targetId, message));
}
```

UIProcess receives it in `WebPageInspectorController::sendMessageToInspectorFrontend()`, which
calls `InspectorTargetAgent::sendMessageFromTargetToFrontend()` to deliver the event — tagged
with the frame's `targetId` — to the frontend.

### Provisional Frames

During provisional navigation, a frame may briefly exist in two processes simultaneously (see
[Provisional Navigation](../SiteIsolation.md#provisional-navigation)). The inspector mirrors this:
`WebFrameProxy` is created for the provisional frame in the same constructor path, so it gets an
inspector target immediately. If the provisional load commits, the old frame target is destroyed
and the new one persists. If the load fails, the provisional frame target is destroyed with no
observable change to the frontend.

### Destruction

`WebFrameProxy`'s destructor calls `willDestroyFrame()`. `WebPageInspectorController`
removes the target and fires `Target.targetDestroyed` to the frontend.

---

## Domain Implementation: Console

`Console` is the first domain fully migrated to per-frame agents. Each `FrameInspectorController`
owns a `FrameConsoleAgent` (see the constructor in `FrameInspectorController.cpp`). Console
messages originating from cross-origin iframes now appear in Web Inspector correctly attributed
to the originating frame, rather than being lost or mis-attributed.

---

## Domain Implementation: Network (In Progress)

Network and Page domains remain as **Page Target agents** — they do not become per-frame agents
and there is no `BackendDispatcher` fallback involved. Instead, the design splits each domain
agent across two processes:

- **UIProcess side** — `ProxyingNetworkAgent` / `ProxyingPageAgent` live in UIProcess as part
  of `WebPageInspectorController`. They handle all command dispatch and own the authoritative
  view of network and page state.
- **WebContent Process side** — A `NetworkAgentProxy` in each WebContent Process hooks into
  `InstrumentingAgents` to capture per-frame network events (resource loads, responses, etc.)
  and forwards them over IPC to the UIProcess agent.

This means command routing for Network and Page never traverses the `FrameInspectorController`
fallback chain. All Network/Page commands arrive at the UIProcess agent directly via the Page
target, and the UIProcess agent is responsible for fanning out to the appropriate WebContent
Process when per-frame data is needed (e.g., `Network.getResponseBody`).

---

### Response Body Retrieval (`getResponseBody`)

Under the single-process model, `Network.getResponseBody` reads directly from
`NetworkResourcesData` in the same process as the agent. Under SI, the response body
lives in whichever WebContent Process loaded the resource — the UIProcess proxy agent
must route the request to the correct process.

The design introduces `BackendResourceDataStore`, a per-page data store in the WebKit
layer (`WebProcess/Inspector/`) that buffers resource metadata and response content
independently of the inspector agent lifecycle. `NetworkAgentProxy` writes to the store
at each instrumentation point (`willSendRequest`, `responseReceived`, `dataReceived`);
`ProxyingNetworkAgent` reads from it via IPC when the frontend requests a body.

```
Frontend                UIProcess                    WebProcess(es)
                        ProxyingNetworkAgent
Network.getResponseBody ──►  look up requestId
(requestId: "r-42")          in m_requestIdToResourceKey
                             ──► {ProcessB, ResourceID-7}
                                                     ┌──────────────────────┐
                        QueryResponseBody(ResID-7) ──►│ BackendResourceData  │
                                                      │ Store                │
                        ◄── (content, base64Encoded) ──│ entry for ResID-7   │
                                                      └──────────────────────┘
respond to frontend ◄──
```

The UIProcess maintains a `HashMap<String, BackendResourceKey>` mapping each frontend-facing
`requestId` string to a `BackendResourceKey { WebProcessIdentifier, BackendResourceIdentifier }`.
This mapping is populated when `requestWillBeSent` IPC arrives from each WebProcess, ensuring
that `getResponseBody` routes to the process that actually loaded the resource — even when the
same URL was loaded by multiple processes.

## Domain Implementation: Page (In Progress)

`Page` domain adaptation mirrors Network. `Page.getResourceTree` must collect and merge frame
subtrees from each WebContent Process. The merged result presents the frontend with a unified
frame tree even though resources are distributed across processes.

### `getResourceTree` Aggregation

The legacy implementation in `LegacyPageAgent::getResourceTree()` calls
`buildObjectForFrameTree(localMainFrame.get())`, which recursively traverses
`frame->tree().traverseNext()`. This only visits `LocalFrame` children — under SI,
cross-origin subframes are `RemoteFrame` instances and are invisible to this traversal.
The same limitation affects `searchInResources`, which has an explicit FIXME:

```cpp
// LegacyPageAgent.cpp:632
// FIXME: rework this frame tree traversal as it won't work with Site Isolation enabled.
for (Frame* frame = &m_inspectedPage->mainFrame(); frame; frame = frame->tree().traverseNext()) {
    auto* localFrame = dynamicDowncast<LocalFrame>(frame);
    if (!localFrame)
        continue;
    // ...
}
```

When Site Isolation is disabled, the Page domain is handled entirely in the WebProcess —
`LegacyPageAgent` traverses the frame tree directly and there is only one process, so
`LocalFrame` covers all frames.

When Site Isolation is enabled, `ProxyingPageAgent::getResourceTree()` fans out to every
WebContent Process hosting frames for the inspected page:

1. `ProxyingPageAgent` creates a ref-counted `ResourceTreeAggregator` with a completion
   callback (following the `LegacyWebArchiveCallbackAggregator` pattern).
2. Each WebContent Process's `PageAgentProxy` responds with a flat list of frames and their
   subresources: `{ frameId, parentFrameId, url, mimeType, securityOrigin, resources[] }`.
3. As each reply arrives, `ResourceTreeAggregator::addPartialResult()` merges the subtree
   into the accumulated frame tree, using `WebPageProxy`'s frame hierarchy to determine
   parent-child relationships.
4. When all replies have arrived (or a timeout fires), the aggregator's destructor assembles
   the final `Protocol::Page::FrameResourceTree` and calls the completion handler.

Remote frames — frames that appear as stubs in one process because they are hosted in
another — are replaced with the real frame data from the owning process during merge.

Phases:
- **Phase 1** — `getResourceTree` aggregation across frame targets (in progress)
- **Phase 2** — `searchInResources` across all frame targets
- **Phase 3** — `getResourceContent` with correct process routing
- **Phase 4** — Resource load events aggregated from all processes

---

## Security: Inspector-Only IPC Interfaces

The proxying agent architecture introduces new IPC channels between UIProcess and WebContent
Processes. These channels do **not** expand the attack surface — they are only active when
Web Inspector is open and connected, and are scoped to the inspected page.

### Dynamic IPC Receiver Registration

`ProxyingPageAgent` and `ProxyingNetworkAgent` in UIProcess dynamically register and
deregister themselves as IPC message receivers when the corresponding protocol domain is
enabled or disabled by the frontend:

**Enable (domain activated by frontend):**

```cpp
// ProxyingPageAgent::enable()
protectedInspectedPage()->forEachWebContentProcess([&](auto& webProcess, auto pageID) {
    webProcess.addMessageReceiver(Messages::ProxyingPageAgent::messageReceiverName(), pageID, *this);
    webProcess.send(Messages::WebInspectorBackend::EnablePageInstrumentation { }, pageID);
});
```

**Disable (domain deactivated or Inspector closes):**

```cpp
// ProxyingPageAgent::disable()
protectedInspectedPage()->forEachWebContentProcess([&](auto& webProcess, auto pageID) {
    webProcess.send(Messages::WebInspectorBackend::DisablePageInstrumentation { }, pageID);
    webProcess.removeMessageReceiver(Messages::ProxyingPageAgent::messageReceiverName(), pageID);
});
```

When Inspector is closed, no handler is registered for these messages. The IPC infrastructure
rejects any message targeting a non-existent receiver.

### Conditional WebProcess Instrumentation

On the WebProcess side, `PageAgentProxy` and `NetworkAgentProxy` register with
`InstrumentingAgents` only when enabled:

```cpp
// PageAgentProxy::enable()
agents->setEnabledPageAgentInstrumentation(this);

// PageAgentProxy::disable()
agents->setEnabledPageAgentInstrumentation(nullptr);
```

When disabled, instrumentation hooks in WebCore (e.g., `willSendRequest`,
`frameNavigated`) find no registered proxy in the `InstrumentingAgents` registry.
The hooks become no-ops — no data is collected and no IPC messages are sent.

### Ordering Guarantees

The enable/disable sequences are ordered to prevent race conditions:

1. **Enable:** Register the UIProcess IPC receiver _first_, then tell the WebProcess to
   start sending. The receiver is ready before any messages arrive.
2. **Disable:** Tell the WebProcess to stop sending _first_, then remove the UIProcess
   IPC receiver. No in-flight messages arrive at a deregistered receiver.

### Per-Page Scoping

IPC receivers are registered with the inspected page's identifier as the destination:

```cpp
webProcess.addMessageReceiver(
    Messages::ProxyingPageAgent::messageReceiverName(), pageID, *this);
```

Only WebContent Processes hosting the inspected page can address these handlers.
Processes for other pages cannot send to them. The `[ExceptionForEnabledBy]` attribute
in the `.messages.in` definitions provides an additional safeguard.

### Summary

| Condition | UIProcess Receiver | WebProcess Instrumentation | IPC Traffic |
|-----------|-------------------|---------------------------|-------------|
| Inspector closed | Not registered | Not registered | None |
| Inspector open, domain enabled | Registered (inspected page only) | Registered with InstrumentingAgents | Active |
| Inspector open, domain not enabled | Not registered | Not registered | None |

These IPC channels exist only for the duration of an active Inspector session, are scoped
to a single inspected page, and are torn down completely when Inspector disconnects.

---

## Compatibility with Legacy Backends

Web Inspector must continue to work with backends shipping in iOS 13 and later, which have no
Frame targets. The frontend's target iteration logic handles this:

- If a `WebPage` target has associated `Frame` targets → send per-frame commands to the
  frame targets.
- If a `WebPage` target has no associated `Frame` targets (older backend) → treat the page
  target as the single frame and send all commands there.

No frontend code needs to know whether it is talking to a single-process backend or a
Site-Isolated backend — the frame target abstraction provides uniform addressing.

---

## Open Questions

1. **DOM domain across process boundaries** — DOM `nodeId` values are process-local integers.
   Under Site Isolation, nodes from different processes may have colliding IDs. A global
   identifier scheme (possibly an extension of `InspectorIdentifierRegistry`) is needed before
   DOM can be migrated to per-frame agents.

---

## Key Source Files

| File | Role |
|------|------|
| `UIProcess/Inspector/WebPageInspectorController.h/.cpp` | Manages all targets for a `WebPageProxy` |
| `UIProcess/Inspector/FrameInspectorTargetProxy.h/.cpp` | Frame target proxy in UIProcess |
| `UIProcess/Inspector/PageInspectorTargetProxy.h/.cpp` | Page target proxy in UIProcess |
| `UIProcess/Inspector/InspectorTargetProxy.h` | Base class for all target proxies |
| `UIProcess/WebFrameProxy.cpp` | Creates/destroys frame inspector targets on frame lifecycle |
| `WebProcess/Inspector/WebFrameInspectorTarget.h/.cpp` | Frame target in WebContent Process |
| `WebProcess/Inspector/UIProcessForwardingFrontendChannel.cpp` | IPC: WebProcess → UIProcess for events |
| `WebCore/inspector/FrameInspectorController.h/.cpp` | Per-frame agent controller with fallback chain (frame-targeted domains) |
| `WebCore/inspector/PageInspectorController.h/.cpp` | Per-page agent controller (legacy + fallback target) |
| `WebCore/inspector/InstrumentingAgents.h` | Agent registry with fallback to parent controller |
| `WebKit/UIProcess/Inspector/ProxyingNetworkAgent.h/.cpp` | Network agent in UIProcess; receives events from per-WP `NetworkAgentProxy` |
| `WebKit/UIProcess/Inspector/ProxyingPageAgent.h/.cpp` | Page agent in UIProcess; handles `getResourceTree` aggregation |
| `WebProcess/Inspector/PageAgentProxy.cpp` | Page instrumentation proxy; conditionally registers with InstrumentingAgents |
| `WebProcess/Inspector/NetworkAgentProxy.cpp` | Network instrumentation proxy; conditionally registers with InstrumentingAgents |
| `WebProcess/Inspector/WebInspectorBackend.messages.in` | Enable/Disable instrumentation IPC messages |
| `UIProcess/Inspector/Agents/ProxyingPageAgent.messages.in` | Events from WebProcess; guarded by `[ExceptionForEnabledBy]` |
| `UIProcess/Inspector/Agents/ProxyingNetworkAgent.messages.in` | Events from WebProcess; guarded by `[ExceptionForEnabledBy]` |
| `JavaScriptCore/inspector/agents/InspectorTargetAgent.cpp` | Target multiplexing and command routing |
| `JavaScriptCore/inspector/InspectorBackendDispatcher.cpp` | `BackendDispatcher` with fallback dispatcher |
