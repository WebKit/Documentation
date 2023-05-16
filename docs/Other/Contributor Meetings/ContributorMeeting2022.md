# WebKit Contributor Meeting 2022

WebKit Contributors Meeting November 9-10, 2022

## Schedule

### Wednesday Sessions

| Talks |
| ----- |
| WebKit 2022-2023 by Eric Meyer |
| Sony WebKit 2023 Priorities by Don Olmstead |
| Site Isolation by Alex Christensen |
| What’s new in LFC/IFC by Alan Baradlay |
| Status of the new Layer-Based SVG Engine by Nikolas Zimmerman |


### Thursday Sessions

| Talks |
| ----- |
| Standards Positions by Anne van Kesteren |
| Apple Goals for WebKit (cancelled) |
| WebCodecs by Youenn Fablet |
| State of WebKit SCM by Jonathan Bedard |
| WPE WebKit for Android by Jani Hautakangas |
| JavaScript Precompiled Bytecode Evaluation by Basuke Suzuki |
| clang-tidy on JSC by Mikhail R. Gadelha |
| Interop 2022/2023 by Jen Simmons |
| WebDriver by Patrick Angle |
| Bringing the GPU Process to macOS by Simon Fraser |
| Improving Contributor Onramps by Jon Davis |


## Talks

### Wednesday

#### WebKit 2022-2023 (Igalia)

##### Notes

- Igalia is a distributed company of 128 people, focused on open source
- 8 main areas ranging from browsers to the cloud. Focused on all kinds of appliances and devices that use the web
- Investing this year in the Wolvic VR browser
- Mostly focused though on Linux and Android devices
- Moving to 2022 in review
- In 2021, about 16% of WebKit contributions were from Igalia, 77% from Apple, 4% from Sony
- In 2022, about 13% from Igalia, 79% from Apple, 3% from Sony
- But the other slice went from 2% to 4%, so more individual contributors
- A lot of Igalia's contributions came from WPE WebKit
- Got Angle enabled on dev branch
- Started working on GPU process and WebGPU, require some buffer sharing tech to work
- Refactoring scrolling code to make scrolling smoother, in WPE and GTK
- Analysis of animation frame vsync
- Upstreamed GStreamer backend for WebRTC
- Upstreamed work for MSE and EME
- Working on cloud gaming for WebRTC
- One of Igalia's biggest areas of work is WPE for Android
- Driven by having so many embedded devices running Android
- Completed Android WebView compat for a subset of APIs, hardware acceleration for media playback (decoding only, not encoding), PSON (important for security), fullscreen support, 64-bit ARM target support, lots of refactoring
- JavaScriptCore work: off-thread compilation, 32-bit platform-related work including WASM signaling memory
- Web Platform work: GamePad API (for a customer that wants to support gaming on embedded device), HTML interactive form validation, Layer-Based SVG engine, WebSpeech API (still in progress), :focus-visible, ARIA attribute reflection
- QA work: 2 new Ubuntu 22 bots, new bot to build with clang, Raspberry Pi bot
- Interop 2022 (cross-browser project with focus areas for improving interop): as of Mon Nov 7, Safari is on top (after starting the year at the bottom). All browsers have significantly improved over the year, from ~60% to ~80%. Many contributions, not just from Igalia
- Interop 2022 work: cascade layers, form elements, scrolling, subgrid tests
- Moving to Plans for 2023
- WPE for Android: keep updated with latest WPE WebKit (should be straightforward); implement missing APIs; support for WebDriver, WebInspector, WebXR; bug fixes and performance improvements (important for embedded devices, esp. low energy)
- Graphics: perf improvements for 2d rendering (requested by clients, who want smooth interfaces on touchscreens, show videos during setup, etc.); WebGL2 support; GPU process on top of ANGLE; fix issues that hurt correct results for WPE on benchmarks; speculative plans for Vulkan and WebGPU support
- Multimedia: WebRTC GStreamer backend; improve MSE eviction algorithm to be more aggressive; video PIP support (depending on GPU process progress); media playback using playbin3
- JavaScriptCore: support FTL tier for 32 bit; support LOL JIT tier on 32-bit; port JSC to RISC-V; investigate runtime sanitizer for PAC failures on ARM64e; temporal API support -- working on cross-browser spec
- 12:30 PMWeb platform: upstreaming layer-based SVG engine (historically, SVG and MathML have been their own rendering engine, want to unify with HTML); WebSpeech AP and ImageBitmap for GTK + WPE (useful for embedded devices); DeviceOrientation for WPE port (good for handheld devices); WebXR implementation (depending on test infra)
- Fully support a11y on GTK4; HTTP/3; WebExtensions API
- QA: improve support for Flatpak on ARMv7 and ARM64; WebKitGTK/WPE in OSS-Fuzz; WebKitSearch build bot; WPE security bot

##### Q&A

- Q from Geoff: about the layer-based SVG engine, what got Igalia interested in this work?
- A from Brian: We did a podcast on this. Original creators of KSVG are Igalians, they know all the warts. Will share a link to podcast in Slack. Important for embedded devices for efficiency and enables things that would not otherwise be possible
- https://www.igalia.com/chats/Igalia-Chats-Niko-SVG-WPE
- A from Niko: You'll hear more soon. Igalia is interested to reduce paint time, esp on low-end CPUs. We are doing painting on software, so if you can do more hardware-accelerated then you win, esp on embedded devices
- Q from Tim: Activity from Igalia on content-visibility and similar properties. Why is Igalia interested?
- A from Brian: Don't have an answer as to why it's interesting. It is :slightly_smiling_face:
- A from Cathie: content-visibility is good for performance and provide many ways developers can decide which parts has the priority to render or skip rendering
- Q from Jonathan: How are we going to make sure we don't break build for another platform?
- Q from Simon: What about WebXR + GPU process combined? We at Apple think some WebXR code has to run in GPU process (edited) 
- A from Brian: I think that rings true to me
- A from Alex: Still in early stages so not sure, but yeah we want to try to do it in the GPU process

