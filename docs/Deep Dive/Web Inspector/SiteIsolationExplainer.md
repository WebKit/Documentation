# Site Isolation Plans

_Last updated Dec 9, 2025._

This document aims to explain the implications of Site Isolation on the architecture
of Web Inspector.

## Terminology

`InspectorBackend`: represents a place that command requests can be dispatched or where instrumentation events are emitted.

## Background: Evolution of WebKit Process Model

20 years ago, Web Inspector was introduced in a world where all of WebKit ran in a single process, including
the `WebInspectorUI` user interface. In the single process model, Web Inspector's frontend sends text JSON-RPC commands
over a channel to a single `InspectorBackend` associated with a `WebCore::Page`, which then parses and dispatches commands to various
group command handlers called _agents_ using `InspectorBackendDispatcher`.

WebKit2 introduced the multi-process model where multiple Web Content Processes are coordinated by a central UIProcess.
Initially this had no effect on the design of targets in Web Inspector, because frontend messages are parsed and dispatched in
one WebProcess at the WebCore level, with WebInspectorUI connected to WebProcesses directly without UIProcess involvement.

A series of half-measures towards Site Isolation started to complicate this picture of one-frontend and one-backend.
Process Swap On Navigation (PSON) was one such effort with a simple premise: when a Page navigates to a new origin,
we should perform the load in a new WebProcess so that a potentially compromised WebProcess won't be reused across the
different-origin security boundary. For Web Inspector, this meant that the there is still one-frontend and one-backend, but
the backend instance may change as the inspected page navigates. Without further changes, the debugger (WebInspectorUI) would automatically
close its connection to InspectorBackend upon such navigations if a new WebProcess is used.

## Background: Inspector Target system

To enable WebInspectorUI debugging session to persist across web process swaps, the concept of Targets was introduced with
three design goals:

1. provide an opaque handle that WebKit can use to route incoming JSON-RPC messages to the correct InspectorBackend (WebPage, Worker, and now Frame).
1. allow reuse of command interfaces across multiple types of execution contexts (e.g., `PageRuntimeAgent`,
`WorkerRuntimeAgent`, `JSGlobalObjectRuntimeAgent` all implement the `RuntimeBackendDispatcherHandler` interface created from `Runtime.json`.)
1. allow the frontend to reason about the capabilities of each InspectorBackend (e.g., send commands to all "capable" targets)

A `Target` represents an execution context, within the overall `WebPage` debuggable, to which JSON-RPC commands can be sent. During a single debugging session,
WebInspectorUI will inspect multiple Page instances which may be hosted in different Web Processes. Each Page/WebPage/WebPageProxy for the same
`WebPageDebuggable` appears as a `PageTarget`. Therefore, WebInspectorUI is able to switch between `PageTarget` instances when a main frame load is committed, while still handling events from both targets as the old page unloads and the new page loads.

Targets also solve the problem of getting a message dispatched to the correct `BackendDispatcher` and corresponding agents. With the introduction of Page targets, the connection to the debugger was moved to UIProcess, but most commands are parsed and handled by agents in WebProcess
after initial JSON parsing in UIProcess. The target routing system is implemented in the backend as the `Target` domain in `InspectorTargetAgent`
and instantiated as part of `WebPageInspectorController`. Targets as exposed by TargetAgent have a simplified lifecycle compared to WebPages and Workers,
but still contain essential concepts such as pausing/resuming, provisional/committed state, and target creation/destruction events.

- Page target: represents a legacy "direct" backend target which does not support multiple Targets. This is for backwards compatibility with old (pre-PSON and WebKitLegacy) backends.
- WebPage target: represents a WebPageProxy or WKWebView. Associated with multiple transient worker and frame targets. For backwards compatibility with post-PSON backends which lack Frame targets, WebInspectorUI can also use PageTarget as the main Frame target when iterating execution contexts.
- Worker target: represents a dedicated Web Worker target. Associated with the parent Page target that spawned the worker.

ServiceWorker, ITML, and JavaScript (i.e., `JSContext`) targets are standalone debuggables and not exposed as sub-targets of WebPage target within debuggable.
The fact that they have target types is for convenience in restricting which domains are supposed to be exposed.

FIXME: describe proxying to workers, before and after


## What are the key issues motivating design changes?

Under Site Isolation, 

- Web Inspector backend can no longer assume that all frames are in the same process, or that a Page is in the same process as its Frame.
- One backend in one Web Process only has partial resource data.
- WebInspectorUI needs to connect to multiple web processes to receive events and fetch resource data.

