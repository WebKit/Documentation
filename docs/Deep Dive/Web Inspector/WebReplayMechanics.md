# Web Replay Mechanics

*Brian Burg <burg@cs.washington.edu>*

----

Web replay is a new technology for low-overhead deterministic replay of web applications. This document explains how the feature is implemented in the WebKit engine, with a focus on the replay infrastructure and how it integrates with other parts of WebKit. (It does not describe the various UI integrations of replay functionality with the WebKit Web Inspector.) It is intended for consumption by other WebKit engineers and browser hackers. Where the text describes planned work or work-in-progress, the relevant Bugzilla bugs are linked.

For more background on the origins and research context of this technology, the reader should see the paper published at UIST 2013: [Interactive Record/Replay for Web Application Debugging](http://homes.cs.washington.edu/~mernst/pubs/record-replay-uist2013.pdf)

----

## Why Web Replay?

Web replay is important because it is a fundamental building block for the next generation of end-user bug reporting, performance testing, and interactive developer tools:

* By capturing a buggy execution of a web application interaction into a self-contained replayable file, an end-user can provide unambiguous, executable "reproduction steps" for an issue that they are experiencing on the client-side.

* By capturing executions of normal browsing behavior and saving them to disk, we can re-execute on new versions of WebKit to measure performance regressions in rendering real-world web applications.

* Developer tools are able to re-execute a specific execution and gather additional runtime data after the program has already run. A developer can interactively probe deeper into what exactly happened during an execution, rather than guessing about what happened and speculatively logging evidence to the console.

----

## Background

Deterministic replay is a well-established family of VM and runtime techniques for capturing and reproducing a specific execution of a program. Replay uses the observation that a program, absent any sources of non-determinism, will behave deterministically: that is, it always perform the same computations and arrive at the same result.

Deterministic replay systems manipulate sources of non-determinism so that an execution will proceed deterministically when desired. Deterministic replay actually has two phases: record and replay. During recording, non-determinism is interposed and saved into a log by some mechanism; during replaying, related mechanisms re-use the saved non-deterministic data while disabling new sources of non-determinism.

Sources of non-determinism vary by programming environment, but generally speaking, most deterministic replay systems must deal with the following sources: execution schedules (thread schedules and/or event queue schedules); the environment (filesystem, network, current time, system state, window dimensions, etc), and user (or device) input. For example, hypervisor-based deterministic replay is concerned with system calls, interrupt timings and orderings, thread schedules, and nondeterministic instructions. The web has its own set of non-deterministic sources, which will be covered below.

----

## Implementation

Web replay (feature flag: `WEB_REPLAY`) is the deterministic replay system implemented in WebKit. Its implementation strategy is adapted from approaches most commonly used by virtual machine deterministic replay systems. Its design exploits the resemblance between virtual machines and web browsers as platforms for executing untrusted, sandboxed code. By adding determinism mechanisms at the same points as in VMs, we have confidence that the technical approach will scale to all sources of non-determinism in WebKit.

Thus far, the implementation has scaled to replaying sites as complicated as Twitter (in a staging branch, [github.com/burg/replay-staging/](https://github.com/burg/replay-staging/)). However, there are still many engine features that are not yet handled correctly.

### On Web vs Browser Nondeterminism

Web replay is primarily intended for use by web developers via the Web Inspector, so we focus specifically on nondeterminism that may factor into bugs in user applications. Concretely, this means that *all JavaScript code within a specific `Page` runs in the same order and computes the same result*. Working backwards from things that transitively cause JavaScript to execute, we can also say that *DOM events, Timers, and resource loader callbacks must also run in the same order*.

Conversely, there are many sources of nondeterminism in the browser and rendering engine that do **not** cause JavaScript to run, and thus can be ignored. For example, several parts of layout and rendering are quite nondeterministic but this nondeterminism does not affect JavaScript computation. (In cases where JS needs to query layout information, script will synchronously wait for layout results.) Other irrelevant nondeterminism includes 'script-transparent' optimizations in JSC (i.e., GC and JIT), code that runs in the Web Inspector itself, and other background activities that don't cause script to run in the replayed page.

Web replay recordings may be useful for browser hackers as well (to reproduce a flaky failure or crash) but this is not the main goal of Web Replay. Projects like the `rr` library focus on whole-browser deterministic replay.

### Replay Infrastructure

Web Replay is a page-level property; the entire frame tree for a page is captured or deterministically replayed together. `ReplayController` (owned by `Page`) is the coordinator of all replay activities. Each `Document` and `JSGlobalObject` has a reference to an `InputCursor`, which represents the page's current position in the recording during capturing or playback. InputCursor is also a gatekeeper to the saved recording, allowing clients to save and load nondeterministic inputs through it. A page cannot be capturing and replaying at the same time; to enforce this, separate InputCursor subclasses exist (`CaptureInputCursor` and `ReplayInputCursor`). As documents attach and detach from frames, they start and stop contributing to the determinism captured in the overall replay recording.

Since web replay is designed to be be used from the Web Inspector, the `Replay` domain (and `ReplayAgent`) is the main API for controlling capture and replay. `ReplayController` also receives a few inspector callbacks through `ReplayAgent` (`didCommitLoad` and `will`/`didDispatchEVent`) but these could be moved elsewhere to support running web replay through an API independent of the Web Inspector.

### Replay Mechanisms

Nondeterminism of web content can be categorized into **event loop inputs** and **memoized inputs**. Event loop inputs are sources of nondeterminism that are conceptually executed sequentially in the main run loop. For example, user inputs, network callbacks, and asynchronous timers are event loop inputs. Memoized inputs are sources of nondeterminism that act as nondeterministic data sources, but are not executed themselves. For example, `Date.now()`, `document.cookie`, and most of `window.navigator` can provide nondeterministic data to executing scripts.

Web Replay uses a variety of tricks to accurately capture and replay sources of nondeterminism. The main way that we capture nondeterminism is to insert branches at control flow points that handle nondeterministic inputs. The branch checks whether the associated `Document`'s `InputCursor` is currently capturing, and if so, saves a copy of the nondeterministic data (a generated subclass of `NondeterministicInput` or `EventLoopInput`) into the active recording.

To memoize or reuse the return values of DOM APIs as they are passed to script, we have added the `Nondeterministic` IDL property that automatically generates this branch in the JS bindings. Specializations of the `MemoizedDOMResult` class are used to store this data using a ctypes-like API.

To replay nondeterministic event loop inputs, we implemented a synthetic event loop called `EventLoopInputDispatcher`, which asynchronously dispatches these inputs in order. During "real time" playback mode, the dispatcher uses observed run loop timings to simulate the user's original interactions. This dispatcher can also "pause" playback by simply not dispatching any more event loop inputs and suspending active DOM objects in replayed script contexts.

For event loop inputs, it is generally simpler and less buggy to capture and replay the nondeterminism as "early" as possible in the web content process. In the case of a mouse click, we could capture/replay at the level of DOM events, `EventHandler::handleMouse`, `WebPage::handleMouse`. However, replaying at a later point in control flow will often cause the rendering engine to be in an inconsistent state and miss important (typically non-DOM event) changes. For example, simulating DOM "click" events rather than calling `WebPage::handleMouseFoo` will cause the focus controller to miss some user inputs.

All known nondeterministic inputs are defined in JSON files, grouped by the framework (JSC, WebCore, WK2) in which the nondeterminism occurs. The CodeGeneratorReplayInputs.py script generates simple classes for each input type and input encode/decode methods for serialization.

### Testing Strategy

Testing the web replay feature requires several complementary testing strategies.

#### Automated Value Testing

Tests that exercise handling of value-oriented (as opposed to scheduling-oriented) nondeterminism are straightforward to write. A prototypical test page computes a diffable result using nondeterministic values. To detect unhandled nondeterminism a replay test library captures and subsequently replays the test page, and the test fails if the computed result differs on capturing and replaying.

 * Network replay and cookies can be exercised by http tests that return random content and/or values.
 * Random numbers, current time, and similar stateless DOM APIs are trivial.

#### Automated Schedule Testing

The nondeterminism of task ordering/scheduling (and attempts to make it deterministic for replay purposes) is inherently hard to test with confidence. The main issue is that event loop turns that cause script to execute must always run in the same order. However, we do not know all of the sources of nondeterminism, thus we don't know which event loop turns may or may not be permuted.

For example, a DOM timer may be serviced before or after an internal `Timer`, depending on non-local effects such as system load. If the Timer could cause nondeterministic effects, then it too should fire deterministically. However, if such a test were to fail, we could not conclusively say that the Timer was to blame. Other web features (which we don't yet know about) may have perturbed the schedule by adding their own nondeterministic actions into the event loop.


#### User Input Testing

For actions such as mouse, keyboard, and touch inputs, it is difficult to perform automated testing that can actually detect unhandled nondeterminism. For example, a layout test that programmatically submits mouse inputs will always be deterministic because script execution in the test page is deterministic. Testing of device input replay would have to be done using native events, such as through a TestWebKitAPI test.

For now, replay of device inputs is covered by manual tests which dump user event data (`MouseEvent`, etc) and present an easy-to-verify hash which should be the same on capture and subsequent playbacks.

### Supported Environment

ENABLE(WEB_REPLAY) is enabled by default for the Mac port. It should compile for other ports, and there is no reason why it wouldn't work for EFL/GTK. There are very few examples of platform-specific nondeterminism that is  relevant to replaying web content.

The current approach to capturing inputs requires intercept hooks in WebKit/WebKit2 or between them and WebCore. Only WebKit2 support is planned, since several important Web Inspector replay integrations are incompatible with a single-process+nested run loop execution model (details: [https://webkit.org/b/135830](https://webkit.org/b/135830)).

### Error Checking

Web browsers contain many sources of nondeterminism, and it is inevitable that we may not handle (or even know about!) all of these sources. Nevertheless, we would like to minimize the impact of missed nondeterminism, and make it easier to diagnose instances of replay divergence. To these ends, several error-checking facilities have been implemented.

We can make several assertions during capturing or deterministic playback in order to detect bugs and unhandled nondeterminism:

 * If a DOM event fires during capture/replay and we didn't capture or replay the originating event loop input, then an unhandled nondeterministic event loop input is running.
 * The number of DOM events and memoized inputs encountered per event loop input should be the same during capturing and subsequent playbacks.

In some cases, it makes sense to check for deterministic creation of specific objects (in particular, DOMTimers and ResourceLoaders). This is accomplished by saving an ordinal as a memoized input during capturing, and comparing it to the observed ordinal during playback. A discrepancy can reveal unhandled nondeterminism which caused the object initialization.

[Web Replay: detect replay divergence in number of memoized inputs used per event loop input](https://webkit.org/b/131287)

[Web Replay: detect replay divergence in number of DOM events dispatched per EventLoopInput](https://webkit.org/b/129695)

Many times, the assertions above will detect "benevolent", or harmless, nondeterminism. For example, an inconsistent number of DOM events may be fired during a playback, but if no listeners respond to the events, then the program will still execute deterministically. Right now, divergence detection is implemented as ASSERTs; it would be better in the long run to log the problem to the console and continue on a best-effort basis.

[Web Inspector: gracefully report web replay errors in the Inspector console](https://webkit.org/b/131279)

### Executions and Sessions

Because web replay is a page-level property, we must start capturing a recording at a main frame navigation. Capturing starts by performing a full refresh  to cause a navigation of the main frame. Similarly, playback begins by requesting a navigation to the same page. Originally, replay recordings could span multiple main frame navigations, forming one large recording. This is simpler to implement, but has drawbacks:

 * To replay to points near the end of the recording, all previous main frame navigations must be executed. There's no way to start replaying from the middle.
 * Passively capturing all nondeterminism (for example, whenever the inspector is open) is infeasible, as monolithic recordings can never be pruned.

To cater to these use cases, a more flexible session-based API is being pursued. A //replay segment// is a self-contained replay recording that spans between two main frame navigations. A //replay session// consists of multiple replay segments that are replayed in sequence. When main frame navigations happen during capturing, the replay infrastructure ends the current segment and appends a new one.

Because segments are self-contained, playback can begin from any segment, rather than only the start of the session. Segments can also be rearranged, added or removed independently. This supports a ring-buffer approach to passively capturing nondeterminism, where the oldest segments are pruned as new segments are added.

A significant challenge in implementing the sessions+segments approach is disentangling the interleaved execution of two main frames into two independent segments. When a main frame navigation happens, for a time there are actually two main frames running script: the outgoing document and incoming (aka provisional) document. During capturing, the replay controller must disambiguate actions between the two segments. Any persistent state necessary to start playback from the replay segment is saved as initialization inputs. This includes state such as the back-forward list and script-accessible history. During playback, main frame navigations between two replay segments do not cause interleaved execution, because segment order can change.

[Web Replay: support multi-segment replay sessions](https://webkit.org/b/131989)

[Web Replay: save and restore page history state at main frame navigations](https://webkit.org/b/131043)


### Replaying Specific Web Features

#### User interactions

User can trigger rich interactions with web pages. In all cases, these inputs (keyboard, touch, mouse, wheel, resizing, etc) come from the OS, then to WebKit/WebKit2, and then to WebCore. These are captured/replayed in `UserInputBridge`, which tees inputs during capturing and pumps saved inputs during playback (while ignoring new user inputs).

Navigations and other top-level commands can be captured in the same way as input device interactions. (History commands require additional support, see below.)

[Web Replay: capture and replay Reload, Navigate, and Stop commands](https://webkit.org/b/129447)

[Web Replay: replay history navigations originating from WK2/UIProcess](https://webkit.org/b/131084)

In the short term, we want to move capturing of user interactions directly into `WebPage.cpp` rather than using a proxy-like class. This allows replay to use fewer, higher-level inputs such as `HandleMouseEvent` (corresponding to a `WebMouseEvent`) rather than several derivatives such as separate inputs for Mouse Press/Release/Move. This refactoring is tracked by a meta-bug [https://bugs.webkit.org/showdependencytree.cgi?id=136294&hide/resolved=1](https://bugs.webkit.org/showdependencytree.cgi?id=136294&hide/resolved=1)


#### ResourceLoader callbacks

Callbacks during resource loading are nondeterministic both in their content (HTTP headers, response data) and in their scheduling. For purposes of deterministic JS execution, it is important that resource loading callbacks execute in a well-defined order on the WebProcess main thread with the same data. It is not important whether networking activity that happens before main thread processing (loading in network process, going through OS network stack) is deterministic, as long as the same main thread callbacks happen.

The current implementation (3x PFR below) intercepts callbacks inside of `ResourceLoader` class during capturing. During playback, the resource is simply not scheduled, ensuring that all loading callbacks for the resource come from replayed inputs. This design is agnostic to whether the NetworkProcess is used or not, since interception happpens after resource data is sent to WebProcess, and requests must be scheduled to be sent through NetworkProcess/platform networking libraries.

Network replay inputs consist of copied callback data and an ordinal representing the related `ResourceLoader` instance. In order to retrieve the `ResourceLoader` and simulate callbacks to it during playback, the main frame's `DocumentLoader**` maintains a mapping between resource loaders' ordinal and unique identifier. During playback, a `ResourceLoader` is obtained by doing a lookup of the ordinal and corresponding unique identifier Note that this depends on deterministic `ResourceLoader` initialization; WebCore resource loaders are initiated by WebCore itself, and depend on deterministic parsing and script execution.

Crucially, deterministic resource loading can be affected by caching in WebCore. Suppose a resource loads from network during capture, but loads from the WebCore cache during playback. In the latter case, loading the resource will cause a different series of callbacks, causing different RunLoop interleavings that leads to replay divergence.

The first patch below moves unique identifier assignment and ordinal tracking to the main frame's document loader. This was chosen as the main frame document loader closely corresponds to the extent of a `ReplaySessionSegment`. Alternatively, each document loader could store its own ordinal mapping and the replay input could also store a document index.

[Web Replay: Move createUniqueIdentifier() from ProgressTracker to DocumentLoader](https://webkit.org/b/130865)

[Web Replay: add page-level setting to bypass the MemoryCache](https://webkit.org/b/130728)

[Web Replay: capture and replay ResourceLoader callbacks](https://webkit.org/b/129391)


#### Internal WebCore nondeterminism

Timers are used throughout WebCore to do things asynchronously, which can cause nondeterministic execution of JavaScript. WebCore has many timers, but for the purposes of deterministic replay, we only care about timers that (transitively) can cause JavaScript code to execute. Timer-like behavior falls into two categories:

 * Web-facing - script can directly request asynchronous execution via `setTimeout`, `setInterval`, `requestAnimationFrame`, promises, and some other indirect mechanisms (animation/transition events). The ordering of these must be captured and simulated when replaying.

 * Internal - script can run due to nondeterminism of WebCore or the platform itself. Some examples are animation, asynchronous parsing, `Document::checkLoadComplete()`, `EventSender`, `DocumentEventQueue`.

To address implicit asynchronous nondeterminism (i.e. from WebCore's internal Timers), we create a `Timer` workalike called `ReplayableTimer`, which logs timer creation and firing when capturing execution, and is manually scheduled during replay. When neither capturing or replaying execution, the timer defers to an inner `Timer` instance.

[Web Replay: make calls into FrameLoader::checkLoadComplete() deterministic](https://webkit.org/b/129451)

Timers have a few levels of functionality: one-shot, repeating, suspendable, and DOMTimer. Each of these adds more nondeterministic functionality, such as returning the last interval or suspending when the page suspends.

The current plan is to implement `ReplayableTimer` in several phases,
culminating in supporting capture/replay of DOMTimer simply by virtue of its extending `SuspendableTimer`. Until then, we could use an alternate DOM timer replay technique that creates a `InstrumentedDOMTimer` or `DeterministicDOMTimer` during capture and replay, respectively. It would be great to land this workaround in the interim, since DOM timers are a key source of important nondeterminism in web content. Without addressing DOM timers, most replay features cannot be consistently exercised in a layout test.

### Deterministic History

History navigations can be initiated by scripts (window.history) or users (back/forward buttons). Scripts can also inspect history using the window.pushState API. Since every replay segment is independent, this history state must be serialized and restored at the start of every segment.

There is the question of what happens when navigation actions seek to previous back-forward entries. The current plan is to disable the PageCache, so any navigation of the main frame does a full load and effectively begins a new replay segment. However, instead of appending a new history item, seeking to an earlier item will prune later history items.


#### Persistent State and Environment

The browser has a lot of script-visible persistent state, which is nondeterministic across different runs, computers, time of day, etc. So, this nondeterminism must be controlled.

To address these sources of nondeterminism, we have a choice between tricking scripts into recieving deterministic results from APIs (typically by capturing and reusing memoized values), and actually restoring the engine's persistent state to what it was during the captured execution. Memoizing values is usually simpler to implement, but creates larger recordings. Dumping and restoring state requires saving a large dump of data once, rather than at each use. However, many of WebKit's persistent state stores (local storage, cookies, history) are not architected in a way to permit straightforward snapshotting and restoration. Thus, memoization-based approaches are generally preferable; this can be revisited if it causes performance issues or such inputs come to dominate recording size.

[Web Replay: make uses of localStorage/sessionStorage deterministic](https://webkit.org/b/131007)

[Web Replay: save and restore initial main frame size during capture and replay](https://webkit.org/b/131337)

[Web Replay: capture and reset initial frame active/focus states](https://webkit.org/b/129694)

#### Async Scrolling

Asynchronous scrolling is disabled whenever capturing or replaying execution.

#### Animations and Transitions

To fire animation/transition DOM events deterministically, WebCore must deoptimize to software animations when actively capturing or replaying execution. Otherwise, is not possible to precisely control animation progress on a per-tick (i.e., ) basis. The software path will be made deterministic using `ReplayableTimers` (see below).

[Web Replay: make animations deterministic during capture and replay](https://webkit.org/b/130997)

#### Workers and Message-passing

The Web Inspector does not support inspection of worker contexts, so there is no way to tell what's executing in the worker. This allows replay to simply capture and memoize the messages sent between workers and the main thread context. During playback, Workers do not need to re-execute, as long as their uses of nondeterminism can be isolated and ignored. This includes navigator, XHR network requests, DOM timers, etc. (full list here: [https://developer.mozilla.org/en-US/docs/Web/API/Web_Workers_API/Functions_and_classes_available_to_workers](https://developer.mozilla.org/en-US/docs/Web/API/Web_Workers_API/Functions_and_classes_available_to_workers))

[Web Replay: capture and replay messages from worker contexts](https://webkit.org/b/131547)

Unlike workers, for `postMessage()` between frames in the main execution context, we must replay code in each frame as well as the delivery of the postMessage from one frame to another, since it is asynchronous. This is captured/replayed similarly to a setTimeout() call.

[Web Replay: capture and replay window.postMessage and 'message' events](https://webkit.org/b/131548)

### Serialization

Web replay recordings and their inputs are serializable to JSON and are only accessible from the WebProcess main thread. In code, recordings are implemented by the `ReplaySession` class, and are segmented into multiple `ReplaySessionSegments`. Each segment begins at a main frame navigation.

Each framework (JSC, WebCore) defines its own replay inputs and encode/decode methods. The top-level recording encode/decode methods will soon move to WebKit2 so that inputs defined in WK2 can be encoded/decoded.

[Web Replay: encode replay inputs through ReplayClient](https://webkit.org/b/140448)

[Web Replay: use framework prefixes for framework-specific replay input code](https://webkit.org/b/140447)

[Web Replay: support generating replay inputs for WebKit framework](https://webkit.org/b/140446)

Recordings are serialized to JSON as nested objects. This is accomplished using a variant of WK2's `KeyedCoder` interface called `EncodedValue`. The main differences between the two are:

#### EncodedValue assumes that encode/decode methods use public class methods

Why? Specializations of the `EncodingTraits<T>` struct implement standalone encode/decode methods for every `NondeterministicInput` subclass and other WebCore types such as `ResourceResponse`, `FormData`, etc. Originally, this was done to avoid painful rebases/merges with fundamental WebCore classes like `ResourceResponse`; it has stayed this way because the maintenance burden is low.

#### EncodedValue supports 1-1 correspondence between encoded/decoded objects.

Why? In the past, we found a stack-based encoder/decoder context makes it very hard to automatically generate serialization code. In particular, WebCore objects that must be stored in a vector or as a key's value in different decode methods are tricky to write because the "current context" is managed by multiple methods.

The current API is based on mirrors (a design concept from reflection APIs) and is very straightfoward: `EncodingTraits<T>::encode(T)` produces an `EncodedValue` for the argument, and `EncodingTraits<T>::decode(EncodedValue, T&)` produces a `T` (shared or owned) in the outparam. Encode/decode methods for inputs can uniformly call encode/decode on any member data type with an EncodingTraits specialization and get back an EncodedValue.

#### EncodedValue serializes objects to JSON, not to a byte buffer.

Why? This allows the inspector frontend and on-disk recordings to share a common file format and structure. Using `String` keys and values also makes its possible to have some backwards compatibility for free. For example, the recording format does not depend on the order or representation of enum values, because it stores the symbolic enum value names as strings. `EncodedValue` encoders and decoders reuse the JSON parsing and generation provided by `InspectorValue` subclasses.