#### Sony WebKit 2023 Priorities

##### Notes

- Two year anniversary of PS5
- Use WebKit for Media apps
- Game developers use as library
- Plans encompass 1-5 years
- WinCairo Port
    - Remove WebKitLegacy support
        - Held back by testing
        - Need to update test configuration
- Network Backend
    - Add HTTP/3 support to cURL backend
    - Movement within cURL to support this
    - Not completely working
        - Some preliminary work done, eg displaying requests in Web Inspector
- Looking into cURL WebSockets API
- JavaScriptCore
    - Aim to reduce startup time
    - Leverage byte code
- To be expanded in future presentation
- Temporal API
- Record & Tuple
- WPE PlayStation Backend
    - Joint efforts with Igalia
    - Working on using WPE renderer
    - Media support
    - Gamepad support
- Media
    - Historically PlayStation specific code not upstreamed, interest in improving this
    - MSE
    - Ideas about a "Media tab" in Web Inspector
- GPU Process
- Called "Web Compositor"
    - Async composition
    - Async scrolling
    - Video rendering
- Want to enable for PlayStation, currently enabled in Windows build
- WebGPU
    - Get Dawn + WebGPU working
    - Port Dawn on PlayStation hardware
    - Dawn is Google's equivalent of ANGLE
- Modern 2D rendering
    - Fixing TextureMapper bugs
    - Experimented with using WebGPU API for TextureMapper
        - As opposed to GL
        - Speed improvement

##### Q&A

- Q from Alex: Asked about WebGPU prototype wrt Cairo port?
- A: Being experimented with, not necessarily final plan.


#### Site Isolation

Site isolation is the next step to make browsers more secure, and its implementation is a major architecture shift.

##### Notes

- Old days: single process browser / WebKitLegacy
    - Stability: one tab crashes, everything crashes
    - Security: no sandboxing
    - Perf: one thread should be enough for 10 websites
    - Responsiveness: that one thread will never hang right?
        - iOS 1.0 introduced WebThread
- Current multiprocess architecture / WebKit2
    - Multiple tightly sandboxed web content processes
    - Network/storage process
    - GPU process
    - UI process
- Partitioned Storage
    - IndexedDB / caches / other persistent storage is partitioned by origin
    - If a.com and b.com both embed example.com, example.com's cached data is stored separately in a.com and b.com's partitions respectively
- Why site isolation?
    - Meltdown/Spectre vulnerabilities: JS can now read arbitrary data
    - Partial mitigations:
    - Cross-Origin-Embedder-Policy, Cross-Origin-OpenerPolicy
    - Disabling SharedArrayBuffer and performance.now's precision
    - Exploit read/write/execute gadgets can send rogue messages; what can it reach?
- Data isolation: already in open source
    - Check if firstPartyForCookies is reasonable before allowing access to cookies
    - window.open can still put multiple first parties in the same process
- Site isolation
    - Put cross-origin iframes in different process than its parent
    - Each process can read only one partition of data; ideally the partition is never a message parameter
    - Spectre attacks can't read anything interesting
- New cross-origin iframe loading flow
    - decidePolicyForNavigationAction - tell old process navigation will likely continue in new process
    - when navigation commits, tell old process that happened, switch from LocalFrame to RemoteFrame in frame tree
    - When loading completes in new process, tell old process that happened, then on-load can fire
    - Make all FrameTree traversal use IPC to pull or push info
- Other things to consider
    - Drawing to the screen/compositing
    - Accessibility tree needs to know about out-of-process iframes
    - Perf - processes aren't free
    - Web inspector - needs to be able to introspect out-of-process state
    - Printing with cross-origin iframes
    - Anything related to frames, must audit at least 200 uses of frames
- Injected bundles: many APIs do not work with out-of-process iframes
    - InjectedBundlePagePolicyClient: allows you to navigate without even asking the UI client
    - WKBundleFrameCopyChildFrames: API has to be removed or changed, can't return a copy of all frames in the same way in an isolated world

##### Q&A

- Q from Jean-Yves: What is the estimated timeline to finish this? Past experience shows that it will take a very long time to complete.
- A: We know it's a large effort and will take more than one year.
- Q from Cameron: Other browsers have decided that on mobile devices it's not practical to have a process per origin due to perf constraints. Would WebKit be subject to the same limitations?
- A: We are aware of this and we'll have to measure the overhead to help make that decision. We are still in the early stages of just getting something that works. (edited) 
- Q from Brian Kardell: WebKit was among the first to do partitioned storage. Were there a lot of issues opened during the timeframe when that feature was introduced?
- A from Alex: There are cross-origin communication channels available in the web standard. We decided that we don't want to make it easy to do cross-origin tracking in WebKit for privacy purposes, even though there are some legit uses of that tracking.
- A from John: the privacy boundary for partitioned storage is site not origin. Originally when implementing storage partitions, we we also wanted to partition cookies but there was too much breakage. Took until 2017 to implement partitioned cookies and took until this year for a web standard to address this issue.

#### What’s new in LFC

Inline and flex layout features added throughout the year to LFC -aka how much WebKit’s line layout has progressed.

##### Notes

- LFC, quick recap
    - Layout formatting context
    - Initiative to reimplement and redesign WebKit's render engine (similar to Blink's layout ng work)
    - Focusing on Inline Formatting Context and Flex Formatting Context
- IFC
    - Webkit maintains 2 inline layout implementations that are independent of each other (legacy and modern)
    - Legacy is always enabled and modern is behind a runtime flag
    - Has been enabled in Safari for many years now
    - When both are enabled, we have to make a certain decision during layout whether to use modern or legacy
    - Decision is made at the block level to determine if IFC can handle the content
