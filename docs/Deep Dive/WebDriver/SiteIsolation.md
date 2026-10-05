# WebDriver and Site Isolation

_Last updated 2026-10-04._

This document describes how site isolation affects WebKit's WebDriver implementation — the
classic W3C WebDriver HTTP endpoints and the WebDriver BiDi modules — and the design each
command and event follows when a page's frames are spread across several WebContent processes.
For a primer on site isolation itself see [Site Isolation](../SiteIsolation.md). The rules and
UI-process primitives that WebDriver shares with Web Inspector are defined once, in
[Automation and Inspection Under Site Isolation](../SiteIsolation.md#automation-and-inspection-under-site-isolation);
this page covers only what is specific to WebDriver. For the Web Inspector side see
[Web Inspector and Site Isolation](../Web%20Inspector/SiteIsolationExplainer.md).

**Contents:**
- [The Stack: Client Side, API Side, Server Side](#the-stack-client-side-api-side-server-side)
- [Shared Machinery](#shared-machinery)
- [Classic WebDriver Endpoints](#classic-webdriver-endpoints)
- [WebDriver BiDi: `browsingContext`](#webdriver-bidi-browsingcontext)
- [WebDriver BiDi: `emulation`](#webdriver-bidi-emulation)
- [WebDriver BiDi: `script` and `log`](#webdriver-bidi-script-and-log)
- [WebDriver BiDi: `session`](#webdriver-bidi-session)
- [WebDriver BiDi: `browser`](#webdriver-bidi-browser)
- [WebDriver BiDi: `input`](#webdriver-bidi-input)
- [WebDriver BiDi: `storage`, `permissions`, `webExtension`](#webdriver-bidi-storage-permissions-webextension)
- [WebDriver BiDi: `network`](#webdriver-bidi-network)
- [Shared Primitives with Web Inspector](#shared-primitives-with-web-inspector)
- [Testing](#testing)
- [Key Source Files](#key-source-files)

---

## The Stack: Client Side, API Side, Server Side

WebKit's WebDriver stack has three sides. The **client side** is any W3C WebDriver or BiDi
client. The **api side** is the WebDriver service (`Source/WebDriver`), which speaks HTTP and
WebSocket to the client and relays commands to the browser over the Automation protocol. The
**server side** is the Automation backend inside WebKit: `WebAutomationSession` and the BiDi
agents in the UI process (`Source/WebKit/UIProcess/Automation`), plus one
`WebAutomationSessionProxy` per WebContent process (`Source/WebKit/WebProcess/Automation`).

```
 client side            api side (WebDriver service)          server side (WebKit)
 ┌────────────┐  HTTP   ┌───────────────────────────┐  JSON   ┌───────────────────────────────────┐
 │ W3C client │ ──────▶ │ WebDriverService          │ ──────▶ │ UI process                        │
 │ (classic   │ ◀────── │  └ Session (per session)   │ ◀────── │  WebAutomationSession             │
 │  or BiDi)  │         │    top-level context handle│ Automa- │   page handle  ⇄ WebPageProxy     │
 └────────────┘         │    current frame handle    │ tion    │   frame handle ⇄ FrameIdentifier  │
                        │    parent frame handle     │ protocol│   known node refs (per frame)     │
                        └───────────────────────────┘         │   BiDi agents (one per module)    │
                                                              │   SimulatedInputDispatcher (/page)│
                                                              └──────┬───────────────┬─────────────┘
                                                      async IPC to   │               │  async IPC to
                                                      the process    │               │  the process that
                                                      hosting frame A│               │  hosts frame B
                                                              ┌──────▼──────┐  ┌─────▼────────────┐
                                                              │ WebContent 1│  │ WebContent 2     │
                                                              │ (site a)    │  │ (site b, remote  │
                                                              │ WebAutomation│ │  iframe)         │
                                                              │ SessionProxy│  │ WebAutomation    │
                                                              │  JS atoms   │  │ SessionProxy     │
                                                              │  node-<uuid>│  │  JS atoms        │
                                                              └─────────────┘  │  node-<uuid>     │
                                                                               └──────────────────┘
```

The api side keeps only _handles_ — a top-level browsing-context handle, a current frame handle
and its parent handle — and sends them with every command; it never sees a process. Classic
WebDriver and BiDi share one `WebAutomationSession`: the BiDi agents call the classic primitives
(screenshot, script evaluation, element layout, input dispatch, the cookie store), so a site
isolation fix in a primitive serves both protocols.

Under site isolation a page (a BiDi _top-level traversable_) is backed by one `WebPageProxy` in
the UI process and by one `WebPage` in **each** WebContent process that hosts at least one of
its frames: the main-frame process plus one process per cross-site frame group. The UI process
is the only place that sees the whole page. All WebDriver state therefore lives in the UI
process, and WebContent processes hold only what they need to apply an override or answer a
frame-scoped query.

---

## Shared Machinery

### Rules every command and event follows

The five cross-cutting rules — (1) the UI process is the authority; (2) per-frame targets for
document data, process-level aggregation for page-wide data; (3) commands go to the hosting
process, and page-wide state fans out and is replayed; (4) asynchronous IPC, with
process-agnostic events; (5) shared primitives built once — are defined in
[Automation and Inspection Under Site Isolation](../SiteIsolation.md#automation-and-inspection-under-site-isolation).
Their WebDriver-specific consequences:

- **Identifiers** are minted in the UI process as described in the table below.
- **Frame-scoped commands** all use the routing primitive below; the `sendWithAsyncReplyToProcessContainingFrame…` form takes the frame's `FrameIdentifier` and the
  page identifier valid in that process (`webPageIDInProcessForFrame`).
- **Page-wide state** (BiDi emulation, interception, viewport) uses
  `WebPageProxy::forEachWebContentProcess` plus late-joiner replay through
  `WebPageCreationParameters`; the per-module BiDi sections give each command's sink and replay.
- **Fan-out replies** come after the last process acknowledged, for a command that fans out and
  must observe its effect.
- **Events** are emitted from hooks in `WebPageProxy` handlers. Messages from a cross-site
  frame's process reach the page through `RemotePageProxy`, which forwards every `WebPageProxy`
  message to the page; provisional (swap) loads reach it through `ProvisionalPageProxy`. Event
  emission is therefore process-agnostic by construction.
- **A page is enumerated once.** A site-isolated page is registered with every process that
  hosts one of its frames, so walking processes and collecting their pages lists a page once
  per process. Any command that needs "all pages the session controls" must therefore
  deduplicate by page identity, not by process.
- **Identity errors are decided first in the UI process.** "no such window" / "no such frame"
  are decided from the UI process's own page and frame tables before any IPC is sent.

### Identifiers: what survives a process swap

| Identifier | Minted by | Lives in | Stable across a process swap? |
|---|---|---|---|
| Page handle `page-<UUID>` / BiDi top-level context id | UI | `WebAutomationSession` ⇄ `WebPageProxy` | Yes (the `WebPageProxy` survives a swap) |
| Frame handle `frame-<UUID>` / BiDi child context id | UI | `WebAutomationSession` ⇄ `WebCore::FrameIdentifier` of the `WebFrameProxy` | Yes for subframes (the `WebFrameProxy` keeps its id when its process changes); the **main frame's** id changes on a main-frame swap, so all frame handles of the page are dropped on a main-frame navigation |
| `FrameIdentifier` | WebContent / UI | global, process-qualified | Same value in every process (`WebFrameProxy::webFrame(id)` is a static lookup) |
| Node handle `node-<UUID>` / BiDi `sharedId` | the JS atom in the frame's process | per-frame map in the atom; mirrored as a bounded, authoritative set per `FrameIdentifier` in the UI process | Minted per document; the UI set is re-keyed on a main-frame swap and dropped when the frame is destroyed |
| BiDi `realm-` followed by the realm identifier | WebContent (the UI process mints a fallback for a frame with no reported realm) | one per frame per document; the UI process holds the registry, keyed by browsing context | No, by design: a new process mints a new realm and the registry ends the old one |
| BiDi `handle-<uuid>` | WebContent | the issuing realm's handle table | No; a later use reports `no such handle` |
| Window marker (wire-only) | the JS atom | result / argument only; translated in the UI process to a window or frame reference | n/a (carries a `FrameIdentifier`) |
| BiDi navigation id | UI (`API::Navigation`) | the page's navigation state; the same before and after a swap | Yes |
| `PageIdentifier` seen by a WebContent process | UI | `webPageIDInProcessForFrame()` returns the `RemotePageProxy`'s id for an out-of-process frame | Per process |

### The routing primitive every frame-scoped command uses

```
 UI process                                                     WebContent process hosting <frameID>
 WebAutomationSession::<command>(pageHandle, frameHandle, …)
   page  = webPageProxyForHandle(pageHandle)
   frameID = webFrameIDForHandle(frameHandle)        ── WindowNotFound / FrameNotFound decided here first, before any IPC
   page->sendWithAsyncReplyToProcessContainingFrame…(
        frameID, Messages::WebAutomationSessionProxy::X(page->webPageIDInProcessForFrame(frameID), frameID, …), reply)
        │  WebFrameProxy::webFrame(frameID)->process()
        │    → the RemotePageProxy for (page, process), or the page itself
        ▼
   async reply (result, errorType)  ◀──────────────────────── WebAutomationSessionProxy::x(pageID, frameID, …)
                                                               WebProcess::webPage(pageID) / webFrame(frameID)
```

Two site isolation fixes made this work for out-of-process frames: the destination
`PageIdentifier` is the one valid in the frame's process
([bug 320563](https://bugs.webkit.org/show_bug.cgi?id=320563)), and coordinate conversion for
out-of-process frames stops at the frame's **local root** in WebContent and is finished by the
UI process ([bug 321440](https://bugs.webkit.org/show_bug.cgi?id=321440),
[bug 321593](https://bugs.webkit.org/show_bug.cgi?id=321593)).

### Event routing and scoping

```
 WebContent A (main frame)         WebContent B (remote iframe)      UI process
 console.log / realm created       console.log / realm created       WebAutomationSession (message receiver
                                                                     registered on the process pool, so it
      |                                  |                            receives from every process)
      | log entry (frame), etc.          | log entry (frame), etc.          |
      +----------------------------------+--------------------------------->|
                                                                           v
                                             frameID -> WebFrameProxy -> page -> top-level handle
                                                                      -> page -> data store -> user context
                                                                           |
                                             subscription check (design)
                                               global subscription?            -> emit
                                               contexts ∋ top-level handle?    -> emit
                                               userContexts ∋ user context?    -> emit
                                               else                            -> drop
                                                                           |
                                                                           v
                                                         event {context: the frame's own handle, ...}
```

Events are scoped in the UI process: a frame is resolved to its top-level traversable, and that
page to its user context, before a subscription is consulted; the event payload names the
frame's own context. The global and browsing-context checks are made by
`BidiSessionAgent::eventIsEnabled`; matching a subscription's user contexts against the page's
user context is part of the same design. Subscriptions never fan out to processes: each WebContent process reports
what happens in the frames it hosts, over asynchronous IPC, and
the UI process alone decides whether and how to report it. In the design, each log entry carries
the identifier of the frame that produced it, so the event names that frame's context.
UI-originated events (navigation,
prompts, downloads, context lifecycle) enter the same check from `WebPageProxy` callbacks.

---

## Classic WebDriver Endpoints

The classic server side is already mostly process-correct under site isolation: every
frame-scoped command resolves the frame handle to a `WebFrameProxy` in the UI process and
routes its IPC to the process that hosts that frame; the only coordinate conversion that needs
the whole frame tree is finished in the UI process; and pointer/wheel events are hit-tested in
the main-frame process and re-dispatched by the UI process to the owning subframe process.
Nothing in the classic surface needs a new per-frame agent. The remaining work moves the last
process-local assumptions — cookies, snapshots, one synchronous lookup — up to the UI process
or to the frame's own process.

Each group below is described in the same order: what crosses processes, where it routes, and
the site isolation caveat. The table summarizes ownership.

| Endpoint group | Owner process | WebContent involvement |
|---|---|---|
| Session, status, timeouts, new/delete session | UI | none (per-process proxies are torn down through the process pool) |
| Navigate, back, forward, refresh, title, URL, wait-for-navigation | UI (`WebPageProxy` / `WebFrameProxy` load state) | none; load callbacks arrive from whichever process loads the frame |
| Window handles, new window, window rect, maximize/minimize/fullscreen | UI + embedder | none |
| Switch to frame | UI → the **current** frame's process (resolve the child) → the **child** frame's process (focus it) | child resolution by ordinal / name / element; focus |
| Switch to parent frame, frame-handle validation | UI (`WebFrameProxy::parentFrame()`, `webFrame(id)`) | none |
| Find element(s), element state (attribute, text, rect, enabled, displayed, role, label …) | the current frame's process; geometry finished in UI | evaluate atoms; `ComputeElementLayout` to the local root |
| Element click, send keys, clear, select option | the frame's process for layout / focus / state; UI injects native input | hit-test in the main-frame process, re-dispatch to the target frame's process |
| File upload (`<input type=file>`) | UI grants the frame's process file access, then the frame's process sets the `FileList` | the frame's process |
| Element / window references (the identifier contract) | UI (authoritative record of issued handles; marker ⇄ reference translation) | the frame's process mints and resolves |
| Execute script (sync / async), page source | the current frame's process | evaluation in the frame's main world |
| Cookies | UI → network process via the page's website data store | none |
| Actions (perform / release) | UI (`SimulatedInputDispatcher` per page) | element origins in the element's process; events routed as for click |
| User prompts | UI + embedder | none (a dialog from any process is one page-level dialog) |
| Screenshots | UI (composited view snapshot) | the element's process computes the clip rectangle in local-root coordinates |
| Print | UI (`WebPageProxy` printing path) | per-frame pagination in the frame's process; composition in UI |

### Session, status, timeouts

**Crosses processes:** nothing. Session lifetime is owned by the UI process. Creating a session
does not create processes; the first browsing context vended to the session launches its
initial process with the session's site isolation preference applied to that page's
`WebPreferences` ([bug 296394](https://bugs.webkit.org/show_bug.cgi?id=296394)).

**Routes to:** the UI process only. Deleting a session fails every outstanding callback in the
UI process and tears down the per-process automation proxies through the normal process-pool
path; no WebContent process is contacted synchronously.

**Site isolation:** pages controlled by the session are isolated exactly like pages the user
opens, and cross-site navigations in them swap processes.

### Navigation and waiting

**Crosses processes:** load progress only. The page's and each frame's load state in the UI
process is updated by whichever WebContent process is loading the frame.

**Routes to:** `WebPageProxy` and `WebFrameProxy` in the UI process; navigation commands and
waits are entirely UI-process operations.

**Site isolation:** a wait keyed on a frame identifier is unaffected by the frame moving
between processes mid-navigation. When a top-level navigation swaps the main frame's process
the main frame receives a new identifier; the session treats that as a new document, drops the
frame handles it had issued for the previous document, and resolves pending page-level waits.

### Contexts: windows and frames

**Crosses processes:** switching to a child frame. The child is resolved inside the process that
hosts the _current_ frame — by ordinal, by name, or through the `<iframe>` element the client
passed — and its `FrameIdentifier` comes back; that identifier is global and identical in every
process whether the child is local or remote to that process.

**Routes to:** the UI process converts the identifier into a frame handle, then asks the process
that hosts the _child_ to focus it. The focus change is reported to the UI process and
broadcast to every other process of the page, so subsequent keyboard input is delivered to the
newly focused frame's process. Switching to the parent frame, validating a frame handle, and
window-level commands need no WebContent round trip: the UI process answers from its own frame
tree, `WebPageProxy` and the embedding client.

**Site isolation:** window and frame handles are UI-process identifiers. A page must be listed once
in the window-handle list, identified by page identity rather than by the process that hosts it
(see "A page is enumerated once" above).

### Element find and element state

**Crosses processes:** element rectangles. Lookup and state are evaluated by the automation
script injected into the frame's own process; the frame's process converts rectangles up to its
_local root_ (the outermost frame it hosts).

**Routes to:** the frame's process, addressed by the session's current frame handle. The UI
process, which alone knows the whole frame tree, converts local-root coordinates to main-frame
viewport coordinates by asking each ancestor process in turn. Accessibility-derived state
(computed role and label) is computed in the frame's process, which owns that frame's
accessibility tree.

**Site isolation:** element handles are minted and resolved only in the process that owns the
element's document; a handle presented to a different frame is reported as "no such element",
and a handle whose node has left its document as "stale element reference". Get Active Element
is a current-frame command; under site isolation the main frame's `document.activeElement` is
the `<iframe>` element, not the focused element inside it, so the api side must send the
current frame handle.

### Element interaction

**Crosses processes:** pointer events and file access. Interaction commands compute their
target geometry as above and then inject native input events in the UI process. Commands that
change element state directly rather than through input — selecting an `<option>`, clearing a
field, attaching files to a file input — are executed in the frame's process.

**Routes to:** pointer events are hit-tested in the main frame's process; when the hit lands
inside a frame hosted by another process, the main-frame process returns the target frame and
the event position transformed into that frame's coordinate space, and the UI process
re-dispatches the event there, with a dedicated timeout so an unresponsive subframe cannot wedge
the page. Keyboard events go to the process that hosts the focused frame, which the session
establishes by switching frames or by running the focus step of Send Keys inside the target
frame. The automation session is notified when the page has finished processing all queued
input, independent of how many processes participated.

**Site isolation:** attaching files additionally requires the UI process to grant the frame's
process read access to the chosen paths (sandbox extension and network-process allow-list),
exactly as it would for a user-driven file chooser; the grant is bound to the process captured
when the command started, and the command fails rather than hand files to a process that was
never granted access if the frame moved in the meantime.

```
 Element Click in a cross-origin iframe (site isolation on)

 UI: WebAutomationSession                 main-frame WebContent            iframe WebContent
  computeElementLayout(frame=B) ──────────────────────────────────────────▶ local-root rect/IVCP
  convertPointToMainFrameCoordinates ─────▶ ContentsToRootViewPoint(B)   (WebPageProxy member)
  ◀──────────────────────────────────────── main-frame viewport point
  platformSimulateMouseInteraction → native event → WebPageProxy::handleMouseEvent
  sendMouseEvent(mainFrame) ──────────────▶ hit test → RemoteUserInputEventData{B, p'}
  sendMouseEvent(B, p') ──────────────────────────────────────────────────▶ dispatch click
  ◀──────────────────────────────────────── handled ◀────────────────────── handled
  mouseEventsFlushedForPage → command completes → waitForNavigationToComplete
```

### Element references, shadow roots, and window references

**Crosses processes:** element handles and window markers. An element reference is a
per-document handle minted by the automation script in the document's process. A window or
frame reference is a session handle; between the UI process and a WebContent process it travels
as a marker naming the frame by `FrameIdentifier`, which every process can resolve to its own
local or remote frame. BiDi `window` remote values use the same marker and the same UI-side
translation.

**Routes to:** the UI process keeps the authoritative, bounded record of every handle issued
per frame, so that it can tell a _stale_ reference (issued for this frame, node since detached
or document since replaced) from a _foreign_ one (never issued for this frame). The WebContent
process reports resolution failures as "not found" together with the handle; the UI process
consults its record and maps the failure to "stale element reference" or "no such element".

**Site isolation:** the record is keyed by `FrameIdentifier`, survives subframe process swaps
unchanged, is re-keyed when a main-frame swap commits, and is dropped when the frame is
destroyed. Returning `window` from a script in a cross-origin iframe, or passing another
frame's reference as an argument, works regardless of which processes host the frames involved.
No synchronous IPC is used in either direction (the synchronous "is this a known reference"
query that exists today on the miss path is being removed in favour of the UI-side remap).

### Execute script and page source

**Crosses processes:** the function, its arguments and the result. The UI process forwards the
function, its JSON-encoded arguments (with element and window references already translated),
and the timeout.

**Routes to:** the process that hosts the current frame, which evaluates the script in the
frame's main world, waits for the result or the implicit callback, serializes the result with
the WebDriver internal JSON clone algorithm, and replies asynchronously. Page source is a
script evaluation in the current frame.

**Site isolation:** a frame navigation, frame removal, process termination, or a user prompt
opening while a script is pending resolves the pending reply with the appropriate error or, for
a prompt, with `null`.

### Cookies

**Crosses processes:** the network process answers; under site isolation WebContent is not
consulted. Cookie commands are answered by the UI process against the page's website data store.
(Moving the classic cookie commands off the main-frame WebContent process is part of the
remaining work listed above.)

**Routes to:** Get All Cookies and Get Named Cookie return the cookies that the _current_
frame's document would see: the UI process takes the current frame's URL from `WebFrameProxy`,
the first-party URL from the page's main frame, and asks the network process for the cookies
visible to that `(url, first-party, partition)` triple, including HTTP-only cookies. Add
Cookie, Delete Cookie, and Delete All Cookies operate on the cookie store with the same
first-party and partition.

**Site isolation:** a cookie added while a cross-site iframe is the current browsing context is
written into that iframe's partition. Deleting a cookie for a cookie-averse document (such as
the initial `about:blank`) is a no-op that succeeds. One UI-side partitioned cookie reader
serves classic WebDriver, BiDi `storage.*`, and the Web Inspector Storage domain.

### Actions

**Crosses processes:** element origins and native input. Pointer and wheel actions are
expressed in main-frame viewport coordinates; an `Element` origin is resolved by computing the
element's in-view center point in its own frame's process and converting it to main-frame
coordinates through the frame's ancestors.

**Routes to:** a per-page input dispatcher in the UI process turns each tick into native
platform events and injects them at the top of the page's event pipeline, where WebKit's normal
site isolation input routing hit-tests in the main-frame process and re-dispatches to the
process that owns the target frame. The dispatcher advances to the next action only when the
page reports that all queued input has been processed. Keyboard actions are delivered to the
process hosting the focused frame.

**Site isolation:** input-source state (pressed keys and buttons, pointer position) is kept in
the UI process for the lifetime of the session, so releasing actions or closing the page never
depends on a WebContent process.

### User prompts

**Crosses processes:** the dialog request only. Whichever process raises a dialog, the embedding
client shows one dialog for the page.

**Routes to:** the UI process. The automation session queries, accepts, dismisses, or fills the
dialog through the client, and uses the dialog's appearance to settle pending navigation waits
and script evaluations for that page. No WebContent process is consulted.

**Site isolation:** a user prompt is a property of the page, not of a process. `beforeunload`
prompts are honored only from the process that owns the frame.

### Screenshots

**Crosses processes:** the clip rectangle only. An element's own frame process scrolls it into
view and computes its rectangle in local-root coordinates; the UI process converts that to
main-frame viewport coordinates.

**Routes to:** the UI process, which composes the screenshot from the page's composited output,
which already contains every frame regardless of which process rendered it. A viewport
screenshot is a view snapshot taken after the next presentation update. An element screenshot
is the same snapshot clipped to the element's rectangle. Content outside the viewport (a
full-page screenshot, or an element larger than the viewport) is captured by the UI process in
viewport-sized tiles — scrolling the page, waiting for the presentation update, snapshotting,
and stitching — or, where the platform compositor supports it, by a single compositor-side
render of the full document bounds.

**Site isolation:** under site isolation no WebContent process rasterizes other processes'
frames. The
clip/scale/encode post-processing is shared with BiDi `captureScreenshot` and the Web Inspector
`Page.snapshotNode` / `snapshotRect` commands. (Element and full-page screenshots moving to the
UI-side snapshot path is part of the remaining work listed above.)

### Print

**Crosses processes:** per-frame pagination, in each frame's process.

**Routes to:** the page's printing path on `WebPageProxy`, invoked by the automation session
with the requested page size, margins, scale and page ranges; the PDF data is received in the
UI process.

**Site isolation:** the printing path composes each out-of-process frame's content in the UI
process. Classic Print and BiDi `browsingContext.print` share this implementation.

---

## WebDriver BiDi: `browsingContext`

**Needs from web content:** almost nothing. **Routes:** the UI process answers from its authoritative frame tree and from page proxy load callbacks; frame-targeted work goes to the process hosting the frame. **Latched on the page proxy:** the viewport override. **Caveat:** per-process frame trees are partial.

```
                 UI process
  +-----------------------------------------------+
  |  WebAutomationSession                         |
  |    handle maps: page <-> "page-…"             |
  |                 frame <-> "frame-…"           |
  |    BidiBrowsingContextAgent  emulation store     |
  |    (navigation bookkeeping)  (override store) |
  |                      |                        |
  |                WebPageProxy  (one per page)   |
  |                 |        \                    |
  |          WebFrameProxy   RemotePageProxy …    |
  |          tree (authoritative)                 |
  +-------|------------------|--------------------+
          | WebPage msgs     | WebPage msgs (same page id space per process)
          v                  v
  +----------------+   +----------------+
  | WebContent A   |   | WebContent B   |
  | main frame     |   | cross-site     |
  | (+ same-site   |   | iframe(s)      |
  |  iframes)      |   |                |
  | WebAutomation- |   | WebAutomation- |
  | SessionProxy   |   | SessionProxy   |
  +----------------+   +----------------+
```

Asking every process of the page for its frame tree yields N partial trees, each rooted at that process's copy of the main frame with URLs only for the frames it hosts. Rather than stitch them, the UI process uses the authoritative tree it already holds (`WebFrameProxy`: parent, `childFrames()`, committed URL from whichever process hosts the frame). The design builds `getTree` and `contextDestroyed` from `WebFrameProxy` with no IPC, using the same tree walker the Web Inspector Page domain uses for `getResourceTree`.

| Command / event | Owner process | WebContent involvement |
|---|---|---|
| `activate` | UI + embedder (window focus) | activity state fanned out by the page proxy |
| `captureScreenshot` (child context) | the frame's process paints its local root | yes |
| `captureScreenshot` (top-level, page has remote frames) | UI composited view snapshot; clip / scale / encode in UI | none |
| `close` | UI | the unload prompt for `promptUnload: true` runs in the main-frame process |
| `create` | UI + embedder | none |
| `getTree` | UI (`WebFrameProxy` walk, by design) | none |
| `handleUserPrompt` | UI + embedder | the raising process resumes via the page proxy's completion handler |
| `locateNodes` | the context's process | locator evaluation and node serialization |
| `navigate` / `reload` (top-level) | UI (`WebPageProxy` load, `API::Navigation` id) | none |
| `navigate` / `reload` (child context) | UI → the frame's process (frame-targeted load) | the frame's process reports the navigation it started |
| `print` | UI; pagination and drawing per frame | the frame's process |
| `traverseHistory` | UI (`WebBackForwardList`) | none |
| `setViewport` | UI (three-tier override store; view size via the embedder; device scale on the page proxy) | fan-out + late-joiner replay |
| `contextCreated` / `contextDestroyed` | UI (`WebPageProxy` / `WebFrameProxy` lifecycle; subtree from the UI walker) | none |
| navigation events, `historyUpdated` | UI (`WebPageProxy` load callbacks, UI-minted navigation ids) | none |
| `userPromptOpened` / `userPromptClosed` | UI (dialog request from any process via the page proxy) | none |
| `downloadWillBegin` / `downloadEnd` | UI (`DownloadProxy`, fed by the network process) | none |

**Screenshots.** A context's screenshot is rendered by the process that hosts its document: the command resolves the context to its frame, sends the request to the hosting process with the page identifier valid there, and that process paints the frame's local root at the requested clip and scale. A top-level context whose page spans several processes cannot be painted by the main-frame process alone, so the page proxy takes a composited view snapshot in the UI process when the page has remote frames and paints in-process otherwise. Clip, `imageSize` scaling and `format` / `quality` encoding are applied in the UI process on the returned bitmap in both cases, so both paths produce the same wire result. The vendor recording commands capture the viewport through the same path.

**Navigation.** For a top-level context the page proxy starts the load and returns an `API::Navigation`, whose identifier is the BiDi navigation id. For a child context the page proxy sends the load to the process hosting the frame, and that process reports the navigation it started; either way the same id flows through `navigationStarted`, `navigationCommitted` and the command reply. The session's per-navigable navigation record is keyed by the navigable (the page for a main frame, the frame identifier for a child), so a cross-site navigation that moves the main frame to a new process continues the same record. `wait` is satisfied from the page's or frame's load state. `traverseHistory` is a `WebBackForwardList` operation on the top-level context; the page proxy swaps the main-frame process when the target entry is cross-site.

**Navigation events** are produced in the UI process from the page proxy's load callbacks. Every process hosting a frame of the page reports its frames' loads to the same page proxy (through the remote page proxy for cross-site frames, through the provisional page proxy for a main frame moving to a new process), so one code path emits the events whatever the process layout. `fragmentNavigated` is emitted for same-document navigations that change the fragment; `pushState` / `replaceState` emit `historyUpdated`, distinguished by the same-document navigation type the WebContent process reports.

**Context lifecycle.** `contextCreated` is emitted when a navigable comes into existence: for a top-level traversable when its page proxy gets its first main frame, for a child when the page proxy learns of the new frame from the parent frame's process. Process swaps create and destroy no navigables and emit nothing; a frame that moves to another process is not destroyed. `originalOpener` is recorded on the new page at creation regardless of `noopener`. `contextDestroyed` is emitted before a navigable is torn down, with the navigable info at full depth built from the frame subtree about to go away. On `session.subscribe` the UI process replays `contextCreated` for every existing navigable in tree order (see [`session`](#webdriver-bidi-session)).

**User prompts.** `userPromptOpened` is emitted when a WebContent process asks the page to show an `alert`, `confirm`, `prompt` or `beforeunload` dialog, with the handler the session's `unhandledPromptBehavior` selects for that type. For `accept`, `dismiss` or `ignore` the UI process answers the dialog itself and emits `userPromptClosed`. The answer reaches the raising process through the page proxy's completion handler, so a prompt raised from a cross-site frame resumes that frame's process. The prompt-handler table (page override → user context → session capability → spec default) is one lookup shared with classic `unhandledPromptBehavior`, `browser.createUserContext` and `input.fileDialogOpened`.

**Downloads.** `downloadWillBegin` is emitted when a download proxy starts for a page the session controls, with the context id of the originating frame (the download proxy carries the originating page and frame info whichever process started it); `downloadEnd` when it finishes, fails or is canceled. Downloads are accepted only once the session has set a directory with `browser.setDownloadBehavior`.

**Viewport.** `setViewport` stores the requested viewport and device pixel ratio in the session's three-tier override store (per top-level context, or per user context for every current and future page in it). Applying it sets the page's web view size (the embedder sizes the view's content area, not its window) and the page's custom device scale factor; the page proxy propagates both to every process hosting a frame of the page and to processes that join later.

---

## WebDriver BiDi: `emulation`

**Needs from web content:** one resolved value per page, applied at a sink. **Routes:** resolve in the UI process, apply in every process. **Latched on the page proxy:** the resolved value, replayed to late joiners.

```
 emulation.setX {value, contexts | userContexts | (global)}
      |
      v
 emulation Override<T> store              (UI process, per session)
   per top-level page  >  per user context  >  global
      |  valueForPage(page, userContextID)  — most specific wins
      v
 WebPageProxy::setXOverride(resolved)     (UI process, per page; also stored for replay)
      |  forEachWebContentProcess
      v
 WebPage::SetX(resolved)   ───►  WebCore Page / Settings / JSC hook   (every process of the page)
      ^
      |  replay: finishAttachingToWebProcess (swap) + WebPageCreationParameters (new frame process)
```

The three-tier store lives in the UI process; the WebContent side never learns about contexts or user contexts. Web Inspector's `Page` overrides write the same page-proxy-held value and ride the same `WebPage` sink messages; whichever client wrote last wins at the sink (see [Shared Primitives](#shared-primitives-with-web-inspector)). Overrides that are per-page `WebPreferences` (scripting, touch) use the existing per-page preferences copy, which already fans out and rides creation parameters.

| Command | Owner | Sink in each process of the page | Replay to late joiners |
|---|---|---|---|
| `setUserAgentOverride` | UI (store → `WebPageProxy::setCustomUserAgent`) | `SetUserAgent` | `WebPageCreationParameters.userAgent` |
| `setScreenOrientationOverride` | UI (page proxy → `WebScreenOrientationManagerProxy`) | orientation change notification; the manager proxy must answer orientation queries from every process hosting a frame of the page | on attach |
| `setScriptingEnabled` | UI (per-page `WebPreferences` copy with JavaScript off) | `PreferencesDidChange` | creation parameters |
| `setMediaFeaturesOverride` | UI (store → page proxy) | forced `Settings` values and the appearance override, the same sink as Web Inspector's user-preference overrides | creation parameters (to be added) |
| `setGeolocationOverride` | UI (store → page proxy) | applied where positions are delivered to the page's `GeolocationController` | creation parameters |
| `setLocaleOverride` | UI (store → page proxy) | a `Page`-level language list consulted by `navigator.language(s)`, the global object's default-locale hook, and `Accept-Language` for the page | creation parameters |
| `setTimezoneOverride` | UI (store → page proxy) | a per-global-object time zone in JavaScriptCore (a process-wide override would leak to other pages in the process); `unsupported operation` where no such sink exists | creation parameters |
| `setTouchOverride` | UI (per-page setting) | `PreferencesDidChange` | creation parameters |
| `setScreenSettingsOverride` | UI (store → page proxy) | a `Page`-level screen-size override consulted by every local frame's `screenSize()` (today the override is on the main frame only) | `WebPageCreationParameters.overrideScreenSize` |
| `setNetworkConditions` (`offline`) | UI → network process per-page automation state; `onLine` override fanned to every process | `navigator.onLine` | creation parameters |
| `setViewportMetaOverride` | UI (page proxy viewport-arguments override; platforms with viewport meta only) | `WebPage` message | `WebPageCreationParameters.overrideViewportArguments` |
| `webkit:setFocusEmulationEnabled` | UI (activity state the page proxy sends) | activity state | on attach |

**Caveat.** A user-agent override applied to one page is visible to service and shared workers of other pages in the same process pool, because workers take the pool-wide user agent. This is a limitation of the worker path, not of site isolation.

---

## WebDriver BiDi: `script` and `log`

**Needs from web content:** realm lifecycle, evaluation, serialization, console messages. **Routes:** the UI process holds the authoritative registries and scoping; the realm's or frame's process executes and reports over asynchronous IPC. **Replayed:** preload scripts (to every process in the pool, including later ones), buffered log entries, and realms on subscribe. **Caveat:** realms are process-qualified and do not survive a swap.

```
UI process                                    WebContent process (one per site; N per page under site isolation)
+-------------------------------------------+ +--------------------------------------------------+
| WebAutomationSession                      | | WebAutomationSessionProxy (one per process)       |
|   browsing-context handle maps            | |   per-frame injected AutomationSessionProxy JS    |
|   known node references (per frame)       | |     (one script object per JSGlobalObject)        |
|   WebDriverBidiProcessor                  | |     node id table, BiDi handle table, serializer  |
|     BidiScriptAgent                       | |   realm ids (process-qualified), worker realm maps|
|       realm registry (UI copy)            | |   preload-script registration mirror             |
|       preload-script registry             | +--------------------------------------------------+
|       event scoping (top-level traversable)|           ^ async IPC up: realm lifecycle, log entries, channel messages
|     BidiLogFrontendDispatcher             |            | async IPC down (with reply): evaluate,
+-------------------------------------------+            |   callFunction, disown, preload add/remove
                                                         v
                                              WebCore AutomationInstrumentation hooks
                                                WindowProxy (realm create/destroy per world)
                                                FrameConsoleClient / WorkerGlobalScope (console)
                                                Worker*ThreadProxy (worker realms)
```

| Command / event | Owner process | WebContent involvement |
|---|---|---|
| `getRealms` | UI (realm registry) | none |
| `realmCreated` / `realmDestroyed` | UI (registry, fed by every process's `WindowProxy` hooks) | reports realm lifecycle for the frames and workers it hosts |
| `evaluate` / `callFunction` | the realm's process | evaluation, argument deserialization, serialization; replies with the executing realm id |
| `disown` | the realm's process | drops handles from the realm's table |
| `addPreloadScript` / `removePreloadScript` | UI (registry) → every process in the pool | runs the script when a window object is initialized |
| channels / `script.message` | the realm's process emits; UI scopes | serializes the argument in the realm |
| `log.entryAdded` | the frame's or worker's process captures; UI attributes, buffers, scopes | serializes arguments and call stack at the hook |

**Realms.** Every WebContent process reports realm creation and destruction for the frames and workers it hosts, using realm identifiers it mints itself. The identifier embeds the process identifier, so the UI process rejects a message whose realm does not belong to the sending process. `script.getRealms` is answered entirely from the registry, so out-of-process iframes appear exactly like in-process ones. A realm identifier is stable for one document in one process; a navigation, a process swap or a crash each end the old realm and start a new one. Two invariants keep the registry consistent when reports arrive on different process connections in any order: at most one window realm is current for a given browsing context and world (a creation that supersedes an earlier realm implies its destruction), and a destruction for a realm the registry no longer holds is ignored. When a process disconnects, the UI process destroys every realm it minted. Realm events are scoped to the top-level traversable of the realm's navigable, while the event's `context` names the navigable itself.

**Evaluation.** `script.evaluate` and `script.callFunction` run in the process that hosts the target navigable, inside the target realm's global object. The UI process resolves the target (a `context` target names the navigable's current window realm in the normal world or the named sandbox world; a `realm` target is looked up in the registry and mapped to its navigable and process), validates parameters, and pre-resolves what it can: a `sharedId` never issued for the target navigable is rejected with `no such node` before any IPC. It then sends one asynchronous message. The process deserializes `this` and the arguments in the target realm (a `handle` against that realm's handle table, a `sharedId` against the navigable's node table, a channel into a function that posts `script.message` events), evaluates through the JavaScriptCore API against the realm's global object so page Content Security Policy does not apply, serializes the result or exception in that realm, and replies with the value and the executing realm's identifier. The UI process checks that realm belongs to the sending process, reports it in the result, and translates process-local window markers into context ids. If the realm was replaced while the command was in flight, the executing process fails the pending callback and the client sees `no such frame`.

**Remote values, handles, shared ids.** Remote values are serialized in the realm that produced them. Handles are allocated by that process, recorded in the realm's handle table, and valid only for commands targeting that realm; `script.disown` is routed to the realm's process. Shared ids are allocated by the process when a node is first serialized and recorded in the UI process against the node's navigable; the UI process is the authority on whether one was ever issued, which it needs because a navigation can replace the hosting process. A serialized `window` value carries a process-local marker holding the window's frame identifier; the UI process replaces it with the browsing-context handle when it processes the reply, so a `WindowProxy` of an out-of-process iframe serializes to that iframe's context id with no cross-process query.

**Preload scripts and sandbox realms.** Preload scripts are registered in the UI process and mirrored, in registration order, into every process of the session's process pool, including processes created later, so every new document of every frame runs the applicable scripts when its window object is initialized. Filtering by top-level browsing context and user context is evaluated in the executing process against identifiers that are the same in every process hosting the page. A sandbox realm is an isolated script world owned by the process hosting the frame, created lazily the first time a command, preload script or channel targets that sandbox name in that frame, and reported to the registry like any window realm. Handles are scoped to the sandbox realm that issued them; shared ids remain valid across all realms of the same navigable.

**Channels.** A channel argument is deserialized in the target realm into a function. When page script calls it, the process serializes the argument in that realm and sends an asynchronous message to the UI process, which verifies the realm belongs to the sender, builds `script.message` with a `source` of the realm and its navigable, and emits it scoped to the navigable's top-level traversable. Channel functions obtained by a preload script behave identically in every realm it ran in, including realms of out-of-process iframes.

**`log.entryAdded`.** The process hosting the frame or worker reports a console message from the same `FrameConsoleClient` call sites the Web Inspector console agent uses. At the hook it serializes the arguments as remote values in the realm the message was logged from, converts the call stack into protocol stack frames, determines the realm identifier, and sends one asynchronous message; the design attributes each entry to the frame and realm that logged it. The UI process verifies the realm belongs to the sender, derives `source.context` from the frame identifier and `source.userContext` from the page, appends the entry to a bounded per-top-level-traversable buffer, and emits `log.entryAdded` scoped to that traversable. On subscribe it replays the buffered entries for the newly subscribed contexts in order. The UI process never contacts a WebContent process for a console message.

```
 WebContent (frame or worker)                                  UI process
 console.log(a, b) -> FrameConsoleClient -> AutomationInstrumentation
   serialize [a, b] in realm; stack -> frames; realm-<pid>-<n>
   ---LogEntryAdded(entry + frame / realm attribution)--->
                                                           verify realm owner; frame -> context, page -> userContext
                                                           buffer[page-X].append(entry); emit if subscribed (scope page-X)
 session.subscribe(log.entryAdded, contexts:[page-X]) ----> replay buffer[page-X]
```

---

## WebDriver BiDi: `session`

**Needs from web content:** nothing. **Routes:** the api side relays every command except `session.status` to the automation session. **Replayed:** `contextCreated` and `realmCreated` on subscribe. **Caveat:** the session's site isolation preference decides whether pages get cross-site process placement.

A BiDi session is the same object as a classic session: the WebDriver service holds the HTTP session and relays every BiDi command except `session.status` to the browser over the automation connection, and the automation session owns all state. The session's site isolation preference is applied to every page it vends; with an automation session active, the process pool performs cross-site process swaps on navigation only when the page has site isolation enabled. A session without the preference stays single-process; one with it gets real cross-site process placement. A WebContent process that hosts a page's main frame and exits abnormally ends the session, because the page can no longer be automated. A process that hosts only out-of-process frames is replaced like any other frame process, and the session reports those frames' realms as destroyed and continues.

| Command | Owner process | WebContent involvement |
|---|---|---|
| `status` | api side | none |
| `new` / `end` | api side + UI | none |
| `subscribe` / `unsubscribe` | UI (`BidiSessionAgent`) | none; replays walk UI-process objects |

`session.subscribe` records a subscription in the UI process: the event names (a module name expands to every event in it), the top-level traversables named by `contexts` (a child context names its top-level traversable), or the user contexts named by `userContexts`. Nothing is sent to any WebContent process; every process keeps reporting what happens in its frames, and the UI process consults the subscription table when it is about to emit (see [Event routing and scoping](#event-routing-and-scoping)). On subscribe it replays `browsingContext.contextCreated` for every navigable not already covered, walking its own frame tree for each page in tree order, and `script.realmCreated` for every registry realm the new subscription covers. Both replays enumerate pages once, by page identity, however many processes host a page. A subscription to a user context covers pages created later in it with no further bookkeeping, because a page's user context is derived from its data store at emission time.

---

## WebDriver BiDi: `browser`

**Needs from web content:** nothing. **Routes:** user contexts, window state and download policy are UI-process state. **Latched on the page proxy:** activity and visibility changes, fanned out. **Caveat:** user contexts are per-data-store, so processes never mix them.

| Command | Owner process | WebContent involvement |
|---|---|---|
| `close` | UI (ends the session; the embedder decides what to close) | none |
| `createUserContext` / `getUserContexts` / `removeUserContext` | UI (`BidiBrowserAgent`; a user context is an ephemeral `WebsiteDataStore`) | none; `removeUserContext` closes pages by page identity |
| `getClientWindows` / `setClientWindowState` | UI + embedder (the classic window hooks) | activity / visibility changes fanned out by the page proxy |
| `setDownloadBehavior` | UI (`DownloadProxy` decision points) | none |

A user context is an ephemeral website data store (and, where the port requires it, the web context that owns it), created in the UI process and identified by an id derived from the data store's session identifier. Pages created in it get that data store, so the network process keeps their cookies and storage apart from every other user context, and the process pool picks WebContent processes per (user context, site): no process hosts frames from two user contexts. `removeUserContext` collects the user context's pages once by page identity, closes each, and completes when every collected page has closed. The page proxy's own close path tears down every process's view of the page, so the session counts pages, not processes.

Download behavior is session state in the UI process with a per-user-context tier, consulted at the two points where the download proxy would otherwise ask the embedder. At download start, `denied` cancels it and `downloadEnd` reports `canceled`. When the destination is decided, `allowed` places the file in the destination folder without consulting the embedder. Because the download proxy is a UI-process object fed by the network process, the behavior applies identically whether the main frame, a frame in another process, or a navigation response started the download.

---

## WebDriver BiDi: `input`

**Needs from web content:** element geometry and file-list application in the element's process. **Routes:** sequencing and native injection in the UI process; site isolation input routing does the rest. **Latched:** input state, per top-level traversable, in the UI process. **Caveat:** file access must be granted to the process currently hosting the frame.

| Command / event | Owner process | WebContent involvement |
|---|---|---|
| `performActions` / `releaseActions` | UI (input queue per top-level context; `SimulatedInputDispatcher`) | element origins in the element's process; events routed as for classic Actions |
| `setFiles` | UI (grant) → the input's frame's process | sets the `FileList` and dispatches `input` / `change` |
| `fileDialogOpened` | UI (the open-panel request from any process via the page proxy) | the frame's process includes the element's shared id with the request |

**`performActions`.** Validated and sequenced entirely in the UI process: actions for one top-level traversable run one command at a time, in order, with input state kept for the life of the page. Each tick becomes native input injected at the top of the page's event pipeline, where the normal site isolation input routing applies, exactly as for classic [Actions](#actions). An `Element` origin is resolved by the process hosting the element's navigable, which reports the element's in-view center in its local root's coordinates; the UI process converts that to main-frame coordinates through the frame's ancestors. A `context` naming a child navigable contributes the same ancestor-derived offset. A shared reference never issued for the target navigable is rejected in the UI process as `no such node` before any IPC.

**`setFiles`.** The UI process validates the paths and checks the shared reference against the record issued for that navigable, grants read access to the process currently hosting the frame, and only on the grant's reply sends that process the request to replace the input's file list. The classic Element Send Keys file-upload path shares this implementation.

**`fileDialogOpened`.** Emitted when a WebContent process asks the page to show a file chooser for a frame the session controls. The frame's process includes the element's shared id with the request (minting it if the element was not serialized before), so the reference is valid for later `input.setFiles` and script commands on that navigable. The session then applies the `file` entry of the prompt-handler table; `dismiss` cancels the chooser through the result listener, which resumes the requesting frame's process.

---

## WebDriver BiDi: `storage`, `permissions`, `webExtension`

**Needs from web content:** nothing. **Routes:** all three are decided in the UI process; cookies go on to the network process. **Caveat:** origins for permissions come from the UI process, never from the asking process.

| Command | Owner process | WebContent involvement |
|---|---|---|
| `storage.getCookies` / `setCookie` / `deleteCookies` | UI → network process (`API::HTTPCookieStore` of the partition's data store) | none |
| `permissions.setPermission` | UI (override table keyed by user context, origin, permission) | none; consulted at the UI-process permission decision points |
| `webExtension.install` / `uninstall` | UI (the embedder's `WebExtensionController`) | the controller's own process management |

**Storage.** A storage partition resolves in the UI process to a user context's website data store and, where cookie partitioning applies, a partition key. A `context` partition names the top-level traversable of the given context (a child context resolves to its page) and yields that page's user context; a `storageKey` partition names a user context directly. Cookie reads and writes go to the network process through the data store's cookie store, so a partition resolves the same way whether one process or several host the named context, and a cookie set by a document in any process is visible as soon as the network process has it. The partitioned cookie reader is shared with classic [Cookies](#cookies) and the Web Inspector Storage domain.

**Permissions.** `permissions.setPermission` records an override in the UI process; `prompt` removes it. The override table is consulted, before the embedder's client, wherever WebKit decides a permission for a page the session controls: the Permissions API query path, the geolocation request path, the user-media request path, and the storage-access path. The requesting frame's origin comes from the UI process's own knowledge of the frame (its committed URL and the frame info the UI process fills in), so a cross-site iframe in its own process gets the state set for its origin and the top-level page gets the state set for its origin.

**Web extensions.** `webExtension.install` validates the extension data in the UI process, builds the extension, and loads it into the extension controller the embedder designates for the session. Content scripts, background contexts and extension pages run in WebContent processes under the controller's own process management, so an installed extension applies to every frame of every page the controller covers, whichever process hosts the frame. Ports without extension support report `unsupported operation`.

---

## WebDriver BiDi: `network`

**Needs from web content:** a sink that pauses matching loads at the request and response stages. **Routes:** observation rides the network process's per-page resource-load channel to the UI process; interception is a page-proxy authority with a sink in each WebContent process. **Replayed:** the interception config and the cache-behavior bit, to late joiners. **Caveat:** a cross-site navigation must stay one BiDi `request` across the swap.

| Command / event | Owner process | Where the work happens |
|---|---|---|
| `beforeRequestSent`, `responseStarted`, `responseCompleted`, `fetchError`, `authRequired` (observation) | UI (network agent), fed by the network process's per-page resource-load channel | network process |
| `addIntercept` / `removeIntercept` | UI (BiDi registry → the page proxy's interception authority) | config fanned out to every WebContent process of the page, replayed to late joiners; `addIntercept` replies after every process acknowledged |
| `continueRequest` / `failRequest` (request stage) | UI resolves the handle | the WebContent sink pauses at `WebLoaderStrategy::scheduleLoad` and at redirect hops; the modified request is what reaches the network process |
| `continueResponse` / `provideResponse` (response stage) | UI resolves the handle | the WebContent sink pauses at `WebResourceLoader::didReceiveResponse`; Set-Cookie writes go to the network process through the policy-respecting path |
| `continueWithAuth` | UI (the challenge proxy is the handle) | the network process holds the unanswered challenge |
| `setCacheBehavior` | UI → every WebContent process (`Page` caching reason set) | creation parameters |

**Observation.** The per-page resource-load channel is gated per automated page in the network process and is process-swap-stable: an event's `context` is the request's own navigable, cancellation is reported, and a cross-site navigation redirect is aliased by its navigation id so one BiDi `request` spans the swap. The BiDi request id joins two keys: a process-qualified `ScopedResourceLoaderIdentifier` (minted in the WebContent process, available before any network-process loader exists, and shared with the Web Inspector Network domain) and the network process's load identifier (which survives a response-time process swap). A transfer notice from the network process re-keys the former when a load moves to a new process.

**Interception** is built on the same consumer-independent primitive the Web Inspector Network domain uses (see [Shared Primitives](#shared-primitives-with-web-inspector)): a `WebPageProxy`-owned authority holding the union of every consumer's patterns with owner provenance and a per-request handle table with one exclusive resolver; a sink in each WebContent process pausing matching loads at the existing request and response stages; authentication pauses held in the network process and reporting into the same table; resolutions sent down as IPC; and one release matrix (process crash → purge; consumer disconnect → continue with the original; `removeIntercept` → already-paused loads stay paused; per-load cancel → release). The BiDi agent holds the BiDi registry (intercept id → phases, patterns, contexts) and validates per the BiDi specification; the authority holds the union. When an Inspector frontend and a BiDi session both match one request, the Inspector resolves it. Intercept handles owned by the BiDi session have no timeout, because the specification's tests block for seconds deliberately.

```
                 UI process
  BiDi network agent (registry: intercept id → phases, patterns, contexts)
       │ InterceptPattern{owner: Automation}            ProxyingNetworkAgent (Inspector)
       ▼                                                        │ InterceptPattern{owner: Inspector}
  WebPageProxy interception authority  ◀────────────────────────┘
    union config · handle table · one exclusive resolver per handle · release matrix
       │ SetNetworkInterception(config)  → every WebContent process of the page; replayed at process join
       ▼
  WebContent sink (per process)            network process
    pause at scheduleLoad / willSendRequest  (auth: unanswered challenge held here;
    pause at didReceiveResponse               handle = AuthenticationChallengeProxy in UI)
       │ NetworkInterceptionDidPause(scopedId, frame, phase, snapshot)
       ▼
  authority → owner's agent → beforeRequestSent{isBlocked:true} / responseStarted{isBlocked:true} / authRequired
  client ── continueRequest / continueResponse / provideResponse / failRequest / continueWithAuth ──► authority.resolve(handle, …)
       │ ResolveNetworkInterception(scopedId, phase, Continue{edits} | Fulfill{response} | Fail{error})
       ▼
  sink resumes the held continuation (the live continuation never leaves the WebContent process)
```

**Pause semantics.** Because the pause is in the WebContent process before the request reaches the network process, request edits are what the network process loads and caches, and a request-stage `Fulfill` is synthesized in the WebContent process so the network process never sees the load. After a response-stage decision the network process has already streamed the real body and completed, so the BiDi agent holds `responseCompleted` while a response handle is open and emits it, with the resolution's edits applied, only after the resolution. Memory-cache hits never reach the request-stage pause; the sink exposes `willIntercept(url)` and the cached-resource loader disallows caching for a URL an intercept would match (the mechanism Web Inspector already relies on), while `setCacheBehavior("bypass")` sets a page-wide, reason-tagged caching-disabled bit that is fanned out and replayed. Synchronous XHR, keepalive-after-close loads and worker loads are reported with `isBlocked: false` and never paused.

---

## Shared Primitives with Web Inspector

The primitives WebDriver and Web Inspector share (UI-side frame-tree walker, emulation store, network interception authority, composited view snapshot, partitioned cookie reader, console and realm hooks) are tabulated once in [Automation and Inspection Under Site Isolation](../SiteIsolation.md#automation-and-inspection-under-site-isolation). WebDriver-specific notes:

- **Consumers.** `browsingContext.getTree`, `contextDestroyed` and the `contextCreated` replay are the WebDriver consumers of the frame-tree walker in the design; `emulation.*`, `setViewport` and the user agent use the emulation store; `network.*` intercepts use the interception authority; `/screenshot`, `/element/{id}/screenshot`, `captureScreenshot` and recording use the view snapshot; classic cookies and `storage.*` use the cookie reader; `log.entryAdded` and `script.realmCreated` use the console and realm hooks.
- **Not shared.** Automation does not highlight, so the per-process document overlay has no WebDriver consumer.
- **Observation seams differ.** BiDi `network.*` observes from the network process (process-swap-stable load ids); the Inspector observes from per-frame WebContent proxies (scoped loader identifiers). The two keys are joined only for interception.
- **Object identity differs.** Inspector remote object ids and BiDi handles are both per frame and per process but use different serializers and lifetime rules; they are not unified.

---

## Testing

- Classic tests (`WebDriverTests/imported/w3c/webdriver/tests/classic/`) and BiDi tests (`WebDriverTests/imported/w3c/webdriver/tests/bidi/`) run through `Tools/Scripts/run-webdriver-tests`, with expectations in `WebDriverTests/TestExpectations.json`.
- A site isolation mode for the test runner (browser launched with site isolation forced on, and a site isolation expectations tag so one file stays the truth) is the prerequisite for verifying the designs above. The shared corpus is served from a single origin and never creates an out-of-process frame on its own.
- Site isolation variants to add alongside the shared corpus: `get_tree` and `context_destroyed` with a cross-site iframe; a cross-site `navigate`; cross-site `captureScreenshot` / `take_element_screenshot`; an emulation late-joiner case (set an override, then add a cross-site iframe); `remove_user_context` with a page containing a cross-site iframe; `set_files` and `set_permission` in a cross-site iframe; an element-origin action inside a cross-site iframe; cookies with the current frame set to a cross-site iframe.
- API tests (`Tools/TestWebKitAPI`) should cover the automation-specific process capture for file upload, a re-dispatched input event whose target process exits, and a session that ends with a paused intercepted load.

---

## Key Source Files

| File | Role |
|------|------|
| `Source/WebDriver/WebDriverService.cpp`, `Session.cpp` | api side: HTTP/WebSocket endpoints, handle bookkeeping, relay to the backend |
| `Source/WebKit/UIProcess/Automation/WebAutomationSession.h/.cpp` | server side: handle maps, known node references, routing, input dispatch, screenshots, navigation waits |
| `Source/WebKit/UIProcess/Automation/WebDriverBidiProcessor.*` | BiDi command dispatch and event emission gate |
| `Source/WebKit/UIProcess/Automation/Bidi{BrowsingContext,Script,Session,Browser,Storage,Permissions}Agent.*` | BiDi module agents |
| `Source/WebKit/UIProcess/Automation/BidiUserContext.*` | user contexts over `WebsiteDataStore` |
| `Source/WebKit/UIProcess/Automation/SimulatedInputDispatcher.*` | per-page input dispatcher |
| `Source/WebKit/UIProcess/Automation/Automation.json`, `protocol/Bidi*.json` | Automation and BiDi protocol definitions |
| `Source/WebKit/WebProcess/Automation/WebAutomationSessionProxy.h/.cpp/.js/.messages.in` | per-process proxy, injected atoms, node tables, realm reporting |
| `Source/WebCore/automation/AutomationInstrumentation.*` | realm, console and worker hooks beside `InspectorInstrumentation` |
| `Source/WebKit/UIProcess/WebPageProxy.cpp` | `sendWithAsyncReplyToProcessContainingFrame…`, `webPageIDInProcessForFrame`, `forEachWebContentProcess`, input re-dispatch, dialog and download hooks |
| `Source/WebKit/UIProcess/RemotePageProxy.*`, `ProvisionalPageProxy.*` | forward cross-site and provisional frame messages to the page proxy |
| `Source/WebKit/UIProcess/WebFrameProxy.*` | the authoritative frame tree |
| `Source/WebKit/UIProcess/Downloads/DownloadProxy.*` | download events and behavior |
| `Source/WebKit/NetworkProcess/NetworkResourceLoader.cpp`, `NetworkSession.*` | per-page automation resource-load observation |
| `Source/WebKit/WebProcess/Network/WebLoaderStrategy.cpp`, `WebResourceLoader.cpp`, `WebResourceInterceptController.*` | request- and response-stage pause points |
