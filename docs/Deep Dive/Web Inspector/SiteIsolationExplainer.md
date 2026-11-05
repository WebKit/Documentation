# Web Inspector and Site Isolation

_Last updated 2026-10-11._

This page explains how site isolation changes the architecture of Web Inspector: where agents
live, how commands and events reach the frontend across processes, and how frame targets are
created, identified, and destroyed. It also carries the per-domain design, the migration plan,
and the testing notes for the Inspector.

The rules that Web Inspector and WebDriver share — the UI process as authority, per-frame
targets versus process-level aggregation, frame-routed commands with replayed page-wide state,
asynchronous IPC, and the shared UI-process primitives — are defined once in
[Automation and Inspection Under Site Isolation](../SiteIsolation.md#automation-and-inspection-under-site-isolation).
This page assumes that model and covers only what is specific to the Inspector. For a primer on
site isolation itself (remote frames, browsing context groups, provisional navigation), see
[Site Isolation](../SiteIsolation.md). For the WebDriver side, see
[WebDriver and Site Isolation](../WebDriver/SiteIsolation.md).

**Terms used on this page.** A _frame target_ is an inspector target for one frame, served by a
`FrameInspectorController` in the WebContent process that hosts the frame. An _octopus agent_ is
a UI-process agent that fans a request out to the per-frame proxies in every WebContent process
and merges the replies (`ProxyingNetworkAgent`, `ProxyingPageAgent`); the design is described in
[Octopus Domains: Network and Page](#octopus-domains-network-and-page).

**Contents:**
- [Background: Inspector Agents and the Single-Process Assumption](#background-inspector-agents-and-the-single-process-assumption)
- [Background: The Inspector Target System](#background-the-inspector-target-system)
- [Two Modes of Operation](#two-modes-of-operation)
- [Architecture: Three Agent Homes](#architecture-three-agent-homes)
- [The BackendDispatcher Fallback Chain](#the-backenddispatcher-fallback-chain)
- [Frame Target Lifecycle](#frame-target-lifecycle)
- [Identifier Scoping on Frame Targets](#identifier-scoping-on-frame-targets)
- [Coexistence with the Page Target in the Main-Frame Process](#coexistence-with-the-page-target-in-the-main-frame-process)
- [Per-Frame Domains](#per-frame-domains)
- [Octopus Domains: Network and Page](#octopus-domains-network-and-page)
- [UI-Process-Only Domains: Storage, Browser, Target](#ui-process-only-domains-storage-browser-target)
- [The Timeline Family, IndexedDB, and Audit](#the-timeline-family-indexeddb-and-audit)
- [CPUProfiler and Memory](#cpuprofiler-and-memory)
- [Security: Inspector-Only IPC Interfaces](#security-inspector-only-ipc-interfaces)
- [Compatibility with Legacy Backends](#compatibility-with-legacy-backends)
- [Status and Migration Plan](#status-and-migration-plan)
- [Key Risks and Architectural Challenges](#key-risks-and-architectural-challenges)
- [Testing](#testing)
- [Key Source Files](#key-source-files)

---

## Background: Inspector Agents and the Single-Process Assumption

Web Inspector's backend is organized as a collection of _agents_, each responsible for one
protocol domain (`Network`, `Page`, `DOM`, `Debugger`, etc.). Historically, all agents for an
inspected page lived in a single `WebCore::Page` in a single WebContent process.
`PageInspectorController` owns those agents and a `BackendDispatcher` that routes each JSON-RPC
command to the correct agent. Commands from the frontend arrive as JSON strings, are parsed in
the UI process, and are dispatched to the right `PageInspectorController` through the target
routing system.

This design works when all frames share one process. Under site isolation it breaks down: the
frames of one page proxy may be spread across several WebContent processes, each with its own
`Page` and `PageInspectorController`.

---

## Background: The Inspector Target System

To keep a debugging session alive across WebContent process swaps (introduced with process swap
on navigation), the Inspector introduced _inspector targets_. A target is an opaque handle that:

1. Provides a stable `targetId` the frontend can route commands to.
2. Lets the same protocol interfaces be reused across execution-context types (page, worker,
   JSContext, frame).
3. Lets the frontend reason about the capabilities of each backend independently.

`WebPageInspectorController` in the UI process manages the set of active targets. The `Target`
domain, implemented by `InspectorTargetAgent`, exposes target lifecycle events
(`Target.targetCreated`, `Target.targetDestroyed`) to the frontend and routes incoming commands
to the matching target.

Before site isolation, a page was inspected through a `Page` target, with `DedicatedWorker` (and
`ServiceWorker`) targets for workers. Site isolation adds the **`Frame`** target type, which
represents an individual frame, each potentially in its own WebContent process. When site
isolation is enabled, a frame target exists for _every_ frame of the page, including the main
frame. (`InspectorTargetType` in `JavaScriptCore/inspector/InspectorTarget.h` enumerates `Page`,
`Frame`, `DedicatedWorker`, `ServiceWorker`.)

Separately from these target types, the UI-process agents belong to the protocol's `web-page`
debuggable type, which the frontend reaches through its `MultiplexingBackendTarget` (see
[Architecture: Three Agent Homes](#architecture-three-agent-homes)).

---

## Two Modes of Operation

Whether frame targets exist is decided per page proxy by
`WebPageInspectorController::shouldManageFrameTargets()`, which reads the page's site isolation
preference. The frontend gates its site-isolation-only behavior on the presence of any
`WI.FrameTarget`.

**Site isolation off, and WebKitLegacy.** The architecture is essentially the pre-site-isolation
model:

- One `PageInspectorTargetProxy` (type `Page`) manages the one `PageInspectorController`, which
  holds all agents in one WebContent process.
- `didCreateFrame` on `WebPageInspectorController` returns immediately, so no frame targets are
  created.
- Commands are routed through the page target.

**Site isolation on.** Each frame gets its own target:

- Each `WebFrameProxy` gets a `FrameInspectorTargetProxy` (type `Frame`) in the UI process and a
  `WI.FrameTarget` in the frontend. The `PageInspectorTargetProxy` still exists, one per page
  proxy.
- Frames belong to a page and may have subframes, but those relationships are optional data on
  the target; they do not affect target lifetime.
- Each frame target corresponds to a `FrameInspectorController` in the owning WebContent
  process. Commands addressed to a frame target are routed by its `FrameInspectorTargetProxy`
  over IPC to that controller.
- Frame targets exist whenever frames exist, whether or not a frontend is connected, consistent
  with page and worker targets.

---

## Architecture: Three Agent Homes

Under site isolation a page proxy has frames in several WebContent processes, and an Inspector
agent can live in one of three places:

| Home | Owner | Reaches the frontend via | Used by |
|---|---|---|---|
| **Frame target** (per `LocalFrame`, per process) | `WebCore::FrameInspectorController` | the target channel (`Target.sendMessageToTarget` / `dispatchMessageFromTarget`); no domain-specific IPC | Console, Runtime, Debugger, DOM, CSS, DOMStorage, Worker; planned: DOMDebugger, LayerTree, Canvas, Animation, Timeline, ScriptProfiler, Heap, IndexedDB, Audit |
| **Page target** (the main-frame process's `PageInspectorController`) | `WebCore::PageInspectorController` | the page target channel | the legacy single-process path; page-level verbs that only need the main-frame process |
| **Multiplexing (`web-page`) target** (UI process) | `WebKit::WebPageInspectorController` | directly — the frontend's `MultiplexingBackendTarget` | Target, Browser, Storage, `ProxyingNetworkAgent`, `ProxyingPageAgent`; planned: CPUProfiler, Memory |

A domain's home follows from where its data comes from, as stated in the
[shared model](../SiteIsolation.md#automation-and-inspection-under-site-isolation): data produced
by a document or JavaScript VM is reported on the owning frame target; data only the UI process
can assemble is reported on the multiplexing target; data the UI process can read from an
authoritative store (cookies) is served by a UI-process agent with no WebContent involvement.

```
UI process                                  WebContent process A (main frame, same-site frames)
┌──────────────────────────────┐            ┌────────────────────────────────────────────────┐
│ WebPageInspectorController   │            │ PageInspectorController                        │
│  ├ Browser / Storage / Target│            │   page-target agents (single-process path;     │
│  ├ ProxyingNetworkAgent      │◀──IPC─────▶│   several are inert under site isolation)      │
│  ├ ProxyingPageAgent         │            │   FrameNetworkAgentProxy / PageAgentProxy      │
│  │                           │            │     (one per LocalFrame)                       │
│  ├ PageInspectorTargetProxy ─┼────IPC────▶│                                                │
│  ├ FrameInspectorTargetProxy ┼────IPC────▶│ FrameInspectorController (main frame)          │
│  │   (main frame)            │            │   FrameConsole/Runtime/Debugger/DOM/CSS/       │
│  │                           │            │   DOMStorage/Worker agents + FrameDebugger     │
│  ├ FrameInspectorTargetProxy ┼────IPC────▶│ FrameInspectorController (same-site iframe)    │
│  │   (same-site iframe)      │            └────────────────────────────────────────────────┘
│  │                           │            WebContent process B (cross-site iframe)
│  └ FrameInspectorTargetProxy ┼────IPC────▶┌────────────────────────────────────────────────┐
│      (cross-site iframe)     │            │ PageInspectorController (never connected)      │
└──────────────────────────────┘            │   FrameNetworkAgentProxy / PageAgentProxy      │
                                            │ FrameInspectorController (cross-site iframe)   │
                                            │   Frame* agents + FrameDebugger                │
                                            └────────────────────────────────────────────────┘
```

**Routing.** `InspectorTargetAgent` (`JavaScriptCore/inspector/agents/InspectorTargetAgent.cpp`)
is the glue layer: it receives commands from the frontend, looks up the target by `targetId`,
and forwards the message to the matching `InspectorTargetProxy`. For a frame target,
`FrameInspectorTargetProxy::sendMessageToTargetBackend()` sends it over IPC to the
`FrameInspectorTarget` in the hosting WebContent process, which calls
`FrameInspectorController::dispatchMessageFromFrontend()`.

**Protocol `targetTypes`.** The protocol JSON decides which target a domain or command is visible
on. `Browser`, `Storage` and `Target` declare `["web-page"]`; `Page` declares
`["itml", "page", "web-page"]` and `Network` declares `["itml", "page", "service-worker", "web-page"]`,
both with per-command narrowing; the per-frame domains list `frame`. The frontend's
`MultiplexingBackendTarget` initializes only the managers whose domains are declared for
`web-page`, so a UI-process agent becomes discoverable only once its domain is added to the
`web-page` debuggable type in the protocol JSON and the relevant manager's `initializeTarget` is
called from `MultiplexingBackendTarget`.

**Lazy agents.** With site isolation on, a frame's `FrameConsoleAgent` is created eagerly and the
other per-frame agents are created on the first frontend connection to that target
(`connectFrontend` → `createLazyAgents`). A frame that is not being inspected therefore costs
only a `FrameConsoleAgent`.

---

## The BackendDispatcher Fallback Chain

Each `FrameInspectorController` owns the agents for a single frame. At the time of writing seven
domains are served per frame: Console (created eagerly) and Runtime, Debugger, DOM, CSS,
DOMStorage and Worker (created lazily):

```cpp
// FrameInspectorController::createLazyAgents()
lazyInitialize(m_debugger, makeUnique<FrameDebugger>(*frame));
...
m_agents.append(makeUniqueRef<FrameDebuggerAgent>(context));
m_agents.append(makeUniqueRef<FrameDOMAgent>(context));
m_agents.append(makeUniqueRef<FrameDOMStorageAgent>(context));
m_agents.append(makeUniqueRef<FrameRuntimeAgent>(context));
m_agents.append(makeUniqueRef<FrameCSSAgent>(context));
m_agents.append(makeUniqueRef<FrameWorkerAgent>(context));
```

Domains that have not moved to per-frame agents must still reach the page-level
`PageInspectorController`. The frame-level `BackendDispatcher` is therefore constructed with the
page's dispatcher as its fallback (`FrameInspectorController.cpp`):

```cpp
FrameInspectorController::FrameInspectorController(
    LocalFrame& frame, PageInspectorController& parentPageController)
    : ...
    , m_backendDispatcher(BackendDispatcher::create(
        m_frontendRouter.copyRef(),
        &parentPageController.backendDispatcher()))  // <-- fallback
```

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

A command for a domain that is not registered in the frame-level dispatcher is forwarded to the
fallback. This makes migration incremental: a domain can move from `PageInspectorController` to
`FrameInspectorController` independently, and the chain routes correctly at every intermediate
state.

**`InstrumentingAgents` uses the same fallback, and resolution is frame-first.**
`instrumentingAgents(ScriptExecutionContext&)` resolves a document to its _frame's_
`InstrumentingAgents`, which falls back to the page's for any slot the frame has not set. Most
instrumentation hooks therefore reach the frame agent (or the page agent, if the frame has none
enabled) with no per-hook routing code. Hooks that take a `Page&` instead of a document or frame
still resolve page-only, which is why some domains (LayerTree, DOMStorage events) need their hook
signatures changed as part of migration.

A frame agent occupies one of two kinds of `InstrumentingAgents` slot:

| Slot kind | Domains | How the frame agent is found | Effect on the main frame's duplicate page agent |
|---|---|---|---|
| **Dedicated** `*Frame*` slot (`FrameRuntimeAgent`, `FrameDebuggerAgent`, `FrameDOMAgent`, `FrameCSSAgent`, `FrameDOMStorageAgent`) | Runtime, Debugger, DOM, CSS, DOMStorage | Hooks query the frame's `enabled`/`persistent` `Frame*Agent()` explicitly, then (for DOM/CSS) _also_ the page agent | Both agents see the hook; the pair must agree who reports (see [Coexistence](#coexistence-with-the-page-target-in-the-main-frame-process)) |
| **Shared** slot (`WebConsoleAgent`, `persistentWorkerAgent`, `enabledWebDebuggerAgent`) | Console, Worker, and the `WebDebuggerAgent` view of Debugger | The frame agent occupies the same slot name on the frame's `InstrumentingAgents`; frame-first resolution finds it and never falls back | The page agent is shadowed for that frame; page-level code paths opt out |

The shared-slot form is preferred for remaining migrations: it gives frame-first routing for
free and leaves exactly one agent responsible for a document. The dedicated-slot form was needed
where the frame agent does not subclass the page agent (DOM, CSS), so the two coexist on purpose
during the transition.

---

## Frame Target Lifecycle

### Creation

A `WebFrameProxy` is created in the UI process whenever a frame is established. For a subframe,
the creation path calls `WebPageInspectorController::didCreateFrame()`
(`UIProcess/WebFrameProxy.cpp`), which adds a `FrameInspectorTargetProxy`. If a frontend is
connected, this fires `Target.targetCreated` immediately. The target id encodes both the frame
and the hosting process (`FrameInspectorTarget::toTargetID`, of the form
`frame-<frameID>-<processID>`), so a frame that moves to another process gets a new target id.

### Connection

When a frontend connects and enumerates targets, `FrameInspectorTargetProxy::connect()` sends
an IPC message to the WebContent process hosting the frame. There,
`FrameInspectorTarget::connect()` (`WebProcess/Inspector/FrameInspectorTarget.cpp`) creates a
`UIProcessForwardingFrontendChannel` and connects it to the frame's `FrameInspectorController`:

```cpp
void FrameInspectorTarget::connect(
    Inspector::FrontendChannel::ConnectionType connectionType)
{
    if (m_channel)
        return;

    Ref frame = m_frame.get();
    RefPtr page = frame->page();
    ASSERT(page);
    m_channel = makeUnique<UIProcessForwardingFrontendChannel>(
        *page, identifier(), connectionType);

    RefPtr coreFrame = frame->provisionalFrame() ?: frame->coreLocalFrame();
    if (coreFrame) {
        m_inspectedFrame = *coreFrame;
        protect(coreFrame->inspectorController())->connectFrontend(*m_channel);
    }
}
```

### Events flowing back to the UI process

When a frame-level agent emits an event (for example `Console.messageAdded`),
`UIProcessForwardingFrontendChannel::sendMessageToFrontend()`
(`WebProcess/Inspector/UIProcessForwardingFrontendChannel.cpp`) sends it to the UI process:

```cpp
void UIProcessForwardingFrontendChannel::sendMessageToFrontend(const String& message)
{
    Ref { m_page.get() }->send(Messages::WebPageProxy::SendMessageToInspectorFrontend(m_targetId, message));
}
```

The UI process receives it in `WebPageInspectorController::sendMessageToInspectorFrontend()`,
which calls `InspectorTargetAgent::sendMessageFromTargetToFrontend()` to deliver the event,
tagged with the frame's `targetId`, to the frontend.

### Provisional frames

During provisional navigation a frame may briefly exist in two processes (see
[Provisional Navigation](../SiteIsolation.md#provisional-navigation)), and the Inspector mirrors
that with two targets. When a `ProvisionalFrameProxy` is created,
`didCreateProvisionalFrame()` adds a provisional `FrameInspectorTargetProxy` for the destination
process. If the provisional load commits, `didCommitProvisionalFrame()` marks the new target
committed and `Target.didCommitProvisionalTarget` tells the frontend to swap old for new; the old
target is destroyed. If the load does not commit, `willDestroyProvisionalFrame()` removes the
provisional target with no observable change to the frontend. A main-frame swap works the same
way at page level: `didCreateProvisionalPage()` adds a provisional page target and, under site
isolation, a provisional main-frame target.

A cross-origin iframe therefore goes through three steps:

1. The initial frame target exists in the original process (`Target.targetCreated`).
2. A provisional frame target is created in the destination process (`Target.targetCreated`
   again).
3. `Target.didCommitProvisionalTarget` fires to swap them.

Frontend code and tests must not cache a reference to the initial target; they should listen for
`Target.didCommitProvisionalTarget` and update the reference. The layout-test pattern is to
check whether the frame target is still provisional and, if so, await the target manager's
`DidCommitProvisionalTarget` event and take the committed target from the event data
(`LayoutTests/http/tests/site-isolation/inspector/dom/query-commands-frame-target.html:23-26`,
`getDocument-frame-target.html:25-28`):

```js
if (frameTarget.isProvisional) {
    let committedEvent = await WI.targetManager.awaitEvent(WI.TargetManager.Event.DidCommitProvisionalTarget);
    frameTarget = committedEvent.data.target;
}
```

A frame target that is paused in the debugger when its provisional replacement commits is
unwound before the target is destroyed, and when the main frame swaps process, the old process's
proxying-agent instrumentation is torn down with it.

### Destruction

`WebFrameProxy`'s destructor (and `webProcessWillShutDown()`) calls `willDestroyFrame()`.
`WebPageInspectorController` removes the target and fires `Target.targetDestroyed`. Worker
targets that are children of a frame target are torn down with it.

Two frontend-model gaps remain here: a frame nested inside an out-of-process frame is not yet
added to the frontend's frame map ([bug 325086](https://bugs.webkit.org/show_bug.cgi?id=325086)),
and a frame that swaps process on a cross-site navigation does not yet survive as the same
`WI.Frame` ([bug 325088](https://bugs.webkit.org/show_bug.cgi?id=325088)). Both are
`WI.NetworkManager` frame-model issues, not target issues.

---

## Identifier Scoping on Frame Targets

Each `FrameInspectorController` creates its **own** `InjectedScriptManager`, which gives every
frame target an independent namespace for object ids, saved results and execution-context ids.
A frame target is therefore fully independent and tears down cleanly. The consequence is that
every identifier minted by an injected script is **target-scoped**: the wire format does not
change, but the frontend keys on `(target, id)`, and cross-target object references are
impossible by construction.

| Identifier | Minted by | Scope | Frontend key |
|---|---|---|---|
| `Runtime.ExecutionContextId`, `RemoteObjectId`, saved results `$n`, `CallFrameId` | the target's own `InjectedScriptManager` | per target | `(target, id)`; `WI.Frame.addExecutionContext` compares target _and_ id |
| `DOM.NodeId`, `EventListenerId` | `FrameDOMAgent` counters from 1 | per target | `"${target.identifier}:${nodeId}"` via `WI.DOMManager.keyForNodeId`; page-target ids stay raw |
| `CSS.StyleSheetId` (and `CSSStyleId` / `CSSRuleId` through it) | `FrameCSSAgent` counter from 1 | per target | `WI.CSSManager.keyForStyleSheet` |
| `Debugger.ScriptId` | JSC `SourceID` | VM-global (per process) | per target (`WI.DebuggerData`); resolved locations deduplicated across targets |
| `Debugger.BreakpointId` | per agent (`url:line:col`) | per target | breakpoints are set on every Debugger-capable target; resolution per target |
| `Network.FrameId` (in `executionContextCreated`, `frameNavigated`, …) | the UI-process identifier registry: `protocolFrameId(frameID, processIdentifier)` | process-qualified string | matches the `Page` domain's frame ids |
| `Network.RequestId` | `ScopedResourceLoaderIdentifier` (process-qualified) | page-wide, unique across processes | raw |
| `Network.LoaderId` | the document identifier | page-wide | raw |
| `Canvas.CanvasId`, `Animation.AnimationId`, `LayerTree.LayerId` | `IdentifiersFactory::createIdentifier()` (process-prefixed) + per-agent maps | per agent today | n/a (page-only domains until migrated) |

For every per-node command (DOM, CSS, event listeners, accessibility), the frontend's
`WI.DOMNode.owningTarget` picks the backend. `WI.DOMUndoCoordinator` keeps per-edit LIFO target
stacks so that undo reverses edits in the right process.

---

## Coexistence with the Page Target in the Main-Frame Process

Because the main frame has a frame target too, it is served _twice_ in the main-frame process:
by its frame target and by the page target's legacy `Page*` / `Inspector*` agents. Each migrated
domain has an explicit, transitional rule for who reports:

- **Runtime:** `didClearWindowObjectInWorld` routes to the frame's `FrameDebuggerAgent` and
  `FrameRuntimeAgent` and returns, skipping `PageRuntimeAgent`. The page target still announces
  the main frame's realm once on enable; `WI.Frame` lets the frame target's report win.
- **Debugger:** the page target's Debugger domain is registered but inert; under site isolation
  `PageDebugger::attachDebugger()` returns before `Page::setDebugger()`.
  `InspectorDOMDebuggerAgent::pausingDebuggerAgentForFrame` redirects pauses to the frame agent.
- **DOM:** both agents bind the same nodes in two id spaces; the frontend keeps two trees and
  splices frame-target documents into the page tree at the owner element.
- **CSS:** `FrameCSSAgent::documentIsReportedByPageCSSAgent()` (true iff a page
  `InspectorCSSAgent` _exists_ in this process) suppresses the frame agent's
  `styleSheetAdded` / `styleSheetRemoved` / `mediaQueryResultChanged` dispatch for documents the
  page agent covers; bookkeeping still runs so commands work.
- **Worker / Console:** shared slot; the page agent opts out (`PageWorkerAgent` returns early
  under site isolation; `PageDebugger` never attaches).

**End state.** Once the frontend sources DOM and CSS from frame targets
([bug 320938](https://bugs.webkit.org/show_bug.cgi?id=320938),
[bug 323034](https://bugs.webkit.org/show_bug.cgi?id=323034)), the page target stops registering
the per-frame domains under site isolation and these rules disappear; the
[migration plan](#status-and-migration-plan) schedules that as its own phase. A
`WI.targetManager.mainFrameTarget` accessor (today `InspectorTest.mainFrameTarget` in the test
harness) would resolve to the main frame's frame target under site isolation and to the page
target otherwise, so frontend code that assumes a single "main" debugging target can be routed
through it.

---

## Per-Frame Domains

Per-frame domains get a `Frame*Agent` registered by `FrameInspectorController`. Commands route
via the target system; events flow through `FrontendRouter`. No new IPC is needed. Under site
isolation the page target does not serve these domains for any frame once the domain's
migration is complete; until then the
[coexistence rules](#coexistence-with-the-page-target-in-the-main-frame-process) apply.

Each section below follows the same shape: where the data **lives**, how commands and events
**route**, and the **site-isolation caveat** that makes the domain differ from its
single-process behavior. Per-domain progress is tracked in the
[status tables](#status-and-migration-plan), not here.

### Console

**Lives.** Each frame target's `FrameConsoleAgent` owns its own message buffer and repeat-count
state. It is created eagerly per `FrameInspectorController` and occupies the shared
`WebConsoleAgent` slot, so messages from `FrameConsoleClient` reach it through frame-first
resolution.

**Routes.** Messages are reported by the frame target of the frame that produced them, from the
WebContent process hosting that frame. The frontend merges the per-target streams in arrival
order into one log. Logging-channel configuration is sent to every frame target, since channels
are process-local state.

**Caveat.** Clearing the console is a fan-out to every Console-capable target and completes only
after each has acknowledged the echoed `messagesCleared`. Objects and DOM nodes embedded in a
message are remote objects of the reporting target and are resolved there.

### Runtime

**Lives.** Each frame target's `FrameRuntimeAgent` reports the execution contexts of exactly one
frame (its main world and any isolated worlds), using execution-context identifiers minted by
that target's own injected-script manager. Evaluation, `callFunctionOn`, previews and saved
results all live in that manager.

**Routes.** A remote object id is meaningful only on the target that issued it, so the frontend
addresses every object-bearing command to the object's owning target. Frame identifiers in
`executionContextCreated` are the process-qualified frame ids the Page domain uses, which is how
the frontend joins a context to its `WI.Frame`.

**Caveat.** Navigating a frame clears its contexts, and the new document's realm is announced by
the same frame target. Type-profiler and control-flow-profiler toggles are VM-global, i.e. per
process: enabling on one frame target enables for every same-process frame.

### Debugger

**Lives.** Every frame target owns a dedicated JavaScript debugger, `FrameDebugger` (a
`JSC::Debugger` subclass), attached to that frame's global objects in every script world.
Breakpoints, pause state, stepping, call frames and `evaluateOnCallFrame` are all per target.
Scripts are reported by the frame target whose global object parsed them, with script ids that
are unique within the hosting process.

**Routes.** A breakpoint set by URL is sent to every frame target and resolves independently
wherever that URL loads. A pause in one frame suspends that frame's document and script execution
only, and the frontend shows per-target pause state without pausing other frames. Navigating a
frame re-attaches the debugger to the new global object before the frame's Runtime agent
announces the new context.

```
frame A (process A)          frame B (process B)
FrameDebugger(A) ─attach─▶ JSWindowProxy(A, main) ┐
                            JSWindowProxy(A, user)┘   FrameDebugger(B) ─attach─▶ JSWindowProxy(B, …)
      │ didPause → suspend doc A only                      │ didPause → suspend doc B only
      ▼                                                    ▼
FrameDebuggerAgent(A) → Debugger.paused (target A)   FrameDebuggerAgent(B) → Debugger.paused (target B)
```

**Caveat.** The page target does not debug any frame under site isolation. Stepping never
crosses a frame boundary: cross-process frames are separate processes, and same-process siblings
are separate debuggers. Two `FrameDebugger`s in one VM each attach to their own global objects;
`recompileAllJSFunctions()` is VM-wide and over-recompiles siblings, which is harmless.
`detachDebugger()` releases exactly the global objects it attached, so closing the frontend
mid-breakpoint-action unwinds the pause. Symbolic breakpoints on native functions evaluate the
symbol per agent and dispatch to the callee realm's debugger. JavaScript profiling installs one
profiling client across the page debugger and every in-process frame debugger so same-process
frames are not double-counted.

### DOM

**Lives.** Each frame target's `FrameDOMAgent` mirrors exactly one document. Node ids are
allocated per target. Mutation, shadow-root, custom-element, pseudo-element and attribute events
are emitted by the frame target that owns the node.

**Routes.** The frontend addresses every node command to the target that issued the id, keeps
undo history per frame (coordinating multi-frame undo), and aggregates per-target search results.
A frame-owner element with a child frame that has its own frame target is designed to report no
inline `contentDocument` and instead carry the child's frame id, and the frontend will splice the
child frame target's document in at that element, so the Elements tab still shows one tree.
`FrameDOMAgent` does not do this yet: it still inlines the child frame's `contentDocument` and
does not set the frame id for frame targets (FIXMEs in `FrameDOMAgent.cpp`).

**Caveat: overlays.** Highlighting and layout overlays are designed to be drawn by the process
that owns the node: the frame target's DOM agent computes the node's quads and draws them into a
document overlay attached to that frame's local root, so an out-of-process node is highlighted in
its own process without any page-level coordinate conversion. Inspect mode is enabled on every
frame target; the process that receives the hover/click hit-tests its own frames and emits
`DOM.inspect` on the frame target of the hit node. Rulers remain a page-level overlay. Today the
overlay, highlight, inspect-mode, `focus` and `getMediaStats` commands are stubbed on frame
targets (`FrameDOMAgentStubs.cpp`), and drawing in the owning process is the next step. The
per-process overlay primitive already exists for paint rects (`Page.setShowPaintRects`), which is
fanned out from the UI process and drawn per local root.

```
Highlight                                    Inspect mode
frontend ─DOM.highlightNode(nodeId)─▶ frame target X    frontend ─DOM.setInspectModeEnabled(true)─▶ every frame target
  FrameDOMAgent(X): node → quads (frame coords)           pointer moves over frame Y's content (process of Y)
  → per-local-root document overlay in process X            FrameDOMAgent(Y) hit-tests, draws hover highlight locally
  → composited in X's own layer tree                        click → DOM.inspect {nodeId} on frame target Y
```

### CSS

**Lives.** Each frame target's `FrameCSSAgent` serves the style sheets, rules and computed styles
of its own document, with style-sheet ids allocated per target. CSS is simpler per frame than
DOM: one document, one id space, one history.

**Routes.** Node ids resolve through the frame target's DOM agent. Edits are recorded in the
frame's undo history so that a style edit and a DOM edit in the same frame undo together.
`createStyleSheet` always creates in the frame target's document. Layout-flag change
notifications (`nodeLayoutFlagsChanged`, `setLayoutContextTypeChangedMode`) are emitted by the
frame target that owns the node and are not yet delivered for frame-target nodes.

**Caveat.** Commands that are not about any document (the supported property list and system
font family names) are answered identically by any target, and the frontend asks whichever target
it has. During the transition `FrameCSSAgent` also gates its double-report of style-sheet events
(see the coexistence rules).

### DOMDebugger

**Lives.** Each frame target will have a DOMDebugger agent bound to that frame's DOM agent and
debugger agent.

**Routes.** DOM mutation breakpoints are set with the frame target's node ids and fire in the
frame that owns the node; a breakpoint on a frame-owner element does not observe the child
document, which has its own target. Event and URL breakpoints are configuration the frontend
replicates to every frame target (as it already does for worker targets), so a breakpoint pauses
whichever frame hits it. Event-listener breakpoints are set on the frame target that issued the
listener id.

**Caveat.** When a frame navigates, its DOM breakpoints are discarded with its document while
event and URL breakpoints persist. Until the frame agent exists, an **interim bridge** serves the
main-frame process: `PageDOMDebuggerAgent` (page target, main-frame process only) keeps all
breakpoint state, and `InspectorDOMDebuggerAgent::pausingDebuggerAgentForFrame()` returns the
frame's `FrameDebuggerAgent` so the _pause_ lands on the debugger that is actually attached. This
makes DOMDebugger work for every frame in the main-frame process; an out-of-process frame has no
DOMDebugger under the bridge until the frame agent lands.

### LayerTree

**Lives.** Each frame target's LayerTree agent is to report the compositing layers rendered for
its own frame. Each process has its own compositor per local root, so layer data is naturally
frame-local. No frame LayerTree agent exists yet.

**Routes.** Node ids are resolved and reported in that target's DOM id space.
`layerTreeDidChange` is emitted by the frame target whose local root composited; `requestContent`
snapshots are taken in the owning process. The Layers tab asks the selected node's owning target
for its layers.

**Caveat.** The domain depends only on the DOM node-id space, which makes it the simplest
remaining migration.

### DOMStorage

**Lives.** Each frame target's `FrameDOMStorageAgent` serves the local and session storage of its
own frame's origin.

**Routes.** A storage id names an origin and a storage kind, and the frontend sends it to a frame
target whose origin matches. Clearing a storage area is a frame-target command.

**Caveat.** Item-change events are emitted by every frame target whose origin they affect, and
the frontend de-duplicates identical events from same-origin frames. The frontend still
addresses the page target, and the `didDispatchDOMStorageEvent` hook takes a `Page&` and so
reaches only the page agent.

### Worker

**Lives.** Dedicated workers are reported by the frame target of the document that created them,
from the process hosting that document. The worker target is a child of that frame target and is
torn down with it.

**Routes.** `FrameWorkerAgent` occupies the shared `persistentWorkerAgent` slot, and
`PageWorkerAgent` returns early under site isolation.

**Caveat.** Shared and service workers are separate debuggables and unaffected.

### Canvas

**Lives.** Each frame target's Canvas agent tracks the canvases and CSS canvases of its own
document, including WebGL/WebGPU programs and recordings, with canvas ids unique within the
target.

**Routes.** Node references in canvas events and `requestNodes` use the frame target's DOM id
space. Recording and auto-capture settings are per target and the frontend applies them to every
frame target.

**Caveat.** The base agent has a `matchesCurrentContext` seam and a worker subclass, so a frame
subclass is mechanical. No frame Canvas agent exists yet.

### Animation

**Lives.** Each frame target's Animation agent is to list and track the Web Animations, CSS
animations and CSS transitions of its own document, with animation ids unique within the target.

**Routes.** Effect targets are reported in the frame target's DOM id space. Timeline-style
tracking runs per frame target, and the frontend's timeline merges per-target tracking records.

**Caveat.** The agent is currently page-bound with no subclass seam, so a context-generic base
must be extracted first. No frame Animation agent exists yet.

---

## Octopus Domains: Network and Page

Octopus domains use a proxy-aggregator architecture: a per-frame proxy in each WebContent
process captures instrumentation events and forwards them via IPC to a `Proxying*Agent`
aggregator in the UI process. The UI-process agent handles command dispatch, identifier
qualification, and presents a unified view to the frontend through the multiplexing target.
The in-process page agents (`PageNetworkAgent`, `InspectorPageAgent`) keep serving the
single-process and WebKitLegacy path. Under site isolation `PageNetworkAgent` returns early on
enable, and so does `PageWorkerAgent` (see Worker); `InspectorPageAgent` does not.

```
          frontend
             │  Network.* / Page.* commands, events        (one target: "web-page")
             ▼
   UI process  WebPageInspectorController
     ├─ ProxyingNetworkAgent  ──┐  IPC::MessageReceiver per (process, page)
     └─ ProxyingPageAgent     ──┤  enableInstrumentationForProcess()/disable…  ← replay seam
                                │
   ┌────────────────────────────┼──────────────────────────────┐
   │ WebContent A (main frame)  │ WebContent B (cross-site)     │
   │ WebInspectorBackend        │ WebInspectorBackend           │
   │   FrameNetworkAgentProxy ×n│   FrameNetworkAgentProxy ×n   │   one per LocalFrame,
   │   PageAgentProxy ×n        │   PageAgentProxy ×n           │   registered on the frame's
   │   BackendResourceDataStore │   BackendResourceDataStore    │   own InstrumentingAgents
   └────────────────────────────┴──────────────────────────────┘
          ▲ WebInspectorBackend::Enable*/Set*/Get* (UI → WebContent, async replies)
          ▼ Messages::ProxyingNetworkAgent / ProxyingPageAgent (WebContent → UI, events)
```

Three properties of the shape as built:

1. **Proxies are per-frame, not per-process.**
   `WebInspectorBackend::ensureNetworkInstrumentationForFrame` /
   `ensurePageInstrumentationForFrame` create one proxy per `LocalFrame`, registered on that
   frame's own `InstrumentingAgents`.
2. **The replay seam is `enableInstrumentationForProcess`.** It is refcounted per (process, page)
   and is where page-wide configuration is re-sent to processes that join a page later ("late
   joiners"). The two agents reach it at different points in the frame lifecycle; see the table
   below.
3. **Identifiers are process-qualified on the wire.** `Network.RequestId` is a
   `ScopedResourceLoaderIdentifier`; frame protocol ids are qualified by the hosting process;
   `LoaderId` is the document identifier. Two WebContent processes can therefore never collide.

**Where each agent registers.** `WebPageInspectorController` drives the seam from the frame
lifecycle hooks, but only for an agent that is enabled, and the two agents differ around
provisional frames. The page agent must have a receiver in the destination process before the
child frame's first `frameNavigated`, which is sent from that process before the commit reaches
the UI process; the network agent waits for the commit.

| Hook | `ProxyingNetworkAgent` | `ProxyingPageAgent` |
|---|---|---|
| `didCreateFrame` | register the frame's process | register the frame's process |
| `didCreateProvisionalFrame` | nothing | register the destination process |
| `willDestroyProvisionalFrame` (no commit) | nothing | release the destination process |
| `didCommitProvisionalFrame` | release the old process, register the new one | release the old process only; the new one was registered at `didCreateProvisionalFrame` |
| `didCommitProvisionalPage` | release the old main-frame process, register the new one | release the old main-frame process, register the new one |
| `willDestroyFrame` | release the frame's process | release the frame's process |

Command routing for Network and Page never traverses the `FrameInspectorController` fallback
chain. All Network/Page commands arrive at the UI-process agent directly via the multiplexing
target, and the UI-process agent fans out to the appropriate WebContent process when per-frame
data is needed (e.g. `Network.getResponseBody`).

### Network

**Lives.** `ProxyingNetworkAgent` is a UI-process agent addressed through the multiplexing
target. Each WebContent process hosts one `FrameNetworkAgentProxy` per local frame; the proxy
records the load in a per-process `BackendResourceDataStore` and forwards each lifecycle hook to
the UI process as a typed IPC message tagged with a process-qualified `ResourceLoaderIdentifier`.

**Routes.** The UI agent converts identifiers to protocol strings, dispatches the frontend event,
and remembers which process minted each request id so that body, certificate and search commands
are routed back to that process (`WebInspectorBackend::GetResponseBody` and friends, all
asynchronous). Every load in every process is reported once, with a process-qualified id, a frame
id, a loader id, an initiator stack trace and timing metrics. The frontend fetches the aggregated
resource tree once the first frame target appears and merges it without discarding live events.

```
Frontend                UIProcess                    WebProcess(es)
                        ProxyingNetworkAgent
Network.getResponseBody ──►  requestId is a scoped id
(requestId)                  {process P, loader L}
                                                     ┌──────────────────────┐
                        GetResponseBody(L) ─────────►│ BackendResourceData  │
                                                     │ Store (process P)    │
                        ◄── (content, base64Encoded) ─│ entry for L          │
                                                     └──────────────────────┘
respond to frontend ◄──
```

**Page-wide configuration.** `setExtraHTTPHeaders` and `setResourceCachingDisabled` are latched
on the UI agent, fanned out to every current process, and replayed to any process that joins
later through `enableInstrumentationForProcess`. Network conditions (`setEmulatedConditions`) are
applied once at the network session, which all of the page's processes share.

**Interception.** Interception under site isolation is designed to be built on a
consumer-independent primitive rather than inside the Network agent pair: a `WebPageProxy`-owned
**interception authority** in the UI process and a **sink** in each WebContent process, described
in
[Automation and Inspection Under Site Isolation](../SiteIsolation.md#automation-and-inspection-under-site-isolation).
The design:

- **Authority.** The union of every consumer's URL patterns, with owner provenance, and a
  per-request handle table with one exclusive resolver.
- **Sink.** In each WebContent process, the sink pauses a matching load at the existing
  request-stage (`WebLoaderStrategy::scheduleLoad`) and response-stage
  (`WebResourceInterceptController`) points and reports a handle up.
- **Inspector's part.** `FrameNetworkAgentProxy` implements the interception hooks
  ([bug 324478](https://bugs.webkit.org/show_bug.cgi?id=324478)); today they decline every load,
  and they are to become the Inspector's entry into the sink. The `ProxyingNetworkAgent`
  interception verbs become configuration writes and
  handle resolutions on the authority. Resolutions travel down as IPC; the paused continuation never
  leaves the WebContent process.
- **Release matrix.** Process crash purges the handles; frontend disconnect continues the request
  or response unchanged; an optional per-handle timeout continues with a diagnostic. Every handle
  gets a terminal resolution.
- **Late joiners and shared consumers.** Configuration is replayed to late joiners from the page
  proxy at process join, not from the Inspector controller, so a consumer with no Inspector
  attached (WebDriver BiDi `network.*`) uses the same path. When an Inspector frontend and a
  WebDriver BiDi session both match one request, the Inspector resolves it.
- **No frontend change** is needed: `NetworkManager` already replays saved Local Overrides via
  `addInterception` on every target setup.

```
frontend ──Network.addInterception──► ProxyingNetworkAgent ──► WebPageProxy interception authority
                                                                  │ SetNetworkInterception(config)  (fan-out + late-joiner replay)
                                                                  ▼
                                          WebContent sink (per process): pause at scheduleLoad / didReceiveResponse
                                                                  │ NetworkInterceptionDidPause(scopedId, frame, phase, snapshot)
frontend ◄──Network.requestIntercepted── ProxyingNetworkAgent ◄──┘
frontend ──Network.interceptWithRequest─► authority.resolve(handle, Continue{edits}) ──► sink resumes
```

The authority and sink are designed but not implemented. Until they land, no load is paused under
site isolation: the configuration verbs (`setInterceptionEnabled`, `addInterception`,
`removeInterception`) accept and discard their arguments in `ProxyingNetworkAgent`, and the
resolution verbs (`interceptContinue`, `interceptWithRequest`, `interceptWithResponse`,
`interceptRequestWithResponse`, `interceptRequestWithError`) report the same missing-intercept
errors as the single-process agent.

**WebSocket.** WebSocket instrumentation is to join the same per-frame contract: the `webSocket*`
hooks become part of `NetworkAgentInstrumentation`, forwarded over IPC under the same scoped
identifier. `resolveWebSocket` returns a `Runtime.RemoteObject`, which is only meaningful on the
target that owns the JavaScript object, so it is routed to the owning process and its reply is
scoped to that frame's target. Until then `resolveWebSocket` returns "Not yet implemented" and no
WebSocket activity is visible under site isolation.

### Page

Page stays a UI-process domain through the multiplexing target for everything page-wide; the
page target keeps serving the single-process path. Commands fall into three sub-shapes:

1. **Aggregation commands** (`getResourceTree`, `getResourceContent`, `searchInResource`,
   `searchInResources`): the UI agent uses the shared UI-side frame-tree walker over the
   authoritative `WebFrameProxy` tree ([shared primitives](../SiteIsolation.md#automation-and-inspection-under-site-isolation))
   and asks each hosting process only for its own frames, then merges. Because the skeleton
   comes from the UI process, remote frames are never stubs in the result and the walk does not
   race a frame that is mid-swap.
2. **Configuration commands** (`overrideUserAgent`, `overrideSetting`,
   `overrideUserPreference`, `setEmulatedMedia`, `setScreenSizeOverride`, `setBootstrapScript`,
   `setShowRulers`, `setShowPaintRects`): these are designed to write a shared emulation /
   page-configuration store on the page proxy, which latches, fans out and replays to late
   joiners exactly as `setShowPaintRects` does today. Only `setShowPaintRects` does so now; the
   others are no-ops in `ProxyingPageAgent`. The Inspector's `ProxyingPageAgent` is to be one
   writer among several and the last writer wins at the sink; the store lives on the page proxy,
   not on the Inspector agent, so an automation session with no Inspector attached can use the
   same path. The bootstrap script is pre-seeded into each process at join time so
   `didClearWindowObjectInWorld` never races the UI process.
3. **Rendering commands** (`snapshotNode`, `snapshotRect`, `archive`): a WebContent process can
   only paint the frames it hosts, so a page-level snapshot that must include cross-site frames
   is designed as a composited view snapshot taken in the UI process and clipped there.
   `snapshotNode` resolves the node in the frame target that owns the node id, has that process
   compute the node's rectangle in its local root's coordinates, converts to main-frame
   coordinates in the UI process, and clips the view snapshot. `archive` is per-process by
   nature; a first version archives the main-frame process's tree with remote frames as
   references. All three currently return "Not yet implemented under Site Isolation".

```
Page.getResourceTree (site isolation on)

frontend ──► ProxyingPageAgent (UI)
               walk WebFrameProxy tree: main frame → childFrames() … (authoritative skeleton)
               for each hosting process P: GetFrameResourceData(frames hosted by P) ──► PageAgentProxy (P)
               ◄── {frameId, url, mimeType, securityOrigin, resources[]} per frame
               merge into Protocol::Page::FrameResourceTree (remote frames filled from their owner)
frontend ◄── unified tree
```

**Events and ownership.** `reload` is to be owned by the UI process (navigation is a
`WebPageProxy` operation), with `ignoreCache` mapped to the reload options and
`revalidateAllResources` mapped to the caching-disabled latch for the duration of the load; the
current `ProxyingPageAgent::reload` is a no-op. `domContentEventFired` and
`loadEventFired` are main-frame events emitted once from the main-frame process; user
preference, appearance and accessibility changes are system facts the UI process observes
directly and emits itself. The cookie verbs (`getCookies`, `setCookie`, `deleteCookie`) are
superseded by the Storage domain under site isolation.

---

## UI-Process-Only Domains: Storage, Browser, Target

**Storage** is a UI-process-only domain (`InspectorStorageAgent` in
`UIProcess/Inspector/Agents/`, `targetTypes ["web-page"]`) created unconditionally alongside
Browser. It reads and writes the authoritative cookie store through `API::HTTPCookieStore`
(`setCookie` / `deleteCookies` in `InspectorStorageAgent.cpp`), so
cookies set by cross-origin frames are visible with no per-process fan-out. Partitioned cookies
are labelled with `partitionKey`; `deleteCookies` requires a filter. Cookie filtering is shared
with WebDriver BiDi's storage module through the `InspectorCookieStoreHelpers` files
(`UIProcess/Inspector/InspectorCookieStoreHelpers.h` / `.cpp`). The frontend's
`WI.StorageManager` enables it from `MultiplexingBackendTarget.initialize`, and
`WI.CookieStorageObject` routes to `WI.backendTarget.StorageAgent` when a frame target exists,
else to the legacy `Page.*` cookie verbs. This is the third agent shape, _UI-process-only over an
authoritative store_, and the model for any future storage inspection whose data the network
process already owns. A per-URL + partition lens is a follow-up
([bug 292393](https://bugs.webkit.org/show_bug.cgi?id=292393)).

**Browser** lives entirely in `WebPageInspectorController` and requires no migration.

**Target** is the multiplexing mechanism itself, described above.

---

## The Timeline Family, IndexedDB, and Audit

These domains were originally queued for the octopus pattern. On closer inspection they are
JavaScript-VM- or document-scoped, and the frontend already treats them as multi-target for
workers, so they follow the per-frame-target pattern. The octopus pattern stays reserved for the
two domains whose authoritative state genuinely lives in the UI process (Network's
request-to-process map, Page's frame tree) and for the two whose data is per-process numbers that
must be summed (CPUProfiler, Memory).

### Timeline, ScriptProfiler, Heap

**Lives.** Timeline, ScriptProfiler and Heap become frame-target domains: `frame` is added to
their `targetTypes`, and `FrameInspectorController` creates a `FrameTimelineAgent`,
`FrameScriptProfilerAgent` and `FrameHeapAgent` per frame. (Today `FrameInspectorController`
creates only the Debugger, DOM, DOMStorage, Runtime, CSS and Worker agents, in addition to
Console.) Each is a thin per-target front end over a **per-process engine**
owned by that process's `PageInspectorController`, which exists in every process whether or not
a page target is connected. The engines are the existing `PageTimelineAgent`,
`InspectorScriptProfilerAgent` and `PageHeapAgent` logic, hoisted so they can run without a
page-target frontend; the page target keeps using them directly on the single-process path.

**Caveat: several frame targets share one process.** This is the one thing a per-frame-target
design must handle that workers never had. The engine resources are per process: one JavaScript
VM and sampling profiler, one run loop (one rendering-frame observer), one heap. Within one
process the first frame agent to start a recording is to start the engine, later starts join it
(refcounted), and the engine stops when the last stops. If the frame that started it goes away
mid-recording the engine stays alive and re-points its process-level event sink to another
started frame agent in that process.

**Routes.**

- A record produced by an instrumentation hook that names a frame (layout, paint, style
  recalculation, timers, script evaluation, animation-frame and observer callbacks, console
  profiles) is emitted on **that frame's target**: the hook already resolves agents through the
  frame's `InstrumentingAgents`, so attribution is free.
- Process-level events (rendering-frame envelope records, sampling-profiler samples,
  garbage-collection events, heap snapshots, Screenshot-instrument records) are emitted on the
  **lead frame target** of the process, the one holding the engine.
- `trackingStart` / `trackingComplete` and `recordingStarted` / `recordingStopped` are emitted on
  every started frame target so the frontend's per-target bookkeeping stays balanced.

No new identifier spaces are needed. `Debugger.ScriptId` values are reported per frame target by
the frame's debugger agent; `heapObjectId` values are scoped to the frame target that returned
the snapshot (`Heap.getPreview` / `getRemoteObject` go to that same target). The UI process does
not merge heap snapshots; a page with N processes yields N snapshots, as a page with a worker
already does. `Timeline.setAutoCaptureEnabled` and `autoCaptureStarted` remain page-level: the
main-frame process observes `mainFrameStartedLoading`, emits `autoCaptureStarted`, and the
frontend starts the recording on every target.

```
          frontend  TimelineManager (per-target streams, one recording)
            ▲  Timeline/ScriptProfiler/Heap events on frame targets   ▲
   ─────────┼───────────────────────────────────────────────────────────┼──────────
   WebContent A (main frame + same-site frames)        WebContent B (cross-site frame)
   PageInspectorController                             PageInspectorController (no page target)
     ├─ page target agents (single-process path)         └─ per-process ENGINE:
     ├─ per-process ENGINE: PageTimelineAgent,               timeline records, run-loop observer,
     │     ScriptProfiler client, Heap                       sampling profiler, heap
     │       ▲ refcounted start/stop; lead = first starter     ▲
     ├─ FrameTimelineAgent(f1) ─┤  frame-scoped records on f1   ├─ FrameTimelineAgent(f3)  (lead)
     ├─ FrameTimelineAgent(f2) ─┘  process-level on the lead    └─ FrameScriptProfilerAgent / FrameHeapAgent
```

Inside the main-frame process, one profiling client per page is installed on the page debugger
and every in-process frame debugger, and is inherited by frame debuggers created mid-recording.
Frames in other processes record nothing until the frame-target agents exist.

### IndexedDB

**Lives.** `FrameInspectorController` will create a `FrameIndexedDBAgent` that answers for its
own frame's origin only (`securityOrigin` must equal the frame's document origin) using that
document's `IDBFactory`. The frame-tree origin lookup that skips `RemoteFrame`s
(`findFrameWithSecurityOrigin`, still used by `InspectorIndexedDBAgent`) is then no longer
needed.

**Routes.** The `Runtime.RemoteObject`s in `DataEntry` are minted by that frame target's injected
script manager, so `Runtime.getProperties` on them routes correctly with no new id scheme. The
frontend's `IndexedDBManager` sends each frame's requests to that frame's committed target.

**Caveat.** The page-target `InspectorIndexedDBAgent` stays for the single-process path. A
UI-process listing of database names for an origin with no live frame (the Storage-domain shape,
read from the network process) is an optional extension.

### Audit

**Lives.** Audit is a pure command/response domain over an execution context, so it becomes a
frame-target domain: a `FrameAuditAgent` reuses the page agent's logic over the frame's document.

**Routes.** `contextId` is validated against that frame target's contexts. The frontend runs the
suite on the main frame's target (the page target on legacy backends, the main frame's frame
target under site isolation) and can offer "run in frame" for other frame targets.

**Caveat.** The audit helper objects and console muting are per process by construction. Results
carry their target with the `RemoteObject`.

---

## CPUProfiler and Memory

Both domains are `ENABLE(RESOURCE_USAGE)`-conditional. Each registers as an observer of the
process-wide `ResourceUsageThread` and emits periodic `trackingUpdate` samples. The numbers are
per process and the user's question is "how much does this page cost", so the correct answer
under site isolation is a **sum over the page's processes**, and a system-wide memory-pressure
event should be reported once, not once per process. Nothing here is frame-scoped, and nothing
the frontend wants can be produced by any single WebContent process: the octopus case, and a
small one.

**Lives.** `CPUProfiler` and `Memory` become UI-process agents on the multiplexing target
(`ProxyingCPUProfilerAgent`, `ProxyingMemoryAgent`), reusing the Network/Page enable-and-replay
seam. Each process samples its own `ResourceUsageThread` through a small
`ResourceUsageAgentProxy` shared by both domains. Neither proxying agent exists yet.

**Routes.** `startTracking` sends a start message to every current process (and to late joiners
while tracking is active); each process sends `{timestamp, usage, threads[]}` /
`{timestamp, categories[]}` up.

**Caveat: merging.** The UI agent aligns samples by timestamp into one page-level series: CPU
usage and per-category memory are summed, thread entries are concatenated with the process
identity in the thread name, and `memoryPressure` is de-duplicated per event. `trackingStart` is
emitted when the first process reports, `trackingComplete` after the last. The Timelines tab's
single CPU lane and Memory lane are preserved; a per-process breakdown can be a later protocol
addition.

---

## Security: Inspector-Only IPC Interfaces

The proxying agent architecture introduces new IPC channels between the UI process and
WebContent processes. These channels do **not** expand the attack surface: they are only active
when Web Inspector is open and connected, and are scoped to the inspected page.

### Dynamic IPC Receiver Registration

`ProxyingPageAgent` and `ProxyingNetworkAgent` in the UI process register and deregister
themselves as IPC message receivers per (process, page), through `enableInstrumentationForProcess` /
`disableInstrumentationForProcess`. Registration does not wait for the frontend to enable the
domain: when the first frontend connects, `WebPageInspectorController::connectFrontend` calls
each agent's `didCreateFrontendAndBackend`, which calls `enable()` (a no-op unless the site
isolation preference is on). The receivers then stay registered until `disable()`, which runs
from `Network.disable` / `Page.disable` or when the frontend is torn down
(`willDestroyFrontendAndBackend`). The registration is refcounted per (WebContent process, page
ID) so that a process hosting several frames of the page is registered once, and it is where
latched configuration is replayed to a process that joins the page later.

The intended contract for that count is one per frame of the page the process hosts, including a
provisional frame loading there, plus one for a process that hosts the page but no frame yet.
The UI-process receiver is added and `WebInspectorBackend::Enable*Instrumentation` is sent only
when a process's count goes from 0 to 1; `Disable*Instrumentation` is sent and the receiver
removed only when it drops from 1 to 0. The frame lifecycle hooks
([table above](#octopus-domains-network-and-page)) already count per frame. `enable()` does not
yet: on main, both agents' `enable()` add one count per process, so a process whose frames all
existed before the frontend connected is released as soon as the first of them goes away, while
its other frames still need instrumentation. A change that makes `ProxyingPageAgent::enable()`
count per frame is under review ([bug 327026](https://bugs.webkit.org/show_bug.cgi?id=327026));
`ProxyingNetworkAgent::enable()` still counts per process and needs the same change.

- **Enable (frontend connects):** add a count for each frame's hosting process (and for each
  process with no frame); on a process's first count, register the UI-process IPC receiver,
  then send `WebInspectorBackend::Enable*Instrumentation` to that process.
- **Disable (domain disabled or Inspector closes):** `disable()` tears down every registration
  regardless of its count: send `WebInspectorBackend::Disable*Instrumentation` to each
  registered process, then remove the UI-process IPC receivers. A single frame going away drops
  only one count.

When Inspector is closed, no handler is registered for these messages. The IPC infrastructure
rejects any message targeting a non-existent receiver.

### Conditional WebContent Instrumentation

On the WebContent side, `WebInspectorBackend` creates one `PageAgentProxy` /
`FrameNetworkAgentProxy` per local frame only when instrumentation is enabled for that frame's
page, and registers it on the frame's `InstrumentingAgents`. When disabled, instrumentation
hooks in WebCore (e.g., `willSendRequest`, `frameNavigated`) find no registered proxy in the
`InstrumentingAgents` registry. The hooks become no-ops: no data is collected and no IPC
messages are sent.

### Ordering Guarantees

The enable/disable sequences are ordered to prevent race conditions:

1. **Enable:** Register the UI-process IPC receiver _first_, then tell the WebContent process to
   start sending. The receiver is ready before any messages arrive.
2. **Disable:** Tell the WebContent process to stop sending _first_, then remove the UI-process
   IPC receiver. No in-flight messages arrive at a deregistered receiver.

### Per-Page Scoping

IPC receivers are registered with the inspected page's identifier as the destination. Only
WebContent processes hosting the inspected page can address these handlers; processes for other
pages cannot send to them. The proxying agents' `.messages.in` receivers carry the
`ExceptionForEnabledBy` attribute, which exempts them from the `EnabledBy` feature-flag gating the
message generator otherwise applies; it is not an additional safeguard. Request/reply messages
from the UI process to a WebContent process (`GetFrameResourceData`, `GetResponseBody`,
`SearchInRequest`, `SearchInFrameResource`, `SearchInFramesAndRequests`, …) are all asynchronous;
no synchronous IPC exists in either direction.

### Summary

| Condition | UI-process receiver | WebContent instrumentation | IPC traffic |
|-----------|---------------------|----------------------------|-------------|
| Inspector closed | Not registered | Not registered | None |
| Inspector open (frontend connected, site isolation on) | Registered (inspected page only, per hosting process) | Registered with each frame's `InstrumentingAgents` | Active |
| Network / Page domain disabled, or frontend disconnected | Not registered | Not registered | None |

These IPC channels exist only for the duration of an active Inspector session, are scoped
to a single inspected page, and are torn down completely when Inspector disconnects. The
network interception authority and emulation override store described in
[Automation and Inspection Under Site Isolation](../SiteIsolation.md#automation-and-inspection-under-site-isolation)
are designed as page-proxy state rather than Inspector state, because they are also written by
WebDriver; their WebContent-side sinks are to be reached through `WebPage` messages and are
equally inert when no consumer has configured them.

---

## Compatibility with Legacy Backends

Web Inspector must continue to work with backends shipping in iOS 13 and later, which have no
frame targets. The frontend's target iteration logic handles this:

- If a `WebPage` target has associated `Frame` targets, send per-frame commands to the frame
  targets.
- If a `WebPage` target has no associated `Frame` targets (older backend), treat the page target
  as the single frame and send all commands there.

No frontend code needs to know whether it is talking to a single-process backend or a
site-isolated backend: the frame target abstraction provides uniform addressing.

---

## Status and Migration Plan

Inspector protocol domains must be adapted to work under site isolation. Each domain follows
one of three patterns (per-frame, octopus, or UI-process-only), according to where its data comes
from. The tables below cover the 23 domains this page migrates, each listed exactly once (16
per-frame, 4 octopus, 3 UI-process-only); design rationale lives in the per-domain sections above, and the
[phase plan](#phase-plan) orders the remaining work. Cross-cutting rules and shared primitives
that these domains rely on are defined in
[Automation and Inspection Under Site Isolation](../SiteIsolation.md#automation-and-inspection-under-site-isolation).

### Per-Frame Domains

| Domain | Status | Notes |
|--------|--------|-------|
| **Console** | Done | `FrameConsoleAgent`; reference implementation for all per-frame agents |
| **Runtime** | Done | `FrameRuntimeAgent`; per-target injected-script manager; frontend joins contexts to `WI.Frame` |
| **Debugger** | Done | Dedicated `FrameDebugger` per frame target; no cross-frame stepping |
| **Worker** | Done | `FrameWorkerAgent`; worker targets are children of the frame target |
| **DOM** | In progress | Tree, mutation, editing, undo, search, listeners, accessibility done; highlight, overlays, inspect mode, `focus` and `getMediaStats` planned on a per-process overlay |
| **CSS** | In progress | Node and stylesheet commands done; layout-flag notifications and the two global commands remain |
| **DOMStorage** | In progress | Backend commands done; frontend routing and per-frame item-change events remain |
| **DOMDebugger** | Planned | Interim pause bridge landed; `FrameDOMDebuggerAgent` with replicated event/URL breakpoints planned |
| **LayerTree** | Planned | Simplest migration; thin agent over the local root's compositor |
| **Canvas** | Planned | Frame subclass over the existing `matchesCurrentContext` seam |
| **Animation** | Planned | Needs a context-generic base extracted first; Timeline coupling |
| **Timeline** | Planned | Per-frame target over a per-process engine with refcounted start/stop and lead election |
| **ScriptProfiler** | Planned | Per-frame target; samples on the lead target |
| **Heap** | Planned | Per-frame target; one snapshot per process, no merge |
| **IndexedDB** | Planned | Per-frame target bound to the frame's origin |
| **Audit** | Planned | Per-frame target over the frame's execution context |

### Octopus Domains

| Domain | Status | Notes |
|--------|--------|-------|
| **Network** | In progress | Observation, bodies, certificates, `loadResource`, header/caching/conditions latches, initiator and metrics done; interception authority and sink, WebSocket, `setClearResourceDataOnNavigate` remain |
| **Page** | In progress | Tree, content, search, live frame events, paint rects done; configuration commands (shared sink with WebDriver), rendering commands (shared UI-side snapshot), `reload`, rulers, archive remain |
| **CPUProfiler** | Planned | `ENABLE(RESOURCE_USAGE)` only; sum over processes in the UI process |
| **Memory** | Planned | `ENABLE(RESOURCE_USAGE)` only; sum over processes; memory-pressure de-duplicated |

### UI-Process-Only Domains

| Domain | Status | Notes |
|--------|--------|-------|
| **Browser** | Done | Lives entirely in `WebPageInspectorController`; no migration |
| **Storage** | Done | Over `API::HTTPCookieStore`; the partition lens is a follow-up |
| **Target** | Done | Two frontend frame-model gaps remain (frames nested in a remote frame; frame identity across a swap) |

### Phase Plan

Phases group the "Planned" and "In progress" rows above; the domain tables carry the per-domain
detail.

| Phase | Domains and work | State |
|---|---|---|
| **1. Foundation** | Target, Console, Runtime, Worker, Storage cookies; Network observation, bodies and commands; Page tree, resources, search, paint rects | Done |
| **2. Core frame inspection** | Debugger, DOM (tree, mutation, edit, undo), CSS (sheets, rules, edits), DOMStorage backend | Done, except DOM overlays and inspect mode and CSS layout flags |
| **3. Rendering surfaces and page configuration** | DOM highlight overlay, then grid/flex overlays, then inspect mode; CSS layout-flag notifications; Page configuration commands on the page-proxy store shared with WebDriver BiDi emulation; `reload` | Next |
| **4. Network interception** | Interception authority and sink (shared with WebDriver BiDi `network.*`); request stage; response stage; release matrix | In progress; hooks landed |
| **5. Dependent frame agents** | DOMDebugger (frame agent and frontend replication), LayerTree, DOMStorage (frontend and events) | Unblocked |
| **6. Timeline family** | ScriptProfiler, then Timeline, then Heap; per-process engine with lead election; frontend per-target instruments | After phase 2 |
| **7. CPU and memory octopus** | `ProxyingCPUProfilerAgent`, `ProxyingMemoryAgent`, shared `ResourceUsageAgentProxy` | Any time after phase 1; Timeline-driven toggles after phase 6 |
| **8. Context-scoped domains** | IndexedDB, Audit, Canvas, Animation (with Timeline coupling) | After the DOM node-id cleanup in phase 5 |
| **9. Rendering** | Page snapshots, rulers, archive; Timeline Screenshot instrument; UI-side view-snapshot primitive shared with WebDriver | After the snapshot primitive |
| **10. Residual Network** | WebSocket, `setClearResourceDataOnNavigate` | Any time |
| **11. Retire page-target duplicates** | Frontend `mainFrameTarget`; stop creating the per-frame domains' page agents in `PageInspectorController` under site isolation; delete the coexistence gates and stale FIXMEs | After phases 3-8, per domain as each reaches parity |

Suggested order within phases 3-8, each item buildable alone: DOM frame-id and no-inlining
cleanup, CSS layout flags, DOM highlight, DOMDebugger, LayerTree, DOMStorage, DOM grid/flex
overlays, Canvas, DOM inspect mode, Animation, retire the main frame's second DOM tree, then
phase 11.

---

## Key Risks and Architectural Challenges

### Resolved

- **Debugger: single debugger, multiple agents.** Each frame target has a dedicated
  `FrameDebugger`, and the page debugger never attaches under site isolation. Stepping does not
  cross frame boundaries by design.
- **DOM: cross-frame traversal at process boundaries.** `FrameDOMAgent` mirrors one document,
  frame-owner elements carry the child's frame id instead of an inline `contentDocument`, and the
  frontend splices child documents at the owner element. `DOM.performSearch` is per frame;
  cross-frame `DOM.moveTo` is invalid.
- **CSS: coupling to the DOM agent.** Co-locating both agents per frame gives one document, one
  id namespace and one undo history.
- **Network: `RequestId` collision across processes.** `Network.RequestId` is a process-qualified
  `ScopedResourceLoaderIdentifier`, and the UI agent routes body, certificate and search commands
  to the minting process.

### Open

- **Timeline family: per-process engines behind per-frame targets.** Several frame targets can
  share one process; the refcounted start/stop with lead election is the only novel piece. A
  sampled stack frame from one VM may reference scripts reported by a _sibling_ frame target in
  the same process, so the frontend resolves script ids first against the reporting target, then
  against sibling targets of the same page.
- **Page configuration shared with WebDriver.** The override store lives on the page proxy and is
  written by both the Inspector and WebDriver BiDi; the last writer wins at the sink. The two
  clients are not used on one page at once in practice.
- **Network interception shared with WebDriver.** One authority with owner provenance and one
  exclusive resolver per paused request; the Inspector wins when both match. The release matrix
  must land before any fulfil or fail verb so that a paused synthetic response can never leak.
- **DOM overlays under a remote ancestor.** A per-process overlay drawn in the node's own process
  needs no cross-process geometry, but a local subframe nested under a remote ancestor is drawn
  frame-locally, and rulers remain page-level.
- **Same-process debugger nesting.** Same-site frames share a process, so two `FrameDebugger`s on
  one VM can pause at the same time and nest run loops; the frontend must keep an active call
  frame when one target resumes while another is paused.

---

## Testing

Web Inspector layout tests live in `LayoutTests/inspector/` and `LayoutTests/http/tests/inspector/`.
Site-isolation-specific inspector tests live under
`LayoutTests/http/tests/site-isolation/inspector/`, one directory per domain, and use
cross-origin frames served by the HTTP test infrastructure.

`run-webkit-tests --site-isolation` runs each test with and without site isolation and compares
the results, using the site isolation expectations:

    Tools/Scripts/run-webkit-tests --site-isolation LayoutTests/inspector/
    Tools/Scripts/run-webkit-tests --site-isolation LayoutTests/http/tests/inspector/
    Tools/Scripts/run-webkit-tests --site-isolation LayoutTests/http/tests/site-isolation/inspector/

Expectations for the site isolation flavor live in
`LayoutTests/platform/mac-site-isolation/TestExpectations`.

### Coverage

Dedicated suites exist under `http/tests/site-isolation/inspector/` for `console`, `runtime`,
`debugger`, `dom`, `css`, `worker`, `target`, `page`, `network` and `storage`. The domains still
to migrate (DOMDebugger, LayerTree, DOMStorage events, Canvas, Animation, Timeline,
ScriptProfiler, Heap, IndexedDB, Audit, CPUProfiler, Memory) have no cross-origin tests yet;
each migration should add at least one.

Each migrated domain should include:

1. **Same-origin frame tests.** Behavior is unchanged from before site isolation.
2. **Cross-origin frame tests.** Data is attributed to the correct process.
3. **Provisional navigation tests.** Targets are torn down and created cleanly during a
   cross-origin navigation.
4. **Legacy compatibility.** The domain still works with site isolation disabled.
5. **Same-process siblings.** Two same-site frames under a cross-site parent do not
   double-report (relevant to every domain whose engine is per process).

### Harness Conventions

Every new per-frame test should follow these conventions:

- For the provisional commit race, wait for the commit and take the committed target, as in
  `query-commands-frame-target.html`: `if (frameTarget.isProvisional) { let committedEvent = await WI.targetManager.awaitEvent(WI.TargetManager.Event.DidCommitProvisionalTarget); frameTarget = committedEvent.data.target; }`
- `InspectorTest.mainFrameTarget` finds the frame target whose execution context is the main
  frame, and otherwise falls back to `WI.mainTarget`.
- Scoped node and stylesheet keys through `WI.domManager` / `WI.cssManager`.
- Frontend-style (not protocol-style) tests for any domain whose node ids come from a different
  target than `DOM.getDocument` answers. The LayerTree and Animation protocol tests were
  rewritten as frontend tests for this reason, so they survive frame targets.

### Cross-Origin Test Examples

Cross-origin inspector tests load iframes from a different hostname (`localhost:8000`), so that
site isolation places them in separate WebContent processes.

**Console** (`LayoutTests/http/tests/site-isolation/inspector/console/message-from-iframe.html`)
checks that console messages from same-origin, cross-origin and nested (grandchild) iframes all
arrive. The page appends iframes dynamically, and the test listens for
`WI.ConsoleManager.Event.MessageAdded`:

```js
function addIFrame(url) {
    const iframe = document.createElement("iframe");
    iframe.src = url;
    document.body.appendChild(iframe);
}

// Same-origin iframe:
addIFrame("resources/console-messages.html");
// Cross-origin iframe:
addIFrame("http://localhost:8000/site-isolation/inspector/console/resources/console-messages.html");
// Nested: a same-origin grandchild inside a cross-origin parent:
addIFrame("http://localhost:8000/site-isolation/inspector/console/resources/embedded-cross-origin.html");
```

**Runtime** (`LayoutTests/http/tests/site-isolation/inspector/runtime/evaluate-in-cross-origin-iframe.html`)
checks that `Runtime.evaluate` works in a cross-origin frame's execution context. The page
contains a static iframe pointing at
`http://localhost:8000/site-isolation/inspector/runtime/resources/frame-with-passphrase.html`.
The test finds that iframe's `WI.FrameTarget`, evaluates `window.passphrase` in it, evaluates the
same expression on the page target, and verifies that the two values differ (a second case checks
that `Runtime.callFunctionOn` works with objects created in the cross-origin frame's context):

```js
let passphraseValue = await waitForExpressionInTarget(crossOriginTarget, "window.passphrase");
// "cross-origin-secret" in the cross-origin frame.
let pageResponse = await WI.pageTarget.RuntimeAgent.evaluate.invoke({ expression: "window.passphrase", objectGroup: "test", returnByValue: true });
// "main-page-value" in the main page.
```

---

## Key Source Files

Paths are relative to `Source/`.

| File | Role |
|------|------|
| `WebKit/UIProcess/Inspector/WebPageInspectorController.h/.cpp` | Manages all targets for a page proxy; creates the UI-process agents |
| `WebKit/UIProcess/Inspector/InspectorTargetProxy.h` | Base class for all target proxies |
| `WebKit/UIProcess/Inspector/FrameInspectorTargetProxy.h/.cpp` | Frame target proxy in the UI process |
| `WebKit/UIProcess/Inspector/PageInspectorTargetProxy.h/.cpp` | Page target proxy in the UI process |
| `WebKit/UIProcess/WebFrameProxy.cpp` | Creates and destroys frame inspector targets on frame lifecycle |
| `WebKit/UIProcess/Inspector/Agents/ProxyingNetworkAgent.h/.cpp` | Network agent in the UI process; receives events from the per-frame `FrameNetworkAgentProxy` |
| `WebKit/UIProcess/Inspector/Agents/ProxyingPageAgent.h/.cpp` | Page agent in the UI process; `getResourceTree` aggregation over `WebFrameProxy` |
| `WebKit/UIProcess/Inspector/Agents/InspectorStorageAgent.h/.cpp` | Storage domain over `API::HTTPCookieStore` |
| `WebKit/UIProcess/Inspector/InspectorCookieStoreHelpers.h/.cpp` | Cookie filtering shared with WebDriver BiDi |
| `WebKit/UIProcess/Inspector/Agents/ProxyingPageAgent.messages.in` | Events from the WebContent process; guarded by `[ExceptionForEnabledBy]` |
| `WebKit/UIProcess/Inspector/Agents/ProxyingNetworkAgent.messages.in` | Events from the WebContent process; guarded by `[ExceptionForEnabledBy]` |
| `WebKit/WebProcess/Inspector/FrameInspectorTarget.h/.cpp` | Frame target in the WebContent process |
| `WebKit/WebProcess/Inspector/UIProcessForwardingFrontendChannel.h/.cpp` | IPC from the WebContent process to the UI process for events |
| `WebKit/WebProcess/Inspector/WebInspectorBackend.h/.cpp` | Creates per-frame proxies; latch-and-fan-out setters |
| `WebKit/WebProcess/Inspector/WebInspectorBackend.messages.in` | Enable/Disable instrumentation and request/reply messages |
| `WebKit/WebProcess/Inspector/PageAgentProxy.h/.cpp` | Page instrumentation proxy, one per local frame |
| `WebKit/WebProcess/Inspector/FrameNetworkAgentProxy.h/.cpp` | Network instrumentation proxy, one per local frame; interception hooks |
| `WebKit/WebProcess/Inspector/BackendResourceDataStore.h/.cpp` | Per-process store of bodies, certificates and source-map URLs |
| `WebCore/inspector/FrameInspectorController.h/.cpp` | Per-frame agent controller with fallback chain; owns the per-target `InjectedScriptManager` and `FrameDebugger` |
| `WebCore/inspector/PageInspectorController.h/.cpp` | Per-page agent controller (legacy and fallback target); `forEachDebugger` |
| `WebCore/inspector/InstrumentingAgents.h` | Agent registry with frame-first resolution and fallback to the page |
| `WebCore/inspector/FrameDebugger.h/.cpp` | Per-frame `JSC::Debugger` attached to the frame's global objects |
| `WebCore/inspector/agents/frame/Frame{Console,Runtime,Debugger,DOM,CSS,DOMStorage,Worker}Agent.*` | The per-frame agents |
| `WebCore/inspector/agents/frame/FrameDOMAgentStubs.cpp` | DOM commands not yet supported on frame targets |
| `JavaScriptCore/inspector/agents/InspectorTargetAgent.cpp` | Target multiplexing and command routing |
| `JavaScriptCore/inspector/InspectorBackendDispatcher.cpp` | `BackendDispatcher` with fallback dispatcher |
| `WebInspectorUI/UserInterface/Controllers/DOMManager.js` | `keyForNodeId`, `_initializeFrameTarget` (splicing) |
| `WebInspectorUI/UserInterface/Controllers/CSSManager.js` | `keyForStyleSheet` |
| `WebInspectorUI/UserInterface/Controllers/DOMUndoCoordinator.js` | Per-edit target stacks for multi-frame undo |
| `WebInspectorUI/UserInterface/Models/Frame.js` | `addExecutionContext` (target-qualified contexts) |
| `WebInspectorUI/UserInterface/Protocol/MultiplexingBackendTarget.js` | Initializes the Browser, Storage and Target managers for the multiplexing target |
