# Web Inspector and Site Isolation

_Last updated 2026-02-25._

This document explains how Site Isolation affects the architecture of Web Inspector in WebKit,
describes the design changes made to support cross-process inspection, and outlines the work
remaining. For a primer on Site Isolation itself — RemoteFrames, BrowsingContextGroups, and
provisional navigation — see [Site Isolation](../SiteIsolation.md).

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
   Worker, Frame).
3. Lets the frontend reason about the capabilities of each backend independently.

`WebPageInspectorController` in UIProcess manages the set of active targets. The `Target`
domain in `InspectorTargetAgent` exposes target lifecycle events (`Target.targetCreated`,
`Target.targetDestroyed`) to the frontend, and routes incoming commands to the correct target's
`BackendDispatcher`.

Before Site Isolation work, there were three target types:

- **`Page`** — legacy direct-backend target (pre-PSON and WebKitLegacy). No sub-targets.
- **`WebPage`** — represents a `WebPageProxy`. May have transient worker and frame sub-targets.
- **`Worker`** — represents a dedicated Web Worker spawned from a Page.

Site Isolation adds a fourth:

- **`Frame`** — represents an individual `WebFrameProxy` / `LocalFrame`, each potentially in
  its own WebContent Process.

---

## Two Modes of Operation

### Mode 1: SI-disabled (or WebKitLegacy)

When Site Isolation is off, the architecture is essentially unchanged from the pre-SI model:

- One `WebPageInspectorTargetProxy` (type `WebPage`) is created for the `WebPageProxy`.
- All agents live in one `PageInspectorController` in one WebContent Process.
- `didCreateFrame` on `WebPageInspectorController` is a no-op — no frame targets are created.
- Commands are routed through the page target to `PageInspectorController`.

### Mode 2: SI-enabled

When Site Isolation is enabled, each `WebFrameProxy` gets its own inspector target:

- One `WebPageInspectorTargetProxy` still exists for page-level agents.
- Each `WebFrameProxy` creation triggers a `WebFrameInspectorTargetProxy` (type `Frame`).
- Each frame target connects to a `FrameInspectorController` in the owning WebContent Process.
- Commands targeted at a frame ID are routed to the correct `WebFrameInspectorTargetProxy`,
  which sends them over IPC to the `FrameInspectorController` in that process.

The key callsite is in `WebFrameProxy`'s constructor
(`UIProcess/WebFrameProxy.cpp`):

```cpp
page.inspectorController().createWebFrameInspectorTarget(
    *this, WebFrameInspectorTarget::toTargetID(frameID));
```

And in the destructor, the target is torn down symmetrically:

```cpp
page->inspectorController().destroyInspectorTarget(
    WebFrameInspectorTarget::toTargetID(frameID()));
```

This means frame targets are always present when frames exist, regardless of whether a
frontend is connected — consistent with how page and worker targets behave.

---

## Architecture: Target-Based Multiplexing

```
UIProcess
┌─────────────────────────────────────────────────────────┐
│  WebPageInspectorController                             │
│  ├── WebPageInspectorTargetProxy  (type: WebPage)       │
│  │     └── PageInspectorController  (in WCP-A)          │
│  ├── WebFrameInspectorTargetProxy  frame-1 (main)       │
│  │     └── FrameInspectorController  (in WCP-A)         │
│  └── WebFrameInspectorTargetProxy  frame-2 (cross-origin)
│        └── FrameInspectorController  (in WCP-B)         │
└─────────────────────────────────────────────────────────┘
         IPC ↕                    IPC ↕
  WebContent Process A      WebContent Process B
  PageInspectorController   (no PageInspectorController)
  FrameInspectorController  FrameInspectorController
```

`InspectorTargetAgent` (in `JavaScriptCore/inspector/agents/InspectorTargetAgent.cpp`) is the
glue layer. It receives all incoming commands from the frontend, looks up the target by `targetId`,
and calls `sendMessageToTarget()` on the appropriate `InspectorTargetProxy`.

For frame targets, `WebFrameInspectorTargetProxy::sendMessageToTarget()` sends the message over
IPC to `WebFrameInspectorTarget` in the WebContent Process, which calls
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
and cross-process frames). Its constructor calls `createWebFrameInspectorTarget()`, which calls
`addTarget()` in `WebPageInspectorController`. If a frontend is connected, this fires
`Target.targetCreated` to notify the frontend immediately.

### Connection (WebProcess side)

When a frontend connects and enumerates targets, `WebFrameInspectorTargetProxy::connect()`
sends an IPC message to the WebContent Process hosting the frame. On the WebProcess side,
`WebFrameInspectorTarget::connect()` (`WebProcess/Inspector/WebFrameInspectorTarget.cpp`)
creates a `WebFrameInspectorTargetFrontendChannel` and connects it to `FrameInspectorController`:

```cpp
void WebFrameInspectorTarget::connect(
    Inspector::FrontendChannel::ConnectionType connectionType)
{
    if (m_channel)
        return;

    Ref frame = m_frame.get();
    m_channel = makeUnique<WebFrameInspectorTargetFrontendChannel>(
        frame, identifier(), connectionType);

    if (RefPtr coreFrame = frame->coreLocalFrame())
        coreFrame->protectedInspectorController()->connectFrontend(*m_channel);
}
```

### Events flowing back to UIProcess

When a frame-level agent emits an event (e.g., `Console.messageAdded`),
`WebFrameInspectorTargetFrontendChannel::sendMessageToFrontend()` sends it over IPC to UIProcess
(`WebProcess/Inspector/WebFrameInspectorTargetFrontendChannel.cpp`):

```cpp
void WebFrameInspectorTargetFrontendChannel::sendMessageToFrontend(
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

`WebFrameProxy`'s destructor calls `destroyInspectorTarget()`. `WebPageInspectorController`
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

## Domain Implementation: Page (In Progress)

`Page` domain adaptation mirrors Network. `Page.getResourceTree` must collect and merge frame
subtrees from each WebContent Process. The merged result presents the frontend with a unified
frame tree even though resources are distributed across processes.

Phases:
- **Phase 1** — `getResourceTree` aggregation across frame targets (in progress)
- **Phase 2** — `searchInResources` across all frame targets
- **Phase 3** — `getResourceContent` with correct process routing
- **Phase 4** — Resource load events aggregated from all processes

---

## Compatibility with Legacy Backends

Web Inspector must continue to work with backends shipping in iOS 13 and later, which have no
Frame targets. The frontend's target iteration logic handles this:

- If a `WebPage` target has one or more `Frame` sub-targets → send per-frame commands to the
  frame targets.
- If a `WebPage` target has no `Frame` sub-targets (older backend) → treat the page target as
  the single frame and send all commands there.

No frontend code needs to know whether it is talking to a single-process backend or a
Site-Isolated backend — the frame target abstraction provides uniform addressing.

---

## Open Questions

1. **`getResponseBody` routing** — Response body data lives in `NetworkResourcesData` in the
   process that loaded the resource. When a frontend requests a body for a cross-origin iframe
   resource, how does the proxy agent locate and fetch it from the correct process? Current
   thinking: embed process identity in the resource identifier, or introduce a UIProcess-side
   cache.

2. **Shared `InjectedScriptManager`** — `FrameInspectorController` currently shares the
   parent page's `InjectedScriptManager`. Is this correct? Injected scripts run in a specific
   frame's JS context; a shared manager may cause leakage of script handles across origins.

3. **DOM domain across process boundaries** — DOM `nodeId` values are process-local integers.
   Under Site Isolation, nodes from different processes may have colliding IDs. A global
   identifier scheme (possibly an extension of `InspectorIdentifierRegistry`) is needed before
   DOM can be migrated to per-frame agents.

---

## Key Source Files

| File | Role |
|------|------|
| `UIProcess/Inspector/WebPageInspectorController.h/.cpp` | Manages all targets for a `WebPageProxy` |
| `UIProcess/Inspector/WebFrameInspectorTargetProxy.h/.cpp` | Frame target proxy in UIProcess |
| `UIProcess/Inspector/WebPageInspectorTargetProxy.h/.cpp` | Page target proxy in UIProcess |
| `UIProcess/Inspector/InspectorTargetProxy.h` | Base class for all target proxies |
| `UIProcess/WebFrameProxy.cpp` | Creates/destroys frame inspector targets on frame lifecycle |
| `WebProcess/Inspector/WebFrameInspectorTarget.h/.cpp` | Frame target in WebContent Process |
| `WebProcess/Inspector/WebFrameInspectorTargetFrontendChannel.cpp` | IPC: WebProcess → UIProcess for events |
| `WebCore/inspector/FrameInspectorController.h/.cpp` | Per-frame agent controller with fallback chain (frame-targeted domains) |
| `WebCore/inspector/PageInspectorController.h/.cpp` | Per-page agent controller (legacy + fallback target) |
| `WebCore/inspector/InstrumentingAgents.h` | Agent registry with fallback to parent controller |
| `WebKit/UIProcess/Inspector/ProxyingNetworkAgent.h/.cpp` | Network agent in UIProcess; receives events from per-WP `NetworkAgentProxy` |
| `WebKit/UIProcess/Inspector/ProxyingPageAgent.h/.cpp` | Page agent in UIProcess; handles `getResourceTree` aggregation |
| `JavaScriptCore/inspector/agents/InspectorTargetAgent.cpp` | Target multiplexing and command routing |
| `JavaScriptCore/inspector/InspectorBackendDispatcher.cpp` | `BackendDispatcher` with fallback dispatcher |