- Example
    - The second block container has to use legacy since the block has a property that is not supported by IFC
- How much content is going through IFC as of 10/8 trunk
    - Some text heavy pages use IFC 100% and does not use legacy at all
    - Some other pages the coverage value can drop to under 50%
    - line-clamp is one offender that causes the % to drop
- IFC, progressions
    - WPT with IFC disabled there are many tests that fail
    - Even some older bug reports get fixed with IFC enabled
- IFC, expanding coverage, what's new
    - Keep adding new features to IFC to bring it up to same level as legacy so that we can remove it
    - Many progressions with BiDi content using IFC
    - When working on inline layout, you do not have to care about line orientations since everything works with logical dimensions
    - Traditionally WebKit has a preferred width code path that basically runs layout twice
    - These 2 codepaths can come back with different values which can result in unexpected overflow or line breaking
    - New floating layout should hopefully be easily to understand and maintain
- FFC, the new flex layout implementation
    - Rewriting flex layout based on LFC design principles
    - Not currently enabled because we need to do integration work
    - Need ways to integrate with existing render tree architecture

#### Status of the new Layer-Based SVG Engine

A closer look at the status of the Layer-Based SVG Engine in WebKit.

##### Notes

- based in Germany - started contributing to KHTML in 2001, co-founded ksvg with Rob Buis (also an Igalian) and moved on as it moved into webkit
- been working exclusively in webkit for some time
- What is LBSE? The layout based SVG engine we’ve been developing at Igalia in WebKit since 2019
- aimed at resolving architectural issues present for 15+ years
- Allows us to use hardware acceleration and features of CSS that are useful
- POC patch in October 2021 passed all existing tests, pixel perfect
- performance was comparable to legacy engine in motion mark - some tests were way faster, some were slower… but in principle we proved it is possible and not a perf issue
- how is it achieved? coordinating system decisions in the redesign with CSS, reuse as much code as possible in RenderLayer without SVG specific changes
- evolution since 2021: the “final” version of the prototype was a drop in replacement for the old SVG engine, but it was not a way to upstream it - it would be a huge patch.  It is all or nothing, there is no way to merge parts - too big a change at once
- we developed an upstreaming plan to evolve this and land pieves in atomic pieces, all of the code is behind a compile time flag
- Unfortunately this means a lot of manual rework, basically equivalent to yet another rewrite… but..
- there is a master bug report 90738 “Harmonize HTML and SVG Rendering”
- 89 patches landed, 75% upstream
- we started adding runtime flags in November last year
- and it wasn’t until January this year we were beginning into real foundations
- along the way some interesting and important upstream bugs were fixed - some about a decade old, perspective should not be affected by transform-origin
- by the end of April we were on to SVG text
- then we added all of the basic shapes, then viewbox, then compositing - this also fixed a 10+ year old bug about upscaling an object via css transforms
- (that brings us through July)
- in august we activated support for ‘defs’ and foreign objects and image elements and activated remaining shapes (polyline, polygon, line)
- in September we fixed some bigs about compositing and device pixels alignment and pixel snapping when elements are composited
- we activated sub-pixel precision for render tree dumps
- very recently (in October) the size negotiation for <object> + RenderSVGRoot, fixed SVGImage container size propagations , assured HTML documents create a new formatting context - also fixes a 15+ year old bug!
- panning and zooming was enabled, there is 1 important interop deviation we need to look into.
- we fixed transform support for svg <text> elements
- so… where do we stand now?
- when we said 75%, most of the core layout is upstreamed… All the render layer, etc.  So, roughly 95% of it is done - there is a patch pending review to fix wrong answers to some DOM APIs - will fix a number of issues
- once this is bug we can go back to the list of open bugs, we are missing patterns, gradients, masking, I think we will have a patch in the next few weeks - some of this is solved downstream
- that is the short term list - but the long term plan involves more performance work and making sure that all of the layout test pass
- There are optimization that we can do to make it faster, we will be dealing with adding those to reduce the overhead and only construct layers if necessary and show that it is not then a massive overhead
- while we said we are 75% completed, we believe that we can hit the goal in 2023 and show it complete and fast
- (showing some video/demos)
- (key here is looking at cpu use and timing is really improved)
- (room gasps audibly, but they are all muted)
- (shows smooth 3d transformation possible with lbse vs vanilla safari with good performance and even panning and zooming while it is happening)
- (shows many individual transforms on individual parts in 3d)
- (there is no flashing or flickering, it’s very smooth)
- (shows the layers - wow there are a lot)
- (242 layers…. you can inspect them to see which parts.. and we are now enabling the compositing / repaint and you can see that we are not increasing the painting count for these objects. You can see that sometimes the count changes because we occasionally do need to repaint, but it is only on a small portion of the image)
- (comparing to the old implementation - there are 0 layers, we are just repainting the whole document every time - and it is less capable too)
- we need to find a tradeoff and conditions which just traverse the render tree and children and don’t create all the layers - to reduce the layers when they are not necessary - and then we can really have the best of all worlds
There is another demo, but I ran long so I will just share the link and you can watch it yourself

##### Q&A

