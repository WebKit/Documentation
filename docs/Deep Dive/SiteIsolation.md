# Site Isolation

In the simplest case of loading a document with no iframes and no popups, we have a WebPageProxy and one WebProcess, one Page in that process, and that Page has one Frame that is a LocalFrame like this:

![Frame Diagram 1](/assets/FrameDiagram1.png)

If that document has 2 iframes loaded from the same site, then the Frames are arranged in a FrameTree structure like this:

![Frame Diagram 2](/assets/FrameDiagram2.png)

With site isolation off, if example.com loaded an iframe from a different site like a.com, then we would load it in the same process:

![Frame Diagram 3](/assets/FrameDiagram3.png)

With site isolation on, though, we put the content from a.com into a different process than the content from example.com

![Frame Diagram 4](/assets/FrameDiagram4.png)

## RemoteFrame
A RemoteFrame is used to indicate a position in the FrameTree that has a Frame that has a Document in a different process.  This is needed because JavaScript can traverse the FrameTree even when it can’t access the DOM in a third-party Frame.  The process that has the main frame at the top of the FrameTree as a LocalFrame communicates via IPC with the WebPageProxy, but all other processes have a RemoteFrame at the top of the FrameTree and they communicate directly with a RemotePageProxy, which mostly just relays messages to the WebPageProxy.