Concurrently to Site Isolation, WebKit is also gaining support for WebDriver BiDi. The implementation for WebDriver BiDi is
automation-focused, but ultimately it is just another JSON-RPC debug protocol that we have to support in WebKit. One of the main 
differences is that WebDriver is UIProcess-based, and it includes the ability to target commands to specific `browsing contexts`.
This is basically the same thing as targeting a command to a specific frame. Similarly, FrameTargetProxy in UIProcess routes its message to the
correct `InspectorBackend` using `sendMessageToProcessContainingFrame()`.

The rest of this document motivates a modified architectural design based on Frame targets.

## What are the main changes are being proposed?

- [X] Add new `Frame` target type which represents a place that commands can be targeted at. A Page target has one or more Frame targets.
- [X] Introduce `FrameInspectorController` which owns per-frame agents in WebProcess.
- [X] Deprecate the 'Page' debuggable type (i.e. remove direct backend support).
- [X] Transition WebKitLegacy to use in-process proxying backend.
- [/] Move per-page agents to UIProcess; use 'octopus' design for instrumentation forwarding from WebProcess `InspectorInstrumentation`.
- [/] Keep per-execution-context agents in WebProcess; dispatch happens from `FrameInspectorController`.
- [ ] Update resource/frame identifier scheme to work with Site Isolation (currently uses a process-local static uint64...)
- [ ] Fix uses of `WI.assumingMainTarget()` in WebInspetorUI

FIXME: add diagrams for DirectTargetBackend, ProxyingTargetBackend with Pages, and ProxyingTargetBackend with Frames.
FIXME: need illustration of octopus hybrid page/network agent and more details

---

BJB> Everything below this has not yet been rewritten.

## Why do we need Frame target?

- Each frame has its own execution context (Document), but it may or may not co-locate in the same process as other frames.
- Helps the backend to route agent commands to the appropriate Webcontent process.
- Frame targets in the frontend abstracts away which actual process is hosting the frame.
- Reuse existing target routing mechanism for Frame-targeted commands.
- Backend needs to know for each frame which process that data resides in.

## Can't we use more than one Page target for OOPIF?

- This violates the expectation that WebInspectorUI should not be overly familiar with
  the process model of WebKit and specifically the policy choices for Site Isolation.
- Frontend code designed to iterate execution contexts (frames), not processes.
- Reasoning about multiple Page targets, which may or may not be a WKWebView, is error-prone.

## What's the difference between multiple Frame targets vs multiple Page targets?

- WebKitLegacy Frame Target adapter (already done)
- Moving Network and Page agent to UIProcess (this might be required anyway to provide global page identifiers)
- Add IPC support for Page and Network events and commands

## What about WebKitLegacy?

- Unable to stop supporting it any time soon, still has 1st party clients that we can't break.
- Easier to add frame target adapter for single-process mode,
  than to continue supporting direct backend target implementations
  (i.e., have IPC (new) and no-IPC (existing) versions of Page and NetworkAgent)
- Qianlang added this adapter as part of the Console work, it uses different frame lifecycle instrumentation.

## What about backwards compatibility with shipping Page targets?

- Frontend needs to continue to support shipping Page, Worker, and ServiceWorker targets w/o any frame targets.
- For Page targets without Frame targets, the frontend assumes it's older and send commands to the Page target.
- Target iteration assumes Page w/ 1+ Frame target -> send frame messages to frames, otherwise send to Page target.

Example:

For Page.getResourceTree, in shipping Web Inspector, all frame tree nodes are included in one payload.

With Site Isolation, not all resources will be in the same process, so each payload will contain a
subset of frame tree nodes and their resources. Whether or not we use Frame or Page targets, we still need
to rework the frontend to merge results from multiple targets. Since Frames are the unit of process isolation,
it's easier to think about the correct behavior of Inspector backend commands in terms of frames.

The alternative would be to send commands to every sub-page of a page, but this is difficult to reason about because
the policy for which frames should go into which processes is variable across platforms and releases.


What is the plan for each domain?

- Domains to transition to per-frame agents:
    Debugger, Runtime, CSS, DOM, Audit, Animation, DOM, DOMStorage, DOMDebugger, Canvas
- Domains to be moved to UIProcess:
    Network, Page
- Domains to stay as-is:
    Target, Browser, Worker, ServiceWorker
- Domains TBD:
    LayerTree, Heap, Memory, Storage, IndexedDB
- Domains removed:
    Database, AppCache


## Other Deprecations

- AugmentableInspectorController
- ITML debuggable type