- Q from cam “how sure are you that these optimizations will improve performance”
- A I have done some things and I have high expectations that it will greatly improve - one for example was real bad - 25% regression and this makes a huge difference if you do that
- Q from cam - (something about pixel precision that are scaled up and down)
- A I shared some things just today that are pixel tests and it surprised me that it is legacy that actually had more problems.
- we correct for offsets on painting and we actively take it into account. All of the basic stuff is working, but there may still be some issues
- Q from Ahmad “before we roll this out, is there a plan to put it into tech preview where it is easier for users to test”
- A Yes, we would love that. I was approached about this a few weeks ago, yes, we would love any help at all to help with these
- Ahmad “It would definitely help me close some old bugs”
- Q from Said “I went through a lot of patches trying to understand the new changes, but I couldn’t understand what you are trying to do.  My question is is there a way you can write some documentation about the changes and the difference between them”
- A Yes, indeed - I published a really lengthy post about it before we started upstreaming. It is out of date, but yes I think that kind of document is really useful. I agree I’m happy to do that, I’ve been kind of working on this in isolation for a few years which isn’t my preference, but that kind of thing is what happens - I am really happy when people are reviewing and comparing and asking these questions.  What I was trying to do here was trying to break down these commits into reviewable chunks, I hope that we are now at a point where all of the readme notes to help the planning are gone and we can do that
- Said yes, I’m not asking for an explanation of every line, just the interesting changes
- Q from said about foreign object - is there a way to enable this only for that initially, we need that
- A yes, I had a similar idea even

### Thursday

#### Standards Positions

Learn about WebKit’s standards-positions repository and how you can help shape the web platform through standards.

##### Notes

- Anne, working on web standards for ~18 years.
- Brief overview of current standards positions.
- Standards positions:
- WebKit's current position on standards
- Positions are not guarantees on what WebKit will implement
- They are a simple/effective way to share the web
- Everyone should feel empowered to speak up and outline their thoughts on standards proposals
- Please add labels in the positions repo
- When a position is decided, please give additional time to allow others to provide their thoughts/comments/feedback (at least 1-2 weeks)
- especially around holidays.
- When should a position be declared?
- WebKit is asked for a position, an issue is opened, and there is discussion within the WebKit community about whether WebKit supports (or not) the proposal
- To what extent does "imminent implementation" affect positions?
- It doesn't really relate to implementations, but we may have a position on a proposal that we are implementing - but there may be situations where we oppose a proposal but we implement it anyway.
- "Standard" - Should we make a meaningful distinction between "proposals" and "standards"?
- The repository handles both standards and proposals, but the name of the repo is a little confusing.
- Is this the place where WebKit can announce its position on a proposal? Yes
- This should not be "Apple's" position, it should be Webkit's - positions as a whole
- Ideally, this repository will help reduce the opaqueness of why features are not available in a WebKit-based browser (like Safari), and it's not necessarily that "Apple hates the feature and silently will never implement it"

#### WebCodecs

The ongoing WebKit work towards WebCodecs support.

##### Notes

- Recent work implementing video hardware codecs
- WebCodecs is a new API. In development. Already in STP
- Interest from Zoom because Zoom is not compatible with WebRTC
- Also interest from web apps for video editing
- WebCodecs also useful for computer vision applications
- Why use WebCodecs vs existing APIs?
- Existing API designed to make playing media easy for web developers. Hands off.
- WebCodecs is lower level. More knobs for specific use cases
- Based on Decoder/Encoder
- VideoFrame is a central object for API
- API objects are thin wrappers for native OS objects for performance
- This makes it harder to use potentially
- Need to close VideoFrame objects manually, should not rely on GC
- Closing VideoFrame directly closes all references. Use ReadableStream to share VideoFrames
- VP8 implemented in software
- All software codecs implemented in web process
- H.264 implemented in hardware
- All hardware codecs implemented in GPU process
- Frames and codecs may reside in either web process or gpu process so may involve IPC
- macOS/iOS ports - implementation almost finished
- VideoFrame cannot be sent out of process
- Potential next steps: more GPU optimizations (e.g. software encoders), support in more ports, more codecs (HEVC, ImageDecoder, Audio), integrating with existing APIs (OffscreenCanvas, WebGPU, ReadableStream/MediaStreamTrack transform)

##### Q&A

- Q from Michael Catanzaro: could be easier for compliance/legal if more clarity around when/where codecs are implemented
- A: WebCodecs only exposes what platform already supports. All infra is abstract. All Cocoa specific for GPU codecs
- Follow up from Michael Catanzaro: Presence of code in repo anywhere can sometimes be legal issue. Red Hat: hardware decoders can be illegal to expose based on licensing (edited) 
- Q from Simon Fraser: Does everything apply to both iOS/macOS? Work with IOKit blocking?
- A: May have different impl. wrt canvas. Should work but may need to make some changes wrt IOKit blocking IOSurfaces

#### State of WebKit SCM

A short overview of how we’re managing our repository in GitHub and what we’re looking to work on this year.

##### Notes

-  Followup to last year's GitHub migration talk
- What have we done
    - Moved the repository to GitHub
    - Decomissioning svn.webkit.org
    - not moving all subversion branches
    - Deleted ChangeLogs
- Migrated to identifiers
    - Integrated into commits
    - Used in bugs
    - Quite effective for bisection
- Pull requests
    - Better review interface
    - Before, patch review was not compatible with every type of change, now it is
    - ~250 PRs a week
- Early Warning System (EWS)
    - Supports GitHub PRs
    - Part of making EWS support GitHub, means that branches are supported too
- Security Pull Requests
    - Supported through WebKit/WebKit-security
    - Big difference between security PRs and security bugs: Security PRs are available to everyone in the security group, bug access is more limited
    - Complications with landing to make it hard to make mistakes
- Use -v flag on git-webkit to get info about setup
- `git-webkit pr --remote security` to create Security Pull Request
- Git and GitHub can't secure specific branches, but can secure entire repositories
- Hence, WebKit-security is a mirror
- WebKit/metadata/git_config_extension contains project configuration settings
- git-webkit has the idea of source remotes, there can be any number of them
- Can be used to create remotes only visible to a particular company
- Tooling also supports bitbucket
- Faster EWS
    - Reducing retries by consulting results.webkit.org
    - If a test fails in EWS, check if the test is currently failing on main, if it is, ignore failure
    - Somewhat dangerous, does allow us to pile on bugs for a specific test failure (e.g. flaky failure becomes a full failure)