If the main frame calls window.open(‘https://b.com') then we need to have 3 processes:

![Frame Diagram 5](/assets/FrameDiagram5.png)

Each process needs to have the entire representation of the FrameTree because JavaScript has the ability to traverse the FrameTree by using properties like window.parent.opener.frames[1] and if it finds a Frame of the right origin it can access its DOM.

## BrowsingContextGroup
A BrowsingContextGroup represents all the WebPageProxy objects that may be connected with opener relationships and all the processes they are currently using for their content.  When a Frame navigates to a new domain, then the entire forest of FrameTrees needs to be recreated in the new process.  Also, when a new WebPageProxy is created by a call to window.open, then all the existing processes need to be notified that a new Page was created with a main Frame.

## DocumentSyncData
The existence of Frames is not the only thing that needs to have updates broadcast to all processes.  Certain properties, such as the Frame name (which can be used as the second parameter of window.open to reuse a frame instead of making a new WebPageProxy) need to also be kept up to date as well as possible in all processes.  Sending synchronous IPC for updates would keep things the most synchronized, but the browser would quickly become unresponsive.  Instead, we broadcast updates to each process while keeping the UI process as the source of truth that is either the same as the state in each web content process or the web content process is about to receive a message with an update.  That’s what DocumentSyncData is.  It is a set of properties that we try to keep as up to date as possible in all processes.

## Main and Root Frames
Each Frame has a main Frame, which is the Frame at the top of the FrameTree in that process.  Not every frame has a LocalFrame as its main Frame.  Sometimes, for purposes such as render layer tree transactions, we want the collection of LocalFrames that are at the top of their local FrameTree.  These are LocalFrames that either have no parent (in the process that has the main frame) or LocalFrames that have a RemoteFrame as a parent.  Page::rootFrames is how we quickly access these “root” frames.  See this deep FrameTree example.  The main frame is at example.com, and it has 2 iframes, one at example.com and one at a.com, and each iframe has a grandchild iframe with the opposite site:

![Frame Diagram 6](/assets/FrameDiagram6.png)

## Site
Site isolation puts content from different Sites into different processes.  A Site is the protocol and eTLD+1 (RegistrableDomain) of the domain.  For example, http://example.com and https://example.com would be in different processes.  https://www.example.com and https://blog.example.com and https://example.com would all be in the same process.  http://example.co.uk and http://blog.example.co.uk would also be in the same process.

## FrameProcess
If web content has many iframes in different processes, then the main frame removes all its iframes using JavaScript like iframe.parentNode.removeChild(iframe), we want to stop using all the now-unused processes.  FrameProcess exists to keep track of which frames are using which processes with site isolation.  Once a FrameProcess is destroyed, the WebProcessProxy it represents is either terminated or put in the WebProcessCache.  The FrameProcess destruction means the BrowsingContextGroup is no longer keeping track of the web content process, but because the WebProcessProxy may be reused by the WebProcessCache the FrameProcess and WebProcessProxy need separate lifetimes.

## Provisional Navigation
A frame can have local presence in multiple processes at the same time for a short amount of time during navigation.  When an iframe navigates from a.com to b.com, it creates a ProvisionalFrameProxy which owns a FrameProcess for b.com.  Inside the b.com process, the corresponding WebFrame will make a LocalFrame and own it with m_provisionalFrame instead of putting it in the FrameTree until the response is received from the network.  This is needed because if postMessage is called in the b.com process to send a message to the frame that is navigating, we will want to use the RemoteFrame for delivery of that message, not the LocalFrame which isn't in the tree yet.  Also, if the provisional load fails, such as if the TCP connection is lost before receiving a response, we can discard the provisional frame and have the frame trees be unaltered.  When the response is received successfully, the RemoteFrame will be replaced by the LocalFrame in the FrameTree in the b.com process and a message will be sent to the a.com process telling it to replace its LocalFrame with a RemoteFrame because the frame is showing content from b.com now.  When the main frame navigates, we use a ProvisionalPageProxy instead of a ProvisionalFrameProxy.

Before navigation:
![Frame Diagram 7](/assets/FrameDiagram7.png)
Between request sent and response received:
![Frame Diagram 8](/assets/FrameDiagram8.png)
Immediately after b.com process is informed of response received:
![Frame Diagram 9](/assets/FrameDiagram9.png)
After IPC notifies other processes that response was received in b.com process:
![Frame Diagram 10](/assets/FrameDiagram10.png)

## New Communication Channels
To get from a WebCore::Page to the WebKit::WebPage that wraps it, you can go through the ChromeClient.  To get from a WebCore::LocalFrame to the WebKit::WebFrame that wraps it, you can go through the FrameLoaderClient.  To get from a WebCore::RemoteFrame to the WebKit::WebFrame that wraps it, we added RemoteFrameClient.  To send a message to all web content processes, use WebPageProxy::forEachWebContentProcess.  To send a message to a specific web content process, use WebPageProxy::sendToProcessContainingFrame

## Tests
We currently have about 90k layout tests which have relatively good code coverage to verify that each feature of WebKit works as desired.  We introduced a special mode to WebKitTestRunner that can be accessed by adding the --site-isolation flag to run-webkit-tests for running tests for reusing these tests to get as much coverage as possible specific to site isolation.  When using this flag, we run the test in a cross-site iframe with site isolation off, gather any output the test emits, then run the same test in a cross-site iframe with site isolation on, and compare the output.  If the output is different, it usually indicates something we haven’t yet implemented for site isolation.  Some tests don’t complete when run in a cross-site iframe, and these tests aren’t helpful in this mode, but most do complete and are useful.  We have a test expectations file at LayoutTests/platform/mac-site-isolation/TestExpectations and a bot running these tests that you can see by going to results.webkit.org then clicking “Suites” at the top then “Flavor” on the bottom right and turning on site-isolation.  We also have API tests that you can run with “run-webkit-tests SiteIsolation -v —no-build” and some layout tests written specifically to test interesting cases of site isolation in LayoutTests/http/tests/site-isolation.

## Finding what needs to be done
Site isolation was originally planned as a simple 3 step project:
1. Put frames from each Site into their own process
2. Fix the functionality broken by step 1
3. Fix the performance regression from step 2
As of October 2026 we are currently on step 2 and looking forward to step 3.  In order to get there, we need to fix all subtasks of rdar://99665363 which is organized from a code-centric perspective.  QA has also been helping find things to fix from a user-centric perspective, and they are subtasks of rdar://138794978.  Those that don't have access to radar can reach out on the WebKit Slack.

## Automation and Inspection Under Site Isolation

Web Inspector and WebDriver (classic and BiDi) both observe and control a page from outside
the web content. Before site isolation, each talked to a single WebContent process that held
the whole page. With content split across processes, both were redesigned around the same five
rules below. This section is the one shared model; the client-specific designs are in
[Web Inspector and Site Isolation](Web%20Inspector/SiteIsolationExplainer.md) and
[WebDriver and Site Isolation](WebDriver/SiteIsolation.md).

**1. The UI process is the authority.** Every identifier a client sees (an inspector target
id, a WebDriver page or frame handle, a BiDi browsing-context or navigation id) is minted in
the UI process from an object that outlives any single WebContent process (`WebPageProxy`,
`WebFrameProxy`, `API::Navigation`). Frame identifiers are process-qualified, so they have the
same value in every process. A subframe keeps its identifier when it navigates cross-site in
place; a main-frame swap gives the page a new main-frame identifier, and the clients treat that
as a new document. Session state (subscriptions, overrides, user contexts, the record of which
element handles have been issued) lives in the UI process, keyed by UI-process identities.

**2. Per-frame targets for document data; process-level aggregation for page-wide data.** Data
produced by a document or a JavaScript VM (console messages, execution contexts, DOM, styles,
breakpoints, realms, element handles) is owned by the process hosting that frame and is
reported on a per-frame channel: an inspector frame target (`FrameInspectorController`) or a
frame-routed automation command. Data that only the UI process can assemble (a page-wide frame
tree, a request-to-process map, a sum over processes) is produced by a UI-process agent that
fans a scoped request out to each hosting process and merges the replies. The Inspector calls
these [octopus agents](Web%20Inspector/SiteIsolationExplainer.md#octopus-domains-network-and-page)
(`ProxyingNetworkAgent`, `ProxyingPageAgent`). Data the UI process can read from an
authoritative store (cookies, in the network process) is served with no WebContent involvement
at all.

```
                                  UI process
   ┌───────────────────────────────────────────────────────────────────────────┐
   │ WebPageProxy ── WebFrameProxy tree (authoritative)                        │
   │ ├ WebPageInspectorController: targets, Proxying agents, Storage, Browser  │
   │ ├ WebAutomationSession + BiDi agents: handles, realms, overrides,         │
   │ │   subscriptions, input state                                            │
   │ └ page-proxy-owned shared state: interception authority,                  │
   │     emulation override store                                              │
   └─────────────┬───────────────────────┬───────────────────────┬─────────────┘
                 │ frame-routed, async   │ cookies, loads
                 ▼                       ▼                       ▼
   ┌────────────────────┐    ┌────────────────────┐    ┌────────────────────┐
   │ WebContent A       │    │ WebContent B       │    │ Network process    │
   │ main frame         │    │ cross-site frame   │    │ HTTPCookieStore    │
   │ FrameInspector-    │    │ FrameInspector-    │    │ per-page load      │
   │  Controller ×n     │    │  Controller ×n     │    │  observation       │
   │ per-frame proxies  │    │ per-frame proxies  │    │                    │
   │ WebAutomation-     │    │ WebAutomation-     │    │                    │
   │  SessionProxy      │    │  SessionProxy      │    │                    │
   │ emulation sink,    │    │ emulation sink,    │    │                    │
   │  interception sink │    │  interception sink │    │                    │
   └────────────────────┘    └────────────────────┘    └────────────────────┘
```

**3. Commands go to the process that hosts the frame; page-wide state fans out and is
replayed.** A command that needs a frame's content is sent to the process hosting that frame
with the page identifier valid in that process (`WebPageProxy::sendWithAsyncReplyToProcessContainingFrame`
plus `webPageIDInProcessForFrame`). Page-wide configuration (an emulated media feature, a user
agent, an interception pattern) is latched on the page proxy, fanned out
with `WebPageProxy::forEachWebContentProcess`, and replayed to every process that joins the page
later: the main-frame process after a swap and a new cross-site frame's process at creation
(`WebPageCreationParameters`). Inspector network settings (extra HTTP headers, caching disabled)
are latched on the octopus `ProxyingNetworkAgent` instead, and replayed when it calls
`enableInstrumentationForProcess` for a joining process. Anything that only does the first half is wrong under site
isolation. Geometry crosses processes in two steps: the frame's process converts up to its
local root, and the UI process, which alone knows the whole tree, finishes the conversion to
main-frame coordinates.

**4. Asynchronous IPC only, and events arrive process-agnostically.** Automation and
inspector code never makes the UI process block on a WebContent process. Automation and inspector messages are asynchronous, with
one exception: the WebContent-to-UI known-element-reference check (`IsKnownNodeReference`),
which the design replaces with a UI-side remap (see [WebDriver and Site Isolation](WebDriver/SiteIsolation.md#element-references-shadow-roots-and-window-references)). Events are produced by
whichever process hosts the frame and reach the page proxy through the same handlers whether
they come from the main-frame process, a `RemotePageProxy`, or a `ProvisionalPageProxy`, so the
UI-process hooks that turn them into protocol events do not know or care which process sent
them. WebDriver BiDi subscriptions are consulted in the UI process at emission time and never
fan out. Enabling an Inspector domain does fan out: the octopus agents send
`EnableNetworkInstrumentation` / `EnablePageInstrumentation` to every WebContent process (and
to each process that joins later), so frame-side instrumentation exists only while the domain
is enabled.

**5. Shared primitives, built once.** Five pieces of UI-process machinery are consumed by both
clients and must not be duplicated:

| Primitive | Owner | Inspector consumer | WebDriver consumer |
|---|---|---|---|
| UI-side frame-tree walker over `WebFrameProxy` | UI process | `Page.getResourceTree` | BiDi `browsingContext.getTree`, context lifecycle events |
| Emulation / page-configuration store: resolved once per page, one `WebPage` sink per process, replayed to late joiners; last writer wins at the sink | `WebPageProxy` | `Page` override commands | BiDi `emulation.*`, viewport, user agent |
| Network interception authority (union of every consumer's patterns, one exclusive resolver per paused request, release matrix) with a pause sink in each WebContent process; the Inspector resolves a request both clients match | `WebPageProxy` + each WebContent process | `Network.*Intercept*` | BiDi `network.*` |
| Composited UI-process view snapshot, clipped to a rectangle computed in the target frame's process | UI process | `Page.snapshotNode` / `snapshotRect`, Timeline screenshots | classic and BiDi screenshots, recording |
| Partitioned cookie reader over `API::HTTPCookieStore`, served from the network process without touching any WebContent process | UI process | `Storage` domain | classic cookie commands, BiDi `storage.*` |

The implementation status of each primitive is tracked per domain in the Web Inspector page's status tables: [Status and Migration Plan](Web%20Inspector/SiteIsolationExplainer.md#status-and-migration-plan).

### Web Inspector

With content split across WebContent processes, the inspector observes and aggregates protocol
data from each process. It reuses the existing inspector target multiplexing mechanism
(`InspectorTargetAgent`) to create a frame target per frame, each connected to a
`FrameInspectorController` in its WebContent process. Document-scoped domains (Console,
Runtime, Debugger, DOM, CSS, DOMStorage, Worker, and others as they migrate) are served by
per-frame agents on those targets. Page-wide domains run in the UI process: Network and Page
aggregate over per-frame proxies in each process, and Storage reads the authoritative cookie
store directly. Details, per-domain status and the migration plan:
[Web Inspector and Site Isolation](Web%20Inspector/SiteIsolationExplainer.md).

### WebDriver

The WebDriver server side (`WebAutomationSession` and the BiDi agents) already lived in the UI
process, so site isolation mostly moved the last process-local assumptions up to the UI process
or down to the frame's own process. Frame-scoped commands are routed to the process hosting
the frame; pointer input is hit-tested in the main-frame process and re-dispatched by the UI
process to the target frame's process; cookies, screenshots and the frame tree are answered
from the UI process; realms, element handles and log entries are minted in the hosting process
and recorded in the UI process. Per-endpoint and per-module designs:
[WebDriver and Site Isolation](WebDriver/SiteIsolation.md).

## Strategies for fixing bugs
Most of the functionality bugs remaining can be described as “we used to follow a pointer to another frame and now we can’t.”  A handful of strategies continue to be quite effective.  The first is maybe we can refactor the code to send a message to the frame via IPC instead of calling a function and operating on the frame directly when we need to do something.  The second is maybe see if we can proactively send state to all processes so when they need to do something they already have the necessary information.  This should only be done with information that is not sensitive because it creates a side channel for speculative execution attacks to read information other sites should not have access to.  The third is maybe we can do something in a privileged process such as the UI process or the GPU process that doesn’t have web content in it but can communicate and know state from multiple sites.  And the fourth is maybe it is correct to do nothing if a frame is in another process.  This last option is rare, but sometimes if access is gated on an origin check it is correct to skip a frame in another process.