- Patch Review
    - Haven't deprecated patch review, no immediate plans to
    - Would deprecate if it became difficult to maintain
    - Tied closely to Bugzilla
- Bugzilla
    - Desire to migrate to GitHub issues
    - Don't think the project is ready to move to GitHub issues
    - Concern is that we will get an influx of GitHub issues, not able to triage
    - Ongoing discussions
- Multi-commit Pull Requests
    - Atomic commits are really important
    - Each commit needs to independently revertible
    - Auto squashing is hard, how to get the commit message?
    - Merge commits are hard to understand
- Commit Signing
    - Would require merge commits
    - Would make merge-queue more complicated
- Documentation
    - Intention to wind down the Subversion Wiki
    - Candidate replacements: GitHub Wiki, GitHub Pages, automatically deployed website
    - Leaning towards automatically deployed website – driven by Brandon Stewart

##### Q&A

- Q from Basuke Suzuki: Bugzilla is low priority, can you add automatic comments back to the Bugzilla? (edited) 
- Jonathan: How are you uploading your PRs? It should make a comment.
- Basuke: I do it manually
- Jonathan: Use the script to get automatic comments (edited) 
- Q from calvaris: Is there a reason why you cannot install ccache on the bots?
- Jonathan: I am not sure, not super familiar with ccache. Is that what helps us switch branches?
- calvaris: It's a cache for compilation. Speeds up compilation. Can potentially reduce time to land a patch.
- Jonathan: Need to talk to Elliot Williams about build speed improvements
- Jonathan: merge-queue builds on tip-of-tree, bot is picking up more content than your change
- Jonathan: Have had a lot of build / performance issues, are looking into them. Will see if ccache is being investigated
- Q from Ahmad: Should modifications to contributors.json or other small contributions trigger EWS?
- Jonathan: Need to do work on this, can be more intelligent
- Jonathan: There are some checks to make sure a change applies to an area before running EWS
- Jonathan: Changes may affect more places that you expect
- Jonathan: If you're making changes to Tools/Scripts you might think it doesn't affect EWS, but it does
- Jonathan: We should be smarter, talk to Aakash and I
- Aakash: Agree with Jonathan
- Q from Ahmad: Is bugs.webkit.org a good place to raise issues with EWS / GitHub tooling?
- Jonathan: Yes – Slack Aakash or I to get a quicker response to bugs, consider importing into radar (edited) 

#### WPE WebKit for Android

WPE Android: Improving the Web landscape in Android devices. Quick 5-min introduction to Igalia’s WPE on Android effort.

##### Notes

- WPE android started as research project in 2017, in development since, goal is to provide a WebView on Android that uses WPE as an engine.
- API is designed to line up with Android System WebView to make development easier.
- No need to introduce new WebKit port - uses existing public API.
- Supports multiple architectures, integrates into the Android main loop, requires an Android-specific SharedMemory implementation.
- Supports hardware accelerated media playback, fullscreen, cookies.
- At some point in the future, support for WebDriver and WebInspector is planned.
- Also planned is being able to provide WPEView as the default WebView on Android, integrating with the existing Android API
- Demo shows WebKit WPE view working on Samsung S20 FE, including user-agent and WebGL support. Very cool!
- (discussion and questions taking place on Slack: https://webkit.slack.com/archives/C01B9F8N0JZ/p1668101419122349?thread_ts=1668101280.148769&cid=C01B9F8N0JZ)

#### JavaScript Precompiled Bytecode Evaluation

Investigation for the precompiled bytecode generation to minimize the cost of JS evaluation.

##### Notes

- Report on investigation about precompiled bytecode evaluation.
- This is just early investigation. We do not have anything yet, but we would like help if we get stuck so that's why we are reporting.
- Precompiled bytecode: We use JSC in our system apart from the web browser. Of course, source code is text, and source is stored somewhere and loaded and compiled each time. If we can achieve that cost at build time this would be big benefit. Not for the web, just JSC standalone context.
- Came from blog post on new bytecode format and how that it is cacheable and so this seemed promising.
- Apple implemented bytecode cache a few years ago. We can use --diskCachePath option with JSC. The first evaluation is the same, but it looks in the cache. This just uses disk and requires original source. Which is not our usecase.
- What is in the cache file? The entire source code is stored inside the file. Other information is stored, we say bytecode but it contains additional information.
- There are two timings for bytecode generation, before the execution and during the execution there are many modifications happening.
- What we did. The function metadata is not necessary as it will be generated and is large and our goal is boot time speed up. The large size of this causes high I/O cost which kills the benefit. Also, bytecode cache system is good but doesn't fit our purpose, extra I/O cost, first source is loaded then cache is checked.
- Added an option to jsc to generate the byte code file. From there, we need to accept this as source, there's a notion of SourceProvider which we used to parse the bytecode file. Added functions to get information from the cached information mostly in CachedTypes.
- Result: Performance is significant, 1/2 to 1/3 time for initial evaluation. Very first line throws exception so most time is compilation/prep time. For 900kb source time was 107ms->47ms, 6M file 365 ms-> 103ms.
-  For file size, it contains original source but not too big. Extra cost (~20%) was acceptable for our use case. At first memory usage increased, at first didn't know why, but then found that source code and instruction stream is duplicated.
- That was the result, so we have more to do. We may need an API as the execute script takes a string. We could improve memory by using source and instruction stream in-place. May be able to use same compiler on same architecture. We believe this may be useful to others, so looking for help.
- I have many questions, so please give me feedback.

##### Q&A

- Q (Mark Lam): Regarding API, is the only way parsing string? . A: There's two, one for generation and one for taking it. Q: Can you use map the file? Around the memory footprint. A: It might be possible, Q: Does the bytecode format (instruction stream) lend itself into memory mapping? A: Current just allocates memory, but instruction stream should be able to. Q: On PC, what does architecture dependency? A: Endianness, can be different if compiler is changed, cache entry is copied into the file so the layout of the memory of the class must be the same (including alignment).
- (Ben Niham): I don't think this disk cache is in use for Safari but there might be some internal use case. There might be a private API for some case. (Basuke) Disk cache is also used in same boot session or if binary is rebuilt, it won't be used. (Mark Lam) We do have some internal cases. We don't use across boot sessions for security. (Basuke) For this I disabled that with fixed info.
- (Yusuke) Measured result looks following, would like to followup Mark's question around memory usage. Would suggest mmap from the file. Usually footprint doesn't count this memory. Some data would need to be regenerated, but some could be used fixed. Another thing is following up why why cache on disk, we don't have a precompiled file.
- Q (Basuke): After evaluation what is purpose of source code A?
- (Yusuke): If bytecode cache is not enabled, we need source code even if entirely done. We need a string right now for bytecode cache today, error handling case. I don't think this is mandatory for bytecode cache, we might need to do plumbing but it should be possible.
- (Basuke) Right now looks like main use-case is for generating hash for the code cache 
- (Yusuke) If we are using a pre-generated bytecode cache file, right now it probably doesn't work, but if we do some work, I don't think there's a super large blocking issue that would avoid purging the source string.
- (Mark Lam) Function.toString is another case. Have you tried to apply this to the builtins as we build those into the binary.
- Q (Basuke) Entire instruction stream is generated at beginning? 
- A (Mark Lam) No.
- (Yusuke) For one function, but not for inner functions for outer function. Current bytecode cache, every time each calling function build up bytecode. If we want to forcibly generate all instruction stream we need to do so. If you made something that forced generation of all functions then you wouldn't need the source, but we have different instruction stream for constructor or other function so each function could have 2 instruction streams when called normally or from new. Which might generate a lot of unused code.
- (Mark Lam) There's a JSC option for eagerly generate bytecode.
- (Yusuke) Given the result, the hybrid result seems to be good. If previous run didn't generate a function then generate it from source will probably work. If eager generates too much code.
- (Alex) In a similar case, I store bytecode and source so that if I change the bytecode it can generate it for a reason like that. 
- (Basuke) This may help for cases on upgrading.
- (Mark Lam) - The inspector will cause throwing away of bytecode.

#### clang-tidy on JSC

What worked and what didn’t when applying clang-tidy to JSC, and starting a broader discussion on using it along with other tools in JSC.

##### Notes

- This talk will cover what worked and what didn't in my experiment, but I hope to start a discussion on using clang-tidy on JSC.
- clang-tidy is an extensible framework to detect programmer errors on the source code.
- it can tell you about things to fix/improve, and even do the changes for you automatically.
- I did run a few passes related to improved readability and modernization on the JSC/WTF/bmalloc source code.
- There were some small things I could not fix. For instance some constants are defined as macros, so could not be moved to move inits. There were some quirks with enums in the initializer list. Etc.
- I found some issues that the compiler did not warn us about, like float narrowing.
- It was a massive patch in the end, and only stayed upstream for 3 weeks 😞
- Some bots broke: clang GTK debug builds, a SIGILL during WPE startup, watchOS regressions.

##### Q&A

- Questions: which checks should be used? Smaller patches and different PRs? CI integration? Run clang-tidy automatically every week/month/whatever?
- (Mark) Instead of landing a mega patch land different patches. Land non-controversial things first. The rest can go after that.
- (Mark) On CI. clang-tidy should not be turned on automatically unless we are 100% sure that it won't introduce bugs.
- (Jonathan) I want to second the smaller changes comment. That way it's less of a big deal to revert it. Especially for watchOS, where good testing CI is difficult to do and will remain difficult to do.
- (Jonathan) If we are concerned about clang-tidy generating bugs, maybe we should do it locally with PR upload. The same way than style checker works? But let developers override it if the suggestions clang-tidy does happen to be wrong.
- (Nikolas) I'd say the bug is not really clang-tidy's, it was a compiler bug. The one that happened in WPE.
- (Nikolas) I agree about splitting the mega patch in smaller patches too, otherwise it's very hard to dissect.
- (Don) I also agree with smaller patches. Also a comment: if something in WTF is not used by JSC then it won't be caught by clang-tidy. Maybe we could create a dummy file that includes every header, to force us to go through everything. These sanitizers helps us to improve our tooling in general. We could create special rules for "WebKit-isms". (edited) 

#### Interop 2022 + 2023

A look at Interop 2022, how it’s scored and how to help. And at what’s being planned for Interop 2023.

##### Notes

- Interop is part of the web-platform-tests (WPT) project
- Interop '22 launched in March '22, with participants from Google, Mozilla, Microsoft, Apple, Igalia, Bocoup. Scores were mid-70s in March for all browsers.
- Across the year, things have slowly progressed over the year, implementing features and fixing bugs.
- The goal, of course, is to make it possible to use these features across all browsers — make them all interoperable.
- Scores in experimental browsers are 85–91, we're leading unlike Jan.
- "Investigation" areas are research areas for "where the specs, tests, infrastructure, etc. are in a palce where we can make these features interoperable"
- Scores for investigation areas are reported back by the investigation groups, based on their instinct. Overall investigation is ~32%, which brings the rest of the score down.
- 60% of the score is 2022 Focus Areas, 30% is 2021 Focus Areas, 10% is Investigation Areas.
- So what tests is this? So there are focus areas—[lists them]—most of these are CSS, but were chosen because this is where these are the ones with the largest impact for web developers.
- Clicking on focus area names takes you over to the results, run on WPT infrastructure.
- Can click through to results, and find the failures, and fix them in WebKit/WPT.
- Things are included in Interop by them being labelled; there are many more tests in WPT than there are in Interop.
- We can add other browsers—including WebKitGTK—and see the results of that too, and not just STP.
- The Interop project is being managed on the GitHub repo. If we go into the 2023 directory we can see a README that gives a lot more detail than I'm going to.
- In Sep–Oct, we got submissions for feature proposals, but that's now come and gone.
- We're now in the point where we're deciding what the positions of the six organizations are. And then make a determination from that. A single exclusion just excludes this.
- Will launch in January, scored somehow, which we keep discussing.
- Got a lot of proposals for 2023—83, after 10 in 2022, and 5 in 2021. Partly because the project has got a lot more attention now, and a lot more attention from web developers and a lot more proposals!
- Choosing proposals is partly a question of prioritizing, what things we think are important to developers.
- If you have opinions—if you were at Apple/Igalia people to people in your org, for everyone else speak to those at Apple (Jen, Tim, Sam), or Igalia (Eric, Brian)

#### WebDriver

What is WebDriver, why does it matter, what have we improved this year, and what’s left to do?

##### Notes

WebDriver is standardize remote interface for introspection and control of web browser
Automate web browsers from separate process
Safari implements this in 3 parts safaridriver, WebKit, and Safari
Easy cross browsers testing.
WPT.fyi WebDriver Results: Safari lags behind currently
Resolved issues around dismissing user prompts
Consistent session creation/deletion
Auditing code against the specWhat's next?
Actions is a key area
Eliminate remaining time outs
Out of order processing

##### Q&A

- Brent: I was curious about moving test infrastructure into WebDriver.
- Patrick: Anything is possible. Key problem is the reliability.
- Brent: What do other engine implementors do?
- Tim: Safari is closed source. Firefox and Chromium is open source.
- Brent: Do other browser use WebDriver or do they use something else? (edited) 
- Tim: Firefox use WebDriver
- Alex: Chromium use WebDriver and other things
- Jonathan: Some test do things that we don't want others to do in WebDriver. Performance matters to us.

#### Bringing the GPU Process to macOS

GPU Process status and plans for the next year.

##### Notes

- I'm going to talk about bring the GPU process to mac os
- goal of security
- Security is the only reason
- code that access devices, devices on the chip, moved to the gpu process
- GPU is primary, but also cameras and stuff
- tightens the sandbox
- one of the goals it to keep risky code in the Web Content Process
- Also consider image and pdf decoding to be risky
- compilated formats with old code that can be more easily exploited
- Sandboxing - what is it?
- it's a thing we use on Apple Platforms to limit the functionality of a process
- allows you to describe what a process is allowed to access.
- sandboxing is 'action at a distance' - at a level that is far below the API level
- this is fragile, we can block a call that we shouldn't be
- if someone changes code in another framework, that can cause issues.
- sandboxing is incredibly powerful, our strongest weapon in the security race
- this has been recognized in the industry - hexacon
- do the same that we did for iOS for macOS
- What have to moved?
- 2d canvas - two years ago
- Also media
- WebGL on iOS in moved this year
- and DOM rendering is also been moved
- Then we do do IOKit blocking, so we succeeded in doing that for iOS 16
- We're working on that for this year
- the reason we did iOS first is because it was easier, we had an existing model that made it easier to do
- DOM rendering also mostly works, because 90% is shared with iOS
- there are small things like form controls that we need to do some custom work for mac
- webrx and webgpu are not ready yet
- there's a lot of interops between these, and all the code paths need to work
- we need to avoid bouncing between the GPU and the web process
- iOS already used UI-side compositing
- it's a confusing term
- when we say 'compositing' we're misusing the term
- it's not the thing that runs the shaders together
- we're creating the core animations layers in the UIprocess, not in the webprocess
- if we want to cut off IOKit, we can't use those in the WebContent process
- all IOS surfaces access has to be in the GPU process
- We can't use CA backing store in the web content process
- DOM rendering has to all be done in the GPU process
- This need to be transparent to most of the code in WebCore
- most of the code still uses graphics context, still uses image buffer
- there are things we need to do special things for images, pdfs and fonts
- We can encode the information about the filters to do the work in the gpu process
- web content creates image buffers,
- in the uiprocess model, we explicitly create image buffers
- we have a implementation that encodes into display list commands
- in the gpu process we have a concrete image buffer
- we transit the ioSurfaces through the webprocess in an opaque manner
- graphic context was made into a pure virtual class two years ago
- we also did some work with display lists that helped
- we subclass it as a display List Recorder, which just records the commands
- we subclass that as the remote proxy that knows how to replay those commands
- We do the same thing for images
- If DOM rendering is enabled, you'd get a graphics context to draw into, but it's really recoding and sending them to the GPU process under the hood
- in order to give us a context class that holds state related to the rendering, we have a proxy in the web content process
- These can IPC with each other
- that will manage a collection of image buffers
- that will interact with some remote image buffers
- per webpage context
- holds collections of object key by rendering resources identifier
- everything is referenced by a resource identifier
- we may get drawing commands that might reference images or fonts
- if we get a command to paint an image, the first thing we do, is we decode the image into a buffer, that image buffer is held in the image head, and the GUP process referenced that shared identifier
- same with fonts,
- we only want to run some of the content in the webprocess
- the fonts themselves, we share that data with the GPU process
- only runs the code that gets the glyf outlines and runs them
- Do the shaping code once, and then run it each time it's needed
- the scope of the GPU process, one per UIProcess using WebKit
- multiple webpages to share a GPU process
- each remote rendering backend runs separately
- a GPU process pre webpage is too much, so just one per UIProcess
- We already had remote layer
- remote rendering is the GPU process
- a lot of renaming is need to clean this up
- the main class that makes drawing work is in the UIprocess
- How does the rendering work for that particular platform?
- part of this work, the mac will start using RemoteLayerTreeDrawingArea, get this working for all the mac bits
- The page content consists of a set of tiles, we create additional later for animations
- each of those layers has a remote layer backing store
- one or more buffers that as iOSurface backed
- incremental painting each time the page changes
- the internals are different, but it's our way of hooking up between those two processes
- important that all updates come atomically to the process
- by changes, I mean any geometry changes
- everything comes in a transation
- and is applies in the UIprocss all in one go
- push the changes onto core animation layers
- makes the mac code more similar to iOS
- scrolling is different, on iOS, UIScrollView we use
- on the mac, we decided we didn't want to use app kit because it doesn't match as well
- we need support for subscrollers, we have to be able to support everything on the subscrollers,
- if you try and use an NSScrollView to do all of that it, doesn't really work as well for the mac, we will be bringing a lot of the existing code to the UIprocess
- we will need to do some work to have a scrolling thread in the UIProcess
- we need to implement pinch-zoom
- we can do it better with UI-side compositing
- this will be smoother in the UIProcess
- we also need to deal with color spaces
- we need to make sure that video full screen works, etc.
- Goal is to use IOKit blocking
- implication for clients who use injected bundles
- if you turn on IOKit blocking, all that code is affected
- trying to reduce and remove injected bundle code
- pdfs -  we rely on PDF kit now, but might try something else
- image decoding - risky so run in the webprocess
- need to make sure that hardware image decoders work
- but we've turned them off for now, even though they are more performant
- testing - see if there's an impact on our benchmarks
- don't ship a regression in motion Mark
- we have to find optimizations to make up for our slowdown because of the IPC
- We also have layout tests
- with UISide compositing, this can get tricky
- the mac will tell us if things are getting blocked by IOKit
- layout test bot, running very early UISide compositing code
- lots of crashes currently
- all the impacts of turning this on
- how can you test this
- you can in minibrowers
- Enable DOM render, enable GPU for WebGL, use UI-Side compositing
- if you have all these, we will block IOKit, and see how it works
- basic stuff works, you can load webpages and click on links
- only main-frame scrolling works, nothing for subscrollers

##### Q&A

- Ujwal: are there any performance numbers on moving surface between processes
- Simon: this is not a performance hit, it's basically free.
- Get an put image data is slow
- content that does a lot of get and put image data can be slower
- also applies to webGL, getting the current error state
- getting images to the GPU process uses shared memory
- same with fonts
- a lot of our performance work was to do with throughput and latency
- you want to optimize throughput and reduce latency
- get enough data to the GPU process to allow it to start rendering
- you need to get things across the divide soon so that you can start executing in the GPU process quickly
- have the drawing commands be as small as possible is important
- get the data through as soon as you can
- get and get image data is the only really bottleneck
- but we've used tomse shard memory for that
- Nikolas: Wondering about several design decisions: Web rendering backend and remote layers
- more wondering about starting this on iOS
- you're not using NSScroll View
- implications for the future. what are your visions/plans if you could change all ports
- The non-UISide Compositing
- Simon: the goal is for WebCore code to not care what we do.
- Really the WebKit code is where we care about the differences between platforms
- What we'd like to do is we'd like to share more code in WKWebView with mac
- there's a legacy bit in WKView, but I do't know if we'll have time for that
- you can imaging a world where we can share all the viewport code
- in terms of legacy, we still have to support UIWebView and WebView, so those still work in the old way, so that won' t change soon
- the maintenance level is up in the UIWe
- we will be able to support both paths
- SVG doesn't need to care
- Nikolas: I'm not asking about that, it's equal if not worse in some thing.
- We often ran into issues for WPE
- that we couldn't cover with automatic testing
- something is broken in certain combinations
- We are in the process of thinking about GPU process for WPE
- we want to go for a model that has your support
- that you think it's safe for the future
- so we can maximize sharing code
- reducing breakage
- that's why I'm asking
- Simon:
- We did a good thing with Sharing the scrolling tree
- good position there
- about testing - with scrolling tree
- you can only scroll and pretend that the webprocess sis unresponsive
- you hav to do the correctly
- UIScriptController methods that helps us to do the UIProcess scroll
- you can do that in a way that you can do the UIProcess scroll
- there are quite a few test that can do this
- now that I think about that, they live in fast/scrolling/iOS
- part of the story here is we should make sure that the test work well
- there's more we could do with UIScript controller

#### Improving Contributor Onramps

Improving Contributor Onramps

##### Notes

- Getting started in intimidating ... confusing ... overwhelming
- Ideas for improvement
- Rework our guides, make better use of existing resources.
- Audit "Getting Started" guide: Areas that are lacking or causing stumbling blocks?
- Got someone interested in helping with this.
- "Contributing Code" page and flow chart needs updating, in particular wrt git-based workflow (was svn).
- Also mention WPT in "Testing Contributions".
- Add "GoodFirstBug" keyword to bug reports, and link to our guides.
- Also link to guide from Slack channel descriptions&titles.
- Build new onramps.
- E.g.: New how-to-contribute videos. Code-along videos showing implementation, testing, and landing.
- Ok to show someone tripping up in the process, to reassure audience that they're not alone in struggling at times -- good encouragement!
- Build new, more focused, guides. E.g.: How to contribute to Web Inspector (so adding tooling when working on new web platform capability).
- Facilitate community onramps.
- E.g.: One-a-quarter office hours Q&A, invite Slack folks to scheduled events. Getting new contributors used to asking Qs to folks in the community.
