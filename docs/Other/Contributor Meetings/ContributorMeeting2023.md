# WebKit Contributors Meeting 2023

WebKit Contributors Meeting October 24-25, 2023

## Schedule

### Tuesday Sessions

| Talks                                      | Speaker             |
|--------------------------------------------|---------------------|
| Sony WebKit 2024 Priorities                | Don Olmstead        |
| Igalia and WebKit: status update and plans | Mario Sánchez Prada |
| Apple Plans for WebKit: 2024 Edition       | Maciej Stachowiak   |
| Managing Security Changes in WebKit        | Jonathan Bedard     |
| Current Status of Cloud Gaming             | Byungseon(Sun) Shin |
| Contributing to Web Inspector              | Devin Rousso        |

### Wednesday Sessions

| Talks                       | Speaker                       |
|-----------------------------|-------------------------------|
| WPE platform API            | cgarcia                       |
| Gstreamer WebRTC Status     | Philn                         |
| WebKitGTK and WPE ports SDK | Patrick Griffis               |
| Status of LBSE              | Nikolas Zimmermann & Rob Buis |

| Lightning Talks                                  | Speaker                      |
|--------------------------------------------------|------------------------------|
| Vertical Form Controls                           | Aditya Keerthi               |
| Masonry Layout                                   | Brandon Stewart              | 
| Speedometer 3                                    | Ryosuke Niwa                 |
| All Fonts Feature (Proposal)                     | Frances Cornwall             |
| Playwright and the state of modern e2e testing   | Pavel Feldman                |
| Standards Positions Page and Contributing        | Anne van Kesteren            |
| Implementing the WebAssembly GC proposal in JSC  | Asumu Takikawa               |
| Enabling WebAssembly and FTL JIT on Windows Port | Ian Grunert                  |
| Shipping Web APIs to Customers                   | Tim Nguyen & Elika J. Etemad |
| Quirks: Kintsugi for the Web                     | Karl Dubost                  |
| Proposal: New WebKit Logo                        | Jon Davis                    |

## Talks

### Tuesday

#### Sony WebKit 2024 Priorities

##### Notes

- Wincairo: Build and build maintenance. MSVC issues with 2023.
- Windows Playwright is interesting - webDriver-sh  and looks very promising.
- Http3: Curl backend is experimental but working on ironing out bugs.
- WASM support: Our interest is in Jit-less . Experimental and research stage at this point.
- JS: Ross Krisling continues to works on TC39 standards
- LibWPE:
    - Collaboration with Igalia on Hardware V-sync. Video and gamepad(newer version for vibration and haptics in conjunction with VR).
    - Hope to get this to a shipping state
- Graphics:
    - WC compositor porting to playstation
    - GPU process is if specific interest for security.
    - WebGPU - Currently using Google's dawn backend
    - Able to get the basic rudimentary rendering on PS port.
    - Hoping to move this to the broader webkit project

##### Questions

- Does PS4 and PS5 use the webkit differently?
    - Mostly NO
    - Any web-transport examples? Some internal teams were interested due to video.
- What is connection between windows and PlayStation port?
    - Webinspector & debug tools
      - backend portions - CURL, cairo, compositor
- Wincairo -> Webkit windows Browser how much is involved?
    - Would love but resources corporate goals
      - Minibrowser is nice starting point but a lot to build upon.
- GPUProcess & WC compositor - how much was successful?
    - Windows is running. (Fuji)

#### Igalia and WebKit: status update and plans

##### [Slides](https://teams.pages.igalia.com/webkit/contributors-meeting-presentations/2023/igalia-slides/igalia-and-webkit-2023.html)

##### Notes

- Mario is the coordinator of the Igalia WebKit team
- Igalia is an open source consultancy, fully remote, flat structure, contributors to engines such as: WebKit, Chromium Gecko, Servo
- Igalia contributes to W3C and other spec bodies
- inside the WebKit Igalia mainly works as the maintainer of WebKitGTK and WPE ports, and the implementation of Web standards and Javascript features
- Igalia spends time in other parts of WebKit such as bugfixing, refactorings, performance, 32-bit, support, QA, etc.
- The list of embedded devices where WebKit runs: set-top boxes, smart homes, medical devices, navigational, digital sinage, QA, etc.
- Who are our users?
    - we have multiple kind of users from the perspective of what they do with the engine: 
        - port users (app developers), platform providers (such as fedora, yocto)
        - Web developers that test things in different engines
        - end users that access the web
- Strategic goals
    - we aim for compatibility and interoperability, that it means the platform is good and homogeneus
    - performance it is very important in embedded devices, and efficiency using resources in the hardware
    - QA and security, are basic to make sure products continue running
    - development tools and documentation is a key part for a good story
    - it is a goal to improve collaboration with other ports inside the WebKit community
- Next we are going to talk about the recent  work, later what we plan to do
- WebKit contributors 2023
    - graph with the amount of the commits inside of the WebKit project
    - mostly is Apple and Igalia is second, with Sony and RedHat later
    - Igalia makes 50% of the commits that are not Igalia
    - in previous years we had a bigger percentage because now we get more commits for other contributors
    - which is good considering the health of the project
- Web platform Contributions
    - CSS properties: content-visibility
    - HTML Fetch Priority
    - Popover API
    - Secure curves
    - we implemented those standards this year
- Graphics
    - we did a lot of work here this year
    - in the port specific side and in the core
    - Finished ANGLE integration and WebGL2 support
    - Sharing buffers between process is an important part of our future development, we are working to move to that kind of architecture
    - we cleaned up some other things such as: remove the wayland server, synchronization using displayLink architecture
    - we have worked is the replacement of cairo as the 2D rendering engine
        - today we do not have anything to present but it is a big effort internally
    - we have a experimental GPUProcess support
    - we implemented SVG layers as a first class citizen in the LBSE effort
- Multimedia
    - biggest users for us if the STB which means multimedia is important
    - we did DMAbuf sink integration
    - WebCodecs, WebRTC using gstreamer, improved power consumption, etc.
- JSC
    - the biggest effort we do is to support 32-bit
    - we added multiple features to the ARMv7
    - we work in WASM GC and it is the topic of asumu's talk tomorrow
- new WPE API
    - we have several problems with the API, it was created that way for a reason in the past, but we wan to change that
    - wayland centric, API documentation lacking, complexity
    - we plan to create a new simpler API
    - we started to work on that
    - we are starting to push patches
    - tomorrow carlos is going to talk about this
- WebKit on Android
    - last year we presented it
    - the idea is to use a different engine in Android using WebKit
    - we did not have that much time this year to work on it
    - we are consuming the WPE API
    - we support multiple architectures, native integration, etc.
- Quality Assurance
    - this is not our strongest point in our ports
    - we have seen multiple problems this year
    - we have added more people to the team and we spent a lot of time fixing API and Layout failures
    - the numbers are interesting, we have increased the amount of tests running and reduced the amount of skipped tests
    - we can see the graphs with the situation
    - it is not great but we are improving, but we are still not happy with the situation
    - we reduced the amount of flakes
    - we are shifting the work for GTK
    - for WPE has a better situation, as a result of the effort we are doing
- for security we do multiple releases every year
- we publish them in the website
- tooling and documentation
- we want to move to the new github documentation infrastructure
- people in the QA is the one that works in this
- on the tooling we did a biggest an effort
- patrick will talk about this tomorrow
- WebKit is not an easy project and we would like to have a solution for developers and testers
- the solutions we had were good for one or the other but not for both
- so we have created a solution with a container based
- OCI compatible container
- you can download it and you can use it even to hack in the dependencies
- for instance it is important for the people working in gstreamer
- next steps section
- on Web Platform
- we will work in the Navigation API and the hasUAVisualTransition
- graphics
    - refactoring is important in the next year
    - use dmabuf more extensively in the architecture
    - replace the 2D engines sooner than later and the GPUProcess
    - the new SVG engine should be upstreamed next year completely without any performance regression
- multimedia
    - gstreamer webrtc backend and general maintenance is the main work we plan to do
- JSC
    - mainly ARMv7 improvements
    - enable OMG and FTL
    - land WASM GC
- new WPE API
    - finish some initial version, review the API docs and deprecate the old one when we think it is ready
    - we want to start landing patches sooner than later
    - there is no specific release date
- WebKit on Android
    - we want a first usable version of WPE on Android
- there is a list of next steps we plan in the future next year
- QA
    - we need to improve the charts of tests running and fixes
    - we have the new SDK that we hope it helps to improve the story
    - prepare GTK4 bots, because it is the next version
    - tooling and documentation
        - release the first version of the SDK
        - and improve the documentation

##### Questions

- WASM BBQJIT in ARMv7, work in the registers support
- they talk about the specifics of how to allocate registers in the ARMv7 architecture
- cairo replacement, is that something you try to use for Windows too
- right know it is mostly for Linux, but we do not discard that running in the Windows is important
- graph of regressions where they come from
- it comes from webkit test hunter for our ports
- webkit for android, do you hope that someone can create a browser out of it or you have niche cases in mind?
    - ideally it could be a complete replacement but we do not have all the features but for the moment we don't have all the features
- we did a proposal for the Windows registers allocation, and he can discuss this later more specifically
- are you planning to use the android support as a general browser or as a webview replacement?
- mario explains that it is going to be a webview replacement
- curious about the CI side, windows using containers
- we already use containers LXC in the bots
- the idea is to use the SDK container in the bots
- either running them in the LXC or directly

#### Current Status of Cloud Gaming

##### [Slides](./Slides2023/Current%20status%20of%20Cloud%20Gaming.pdf)

##### Notes

- Agenda:
    - What is cloud gaming
    - what are the difference from normal video gaming
    - current standardization activity at w3c working group
- What is cloud gaming? Graphic rendering on the cloud side. Client side does need  high perf machine.
- Customer does not need to upgrade hw console every year
- Click to pixel latency is one of the major performance indices.
- It’s recommended to be under 150ms in the cloud gaming
- slide: 120fps processing timeline.
- Demo (recorded video) (edited) 
- current standard activities w3c webrtc wg:
    - quality improvements on lossy network condition
    - faster video recovery
    - consistent latency
- nvidia trying to propose to the working groups
- macOS/iOS topics:
    - WebRTC Release Cycle, by annual
    - Higher Resolution 4K Support, (HEVC behind a flag)
    - User Input gamepad, keyboard, and mouse

##### Questions

- slide: What are the difference from normal video streaming:
    - ultra low latency
    - consistent latency
    - video content
    - QoS
    - …and more
- How about WebTransport or WebCode instead of webrtc?
    - Yes. internally considering.

#### Contributing to Web Inspector

##### [Slides](./Slides2023/Contributing%20to%20Web%20Inspector.pdf)

##### Notes

- Devin spent 8 years working on Web Inspector.
- Going to give run down.
- Debuggable is the main thing you are inspecting
- Target is the thing that is being debugged (e.g., Javascript, page, service worker)
- It may be weird that you have two separate list... some are one 1 to 1.
- but others allow a 1 to many relationship. Like web pages can debug many things
- Frontend is our UI.
- And backend is the page we are inspecting>
- Protocol is used to communicate between "front end" and "backend"
- Going to focus this talk about the protocol... the protocol is auto generated.
- There is also the "remote", which is important for devices... like connecting to iOS and Simulator
- With remote, we get some assurances around IPC
- Front end is just vanilla javascript and HTML, CSS, etc.
- The InspectorFrontendHost is just a special API (non-standard)
- And InspectorFrontendAPI is how things talk to web inspector
- We use a few frameworks to help us (e.g., codeMirror).
- We use extensive use of event listeners
- We have a "custom layout engine"TM
- we use this as a "view", and we use requestAnimationFrame etc to keep everything in sync.
- And we follow a simple MVC
- Controllers are mainly "managers"... mostly a singletons on the frontend
- They handle the protocol communication
- They need to know which target they are communicating with and handling
- But other than that is just models and views
- The models are just data wrappers
- The UI is split into multiple areas that interact with each other
- As you interact, each area is given metadata to control various aspects of web inspector.
- Web inspector care about RTL, Dark mode, eetc. so you need to care about that when contributing to the project
- There are various APIs attatched to WI.*   ... WI.Table, WI.NavigationBar, etc. as components.
- Lots of examples of how these components are used. Makes it easier for new developers to contribute
- The protocol is almost entirely auto generated
- Basic IPC system based on JSON
- There are a ton of protocols
- And there are other domains.
- Like CSS domain corresponds to CSS things, runtime is "javascript"
- new domains are just specified with JSON
- beyond domains, there are corresponding types
- It provides type safety and assurances
- Plus it provides events and expected structures
- Devin shows an example of what a definition of a domain looks like in JSON
- Similarly with types... we define it as "type": "integer "
- Makes it really easy to understand... same with enums
- e.g., "before" and "after"
- and gets more complex from there
- but not too complex 
- You can also specify "commands"... like., "getDocument"... and that would send from frontend to backend, and it sends a serialized version of the command.
- As a developer, you just implement the the frontend call, backend function, but you don't need to worry about the IPC. That's all handled for you. (edited) 
- And for events, there is just parameter associated with it. It keeps things simple.
- Web inspector needs to consider:
    - Inspector Web Process
    - Inspector UIProcess
    - Inspected UIProcess
    - Inspected WebProcess
- and how each communicates / route through each one. We handle that for you. You never have to touch this code to make it easier.
- But what's important is that "inspector" and "inspected" are totally different devices potentially. But you don't need to worry about that as a developer
- It's possible to inspect from a new macOs to an older iOS, but older iOS can't inspect a newer macOS... i.e., you can inspect "the past", but not the future
- We have automated systems to check for support if the backend has support for a particular command
- Which is very helpful. So you can recover
- Again, this is all auto generated,
- ....Devin shows how this is done with JS... communication between front and backend
- ... lots of JS code...
- Similarly with events... it's not that hard
- Heavy use of WTFJSON
- Backend... each debugable has a top level controller object
- It's responsible to create an agent to help with a domain... it provides the functionality for that domain.
- E.g., all would have a runtime agent because they all talk "javascfript", but they are normally specialized
- There are specialized objects to help you work with different things you might want to debug.
- General tips... a lot of prior out throughout the code base. Only confusing bit is the protocol.
- But generally everything is pretty straight forward
- You can even inspect web inspector with web inspector
- We rely on ESLint
- to keep the code clean and consistent
- There are barely no UI tests... you don't have to write tests.... but the downside is that you need to manually test stuff
- No need to wait for EWS... it's easy to make changes to the UI

##### Questions

- Razvan, when you create agents on the backend, how do you maintain sprawl?
    - generally try to think to figure out what category it falls into? (e.g., look on MDN)... you could argue that you could make a new domain. Try to use an existing agent if you can. Or if it requires a special case that talks to multiple agents. You need to think hard about the domain and the agents to handle different cases. So yeah, think about the architecture and reuse as much as possible
- I tried to make changes to the code UI... do you plan to add UI frameworks?
    - we are not huge fans of UI frameworks because they can get in the way. We like to name things well, and keep things super simple. The view system is our answer to that. We have a very basic system, it's only like 20 lines of code.
    - We define the rules. And we enforce them on ourselves
    - The less code we have to deal with the better. Nowadays, we don't need things like jQuery anymore because how much better browsers are now
- Don from Sony. You are allowed to use whatever is available in the web platform. What web platform would you like to see more of?
    - we see a lot uses of var but generally we leave those alone if it's working. We use new things as a test bed, but we don't got out of our way. Like, going forward, we always replace functionality old functionality and also use new things when they become available?
- do you use ESLint on EWS or plan to?
    - more often than not, we use it as guide but we sometimes don't agree with ESLint for various reasons. So, more of a guide an principle.
- comment: Karl. I use web inspector a lot for web compat. It helps a lot when you fix web inspector it helps fix web platform health overall.
- Please fix more stuff
- Devin: sure. We want to help everyone - web developers and WebKit engineers
- We sometimes even do very specific things for web inspector developers. And we add things specific things just for WebKit engineers, but also benefit web developers
- Frances. What suggestions do you have to find Web Inspector bugs for webkit engineers?
    - here is no way to explicitly find them, but there is no specific list. I'm sure there are quite a few
- Razvan: to rephrase is bugzilla, the right place to file Webkit bugs?
    - yes, put things under the Web Inspector components
- Elika, great presentation! Where can we find this info later?
    - Great question. I want to write a blog post about this. I don't have speaker notes.

### Wednesday

#### WPE platform API

##### [Slides](https://teams.pages.igalia.com/webkit/contributors-meeting-presentations/2023/igalia-slides/the-new-WPE-API.html)

##### Notes

- we are working in the new WPE API
- current status
- the architecture nowadays has WPE as an external library for rendering and input handling
- backends implement does interfaces for rendering and input handling
- we have the fdo backend for wayland support
- there are other backend such as the RDK for set top boxes
- we have cog which is a browser you can use as reference implementation
- problems with this model
- we have multiple problems
- we designed with EGL and wayland for rendering
- but with time we realized we can render better without EGL and wayland
- wpe is an external library
- used by WPEWebKit, backends and applications
- this way libwpe is not obvious what parts are needed from the UIProcess and the WebProcess
- it has its own IPC mechanism
- it is not easy to maintain because we have to sync with releases with WPEWebKit and cog
- there is lack of documentation
- and just simple implementation requires a lot of understanding
- cog is not just a reference it includes a lot of glue code to complement
- that is why it is mainly used
- new architecture
- we want to get rid by the wayland model
- and use a buffer sharing mechanism that the target platform can provide
- the rendering of the WebProcess it is independent of the target platform not
- with gbm, o surfaceledd contexts we can avoid that dependency
- and WebKit IPC is what we want to use for the communication
- web process send message when allocating a buffer
- and it notifies when the buffer has a frame
- and the UIProcess notifies when the buffer is rendered
- this is already upstream in gtk port
- wpe is not using it now because it requires a new API for this
- we don neew the wayland compositor to share the buffers
- the new WPE API
- we need it because we need a new model because the requirements are different
- the plan is to make it part of WebKit
- instead of an external library
- it still has the same users: WPEWebKit, platform implementations and applications
- in this case it is optional applications know about this API
- there will be builtin platform implementations now
- this is a difference with the past library
- we will have support to load external ones
- but we will include the ones that cover most of the cases as part of the library
- it would be optional to compile them
- drm, wayland and headless would be the first additions
- DRM is the most efficient to render a fullscreen mode browser
- we can do direct scan-out buffers
- headless would be used mainly for testing
- the API is now UIProcess only (edited) 
- making it easier to use
- there would be API documentation, we would fail if there are no symbols for an API
- and it will be easy for most use cases but flexible enough
- current status
- the API is already and working
- wayland platform implements most of the interfaces
- headless is complete too
- and the DRM is on going, it implements only some input events
- Plans
- we want to upstream the patches from now on
- it is a big patch
- but it is well self contained
- the architecture is already in the repository
- because it is enabled for the GTK port
- we have enough code to be confident this is the way to go
- we have to implement the missing features
- we need to review all the documentation
- because we are adding changes and we need to update
- we will deprecate the old API
- but we will not remove it for the moment
- because some platforms are not able to use sharing buffers
- it does require any API or ABI version bump
- and applications using the old API will just work
- but they could use the new API with the new constructor
- it would be released when it is ready
- we do not have a deadline for this
- we have a branch internal that we rebase
- it would be upstream with a build flag
- so that we don't break anything and distributors do not ship it until it is ready

##### Questions

- N/A

#### Gstreamer WebRTC Status

##### [Slides](https://teams.pages.igalia.com/webkit/contributors-meeting-presentations/2023/igalia-slides/webrtc-in-wpe-and-gtk.html)

##### Notes

- Brief summary of the timeline (libwebrtc, …)
- 2015-17 …
- 2017-2019: LibWebRTC attempts
- Bundled in WebKit for Apple WebKit pots.. Integration with GStreamer Encoders, Hardware accelerated support requiring custom decoder/sinks
- 2019 onwards: New GstWebRTC announced at GSTConf
- 2017, and the initial experimentation which we upstreamed a backend for in 2022
- Screen capture when you want to capture mic or video. In WebKit that takes a permission from UIProcess to WebProcess
- We differ a bit form the apple ports in that I think apple does it in the GPU process
- we had to design from RPC from the webkit process to the ui process
- that means it’s not easily testable right now
- we have some infra for this, it breaks now and then, it’s not that hard to fix but you have to watch it
- one pipeline per capture device
- Stream capture (getDisplayMedia()) - we have two layers of permissions
- in linux we have the webkit permission request + desktop portal - we have to talk to it over IPC
- The desktop portal can remember previous permission requests so perhaps we can improve that
- then we have another pipeline which relies on pipewire, it’s deplohyed on linux desktops nowadays and it can captire - it provides DMABufs
- for MediaStream handling - when you need to capture, in the gstreamer ports we have a plugin that is able to feed the popline with data coming from the media stream
- we use that quite a lot for handing incoming streams, canvas/video/capture
- {shows a diagram showing a simplified version}
- webrtcbin implements the JavaScript SEssion Establishment Protocol, the integration with webkit was quite easy - GstPromis is hand in hand with webkit’s Promise<T>
- When you receive a media stream, in javascript you will usually connect that to a video element (as .src) - in webcore it will internally hook to webkitmediastreamsrc -
- this all means that we use the same thing for normal playback of video, etc — which I think is different form apple ports again
- additional APIs: Can’t do everything that is required of the spec, some we did upstream adds — we had to do some plumbing to provide frames-encoded, bitrate, etc
- also with DataChannel - we had to do some patches in Gstreamer, but now it is integrated quite well
- we are passing ~60% of the tests, but that isn’t WPT
- there is still work to do obviously, but we’re getting there
- we’re also doing dedicated bring ups of specific platforms - we focuesed on gaming with amazon luna - we followed kind of the chrome approach, I tried with a safari UA but it doesn’t work.. So we have to send the chromium UA and rely on some legacy RTC…
- we have a pull request, it’s not been reviewed yet
- we had some issues with the service expecting some chrome specific specs - we provided some shim implementations of those to just allow us to move forward - it’s not great
- another one we’re bringing up is jitsi — it’s unfortunately not working yet.
- it requires features we don’t yet support: renegotiation, simulcast, etc
- Takeaway: Every platform requires a dedicated bring up. We can have spec compliance, but every one requires more… Being spec compliant is just the tip of the iceberg for webrtc
- re: encoding - we have to provide for simulcast - GSTWebRTC has some support but it’s not used by WebKit yet…
- there are 2 types of scalability
- re: Privacy and security… All of our pipelines run in the WebProcess, we can’t send that into production, that’s bad
- ideally the plan on the roadmap is to move that to a restricted NetworkPRocess
- etc
- another deals with capture devices - same issue in the WebProcess… tentative plan is to improve permissions/portal on GTK/Desktop. We’ll have to figure it out on embedded where user input could be lacking. Then we’d like to move all of the GStreamer pipelines to the GPU process
- Then we have a missing features backlog:
- ICE candidates filtering
- SFrame encryption
- Improve stats coverage
- Tranceiver direction changes
- DTMF?

##### Questions

- How do I accelerate video? are there licensing issues?
- on adb platforms the support is provided by third party provider GCMA plugin that you can use so it really depends on each case
- second question: You mentioned the keyboard for cloud gaming. Did you have any plan to upstream that implementation?
- I dont think there are positive signal from apple at this point. WE could provide an implementation but it would have to be disabled by default because there were some issues related with that spec that we’ve not addressed yet
- Indeed
- The question was about keyboard-lock, for the record

#### WebKitGTK and WPE ports SDK

##### [Slides](https://teams.pages.igalia.com/webkit/contributors-meeting-presentations/2023/igalia-slides/wpe-and-webkitgtk-SDK.html)

##### Notes

- flatpak was our previous attempt
- it added too much complexity in WebKit's tooling
- it's immutable sandbox prevents working on system libs
- the SDK image was too complex to produce
- flatpak is mostly for desktop apps
- new attempt is a container based on Ubuntu 23.04
- goal, be out of the way as much as possible
- provides scripts to interact with the podman container
- 3, commands, wkdev-create, wkdev-enter, and then in the new shell, usual scripts like build-webkit can be used
- no modification required in WebKit's tooling
- SDK provides support for distributed builds with sccache
- also VSCode integration
- also NVIDIA tooling, and scripts to build system libs using jhbuild
- the plan is to deploy this SDK in EWS bots (no timeline yet)
- the SDK source will be soon published online
- Github Codespaces could be used for WPE development from the browser as well
- Could be used in VMs as well, on macOS for instance

##### Questions

- N/A

#### Status of LBSE

##### [Slides](https://teams.pages.igalia.com/webkit/contributors-meeting-presentations/2023/igalia-slides/integrating-the-new-LBSE.html)

##### Notes

- Presenting challenges, current status, and roadmap
- Started working on KHTML since 2001
- LBSE is a new SVG engine in WebKit, utilizing the layer tree
- …which used to be inaccessible to SVG, leading to a long trail of bugs
- LBSE is meant to integrate SVG, HTML, and CSS
- Trying to embed HTML into SVG caused some really nasty bugs; LBSE should resolve these
- Developed by Igalia and funded by Igalia, Vorwerk, and now WIX
- We want to re-use the WebKit codepaths that give us hardware acceleration, particularly perspective transformations
- The paths are presently mutually exclusive
- When we started, only SVG had transformations and other features CSS has picked up over the years from SVG
- SVG rendering stayed as it was while HTML+CSS was developed
- So the only reasonable way to update is to remove the old SVG engine and replace it with a better one, like LBSE
- Performance was about on par, with a 2-4% drop on MotionMark
- Some individual tests were much faster than before, others regressed
- How is this achieved?
- SVG is allowed to participate in the layer tree
- Remove SVG-only transform, clipping, marker, masking, filter code
- Rework SVG’s render tree to be accessible by CSS
- Re-use as much code in RenderLayout as possible
- The more we use RenderLayout, the more things we get for free (z-index, etc.)
- LBSE was designed as a drop-in replacement for the old SVG engine
- This wasn’t well-received; too much change too quickly
- So we had to rename the entire legacy engine so it could live in parallel with LBSE
- Last we checked, the LBSE patch is about 40MB
- We provide a compile-time flag allowing to pick between engines
- Issue was opened in 2021, hadn’t been finished yet
- Overall progress status is around 77%
- The main thing missing is resources
- Many patches landed since last year’s WKCM
- November 2022, we landed a patch that unified geometry and transform computations with CSS
- The key for performance is to bypass WebCore
- Access already-composited images and move them instead.
- This let us finally switch on accelerated transforms, this year
- That patch landed June 2023
- We still had repainting issues; if you animated inside an SVG with CSS, looking at it Web Inspector caused a lot of repaints
- This was patched out October 2023
- We started to upstream resources in September 2023
- In SVG, resources are clipping, masks, filters, etc.
- In our next steps, we want to finish upstreaming, including many patches adding missing layout tests
- Resource invalidation is broken in WebKit since forever
- (shows example, slide 20/32)
- How invalidations actually work: if you change a circle radius to 20, the clipper has to notify the masker that the rect it’s using has changed
- Before, we handled this via layout
- So changes to radius would force a re-render of the mask
- Do it in the right order, and you could get lucky with correct invalidation
- Get them out of order, and invalidation wouldn’t happen properly
- We suffered a lot from unnecessary repaints and relayouting as a result of this
- (shows example, slide 22/32)
- Here’s a typical code graph
- At some point, we’ll tell core the layout is dirty
- We have to invalidate it
- Afterwards, something is marking it for invalidation. Why?
- At some point in this recursive calling, the element gets a style change notification
- We have to mark the user of that clip path and “needs layout”
- Resources in the chain are notified
- If you process in the right order but swap elements, then after layout, things are still dirty and so layout isn’t finished when we think it is
- We think we can avoid this mess if we stop abusing layout
- All this is a fundamental flaw we need to avoid
- Invalidation depends on element order, and it should not
- Our plan: LBSE will do masking and clipping statelessly
- No more temporary buffers or caching of individual render objects
- This is being implemented via RenderSVGResourceContainer, a new base class, which landed this month (Oct 2023)
- The next target after that is the resource clipper
- We’re currently rewriting the whole of the resource invalidation logic
- The SVG resource cache will be moved to LegacySVGResourcesCache
- Mid-term plans: finish support for <clipPath>, then add <mask>, linear and radial gradients, <pattern>, and <marker>
- All of those become trivial after finishing with <clipPath>
- First basic implementations should be done this year
- Long-term plans: finish LBSE, such that all layout tests pass and are not slow
- We have to reduce the core RenderLayer overhead and cache more SVG subtree information
- Also selectively construct render layers only when necessary
- Target for switching over LBSE by default and remove the legacy engine is 2024
- Igalia is working with all the power we can, getting everything we have upstream so we get everything upstream though maybe not as performant as legacy
- Then we will work with Apple to reach performance targets and equal or exceed the legacy engine in performance
- MotionMark is a good example of something that doesn’t benefit from the new engine
- On other tests, LBSE is outperforming the legacy engine by orders of magnitude

##### Questions

- Sayeed: you mentioned you were going to get rid of the buffer. HOw can you make performance faster without those?
- Nikolas: The idea is you don’t have to paint those things at all
- …If there is something where we have to do more work, we’ll do that, but this is no difference than HTML or CSS
- ???: You said MotionMark is testing something that doesn’t benefit, so you’re using it just to make sure you’re not regressing
- …Do any existing benchmarks that show the gains here, or something you use?
- Nikolas: We don’t have anything public yet
- …It would be good to put such a benchmark out for people to see
- ???: I wonder if you would see  benefits in other existing benchmarks

#### Vertical Form Controls

##### [Slides](./Slides2023/Vertical%20Form%20Controls%20%E2%80%93%20WebKit%20Contributors%20Meeting.pdf)

##### Notes

- Form controls where writing mode is specified as vertical-rl or vertical-lr
- Results in an alternate CSS block model form
- Motivation: lack of internationalization, interop 2023 form focus area (WK has lowest score)
- Implementation: not as simple as specifying writing mode
- Example: the progress bar, which is forced to have horizontal style even with vertical mode
- We need to make sure we are using CSS logical properties, updating our user agent stylesheet
- Layout: reimplementing custom renderers, baseline adjustment (custom baselines updated to work with vertical text)
- Any port can detect vertical writing mode by checking render style or control style state
- Implementation: Rendering: Rotation
- we simply rotate the control to match the writing mode
- Implementation: Rendering: Logical Coordinates:
- transpose rects, sizes, and coordinates
- Demo of select multiple
- Complete rewrite of the select control to support horizontal scrolling, and keyboard selecting, and scroll-left property. All ports benefit from this
- Enabling this in ports: VerticalFormControlsEnabled setting (planning on enabling in macOS and iOS)
- Still some small rendering issues to address in the short term, and in the long term, support for pop-up/native UI

##### Questions

- Q: Do other browsers also not rotate the checkbox?
- A: No browsers rotate checkboxes, radio buttons, etc.

#### Masonry Layout

##### [Slides](./Slides2023/CSS%20Masonry.pdf)

##### Notes

- Jen Simmons gave an overview of Masonry layout at WWDC.
- Grid: consists of rows and columns. This might leave a lot of space in individual cells.
- Masonry: solves this by getting rid of rows.
- [Shows example of 7 sibling elements where the first three elements are next to each other on the first conceptual row. The elements after that are put in the shortest subsequent conceptual rows.]
- Worked on updating the specification to finalize it. Worked on Align Tracks & Justify Tracks and because there was a lot of complexity and a11y issues these were removed.
- Intrinsic Track Sizing Changes: we used to use the first conceptual row to determine the sizes. That made it hard for web developers to use.
- In the new specification all elements participate in determining the track size.

##### Questions

- N/A

#### Speedometer 3

##### [Slides](./Slides2023/Speedometer%203.pdf)

##### Notes

- Used to optimize and compare browser perf
- 1.0 in 2014 by apple
- 2.0 2018 collab with Apple and Google
- 1.2 in 2022
- 2.0 was mostly updating frameworks, not much to runner or test harness
- ... but it's often considered one of the most popular benchmarks
- Speedometer 3
- open governance model
- collab between apple, google, mozilla
- update frameworks, but also include other types of content
- instead of contributions governed by webkit contribution policies, based on consensus model
- updated framework list, new (web components, svelte, lit). retired (ember, inferno, elm, flight)
- New News sites tests (Next.js, Nuxt.js), emulating a website like cnn
- Editor test cases for rich text and code
- Charting (observable plot, chart.js, stockcharts, perf dsashboard)
- working for a bit over a year
- webkit optimizations. improvements starting July of this year
- continuing until early next year for scheduled release (spring 2024)

##### Questions

- question: when running speedometer on browserbench, there's an effect of testing the end users connection. is there work being done to avoid that?
- answer: we'd have to look into that
- q: anything you'd like to get into a future version, or another benchmark?
- answer: biggest one is async tasks for promises / workers
- q: is it correct that charting is based on SVG?
- a: yes, some are using SVG and others are using Cavnas
- q: how do you select frameworks?
- for the network speed question, filing a GitHub issue on the Speedometer 3 repo is a great way to record that feedback
- a: we look at data based on what's being used in real websites and use currently prominent
- or those that appear to be becoming more prominent
- @Nikolas Zimmermann we have some some SVG optimizations (mostly attributeChanged stuff) based on speedo3
- the two charting SVG tests are Observable Plot and React Stockcharts SVG. ChartJS and Perf Dashboard are canvas
- there are SVGs scattered throughout other tests (like icons in editor toolbar), though I wouldn't expect much of that to get measured

#### All Fonts Feature (Proposal) 

##### [Slides](./Slides2023/All%20Fonts%20Feature.pdf)

##### Notes

- recent contributor to web inspector. I have a lot experience as a front end engineer
- Today I'm going to be presenting a "all fonts"  feature for the web.
- Frances makes a joke about bad font usage.
- Some fonts are not appropriate for.
- The New York Time uses a particular font to convey their identity.
- I created a site with different font for each word.
- How can a web dev find out which font is being used for each word?
- You can do that by inspecting each element?
- You can look at font-family under style... but you can't know which one has been actually selected. It's unclear.
- And then you have Times New Roman, but it's a default so it's still confusing.
- You can also look at the CSS itself to see what is being applied being ids
- and via classes
- Your last option is to go to Firefox and their dev tools. But that still doesn't tell you which one WebKit chose.
- Proposals: what is you had a way of seeing which font is selected via a new fonts tab.
- Challenges: what if you have a slide show, for instance, and each slide is using a different font, or scripts are changing things, and what if the computed style is different for different devices?
- Right now, I've managed to get the right information to show in console.log().

##### Questions

- Question: can you track which font is being used by an element?
- Right now I would just present all the fonts computed for an element on a web page

#### Playwright and the state of modern e2e testing

##### [Slides](./Slides2023/Playwright%20and%20the%20State%20of%20Modern%20E2E%20Testing.pdf)

##### Notes

- Will talk about capabilities, trends, challenges etc
- the team started at Google, worked on web inspector before fork, chrome devtools after fork
- later node.js debugging
- at some point puppeteer emerged as browser automation interface
- later switched focus to web testing
- playwright test example, similar to layout test, isolated environment
- see test execution step by step in the trace viewer
- unique features: single command installation
- works on 3 oses, in cloud, headed and headless
- whitebox instrumentation of the browser, network interception, ignore tls, workers etc
- reliable tests is a priority
- each test runs in clean, isolated environment (new ephemeral context per test)
- parallel test execution
- chromium, webkit, firefox are supported out of the box
- Linux dominates CI
- as it is cheaper in cloud
- Mostly Node.js, with python distant second
- also supprot .net and java
- download stats for major players in the space
- cypress: tests run within page, oopifs not supported
- great user experience makes it the leader
- puppeteer: out of process CDP client of Chromium, general puprose API for the browser
- playwright: upwards trajectory, relatively new
- selenium-webdriver: steady download rate
- each tool uses its own way to connect to the browsers
- only playwright is cross-browser
- default browsers download stats for playwright installations
- firefox and webkit have a big share each
- wholistic approach to the integration: from browser instumentation to retries
- responsible for all the bugs, no finger pointing to other components, if there is a bug in browser protocol it is considered a bug in playwright
- browser fixes either upstream or downstream
- in chromium everything is upstream
- webkit: wincairo, linux wpe(headless) and gtk (headed), macos
- support headless execution on all platforms
- implemented as web inspector agents
- the protocol is reach-enough, talks about all the entities we need
- couldn't find another protocol that provide comparable capabilities
- when testing how web site works on mobile safari we need to emulate touch
- the code is ios specific
- same for fixed layout emulation
- taking screenshots after compositing is a challenge across platforms
- same problem in web driver
- network stack is different across platfors
- no good rationale for upstreaming web inspector protocol changes as many of them are not directly usable by web inspector front-end

##### Questions

- N/A

#### Standards Positions Page and Contributing

##### [Slides](./Slides2023/standards-positions-2023.pdf)

##### Notes

- there is a repo on GitHub that WebKit uses to be asked and provide feedback for web standards
- intended to be separate from actual implementation
- sometimes have to implement things WebKit doesn't like
- ideally allows for evaluation of standards with a more principled/conceptual viewpoint
- collaboration can be async
- to request a position, discuss with colleagues, post a comment asking, give a deadline, and (usually) WebKit will do something before then
- there's also a basic website that visualizes the state of the standards position repo on GitHub with some extra features (e.g. search, filtering, etc.)
- would love to have more contributors.  often only Apple employees
- could use help with triaging of applying labels to issues.  some is automated, but not all.  all contributors should be able to do so
- room for improvement in tooling and the website

##### Questions

- Q: opinions from real use cases often are missing from standards positions
- A: more of this would definitely be useful.  there are a few cases where this has happened, but not often.  could be that the web developers themselves arent involved.  WebKit should encourage them to
- Q: are there any examples where there's disagreement on standards positions?  there might be a little bit of hesitancy around "internal" disagreement stopping momentum of standards work
- A: there are a few issues with disagreement from the wider web, but not often from within WebKit.  possibly the mailing list used to have more "internal" disagreement.  there is the #standards/#standards-github slack channels for less public discussion if you'd prefer to "poll the room" or verify opinions or etc. before posting publicly

#### Implementing the WebAssembly GC proposal in JSC

##### [Slides](./Slides2023/wasm-gc-webkit-contrib-meeting.pdf)

##### Notes

- What is this proposal and why do you are?
- Wasm is a target language for compiling web programs. It’s an alternative to JS where you want to transpile
- it’s been used for a number of interesting applications - bringing photoshop to the web, things that use plugins written this way - flight simulator, games
- you might wonder: is that low level stuff all it can be used for?
- wasm - can it be used by language that use GC?
- Kludgy solutions, but Key missing piece was is some kind of allocatable memory - that’s what this GC proposal is for
- it has datatypes like structs and arrays
- and also new kinds of reference types - you get new type casts and advanced types from this
- at least in the browser context it is designed to take advantage of the built in already
- (shows a concrete example with type declaration)
- (and globals initialized with new types)
- (and writing operations which access that data)
- (and new reference types)
- there are a bunch more features, ut this is a high level overview of what it is
- let’s talk about the implementation progress in JSC
- most of the features of the proposals are already implemented
- but it’s not in a shippable state - a few more months — bulk array operations aren’t implemented, misc missing instructions — it needs much more testing and optimization but look how much (a lot) is already implemented
- Basically: It’s well underway and hopefully we can get it to shipping soon.
- The big takeaway is that this is an exciting time for web assembly — this proposal enables WASM to be used for a whole bunch more languages.  It’s stage 4 pretty much the last stage — it’s shipped in other browsers
- it enables targeting wasm for Java, OCaml and many others

##### Questions

- N/A

#### Enabling WebAssembly and FTL JIT on Windows Port

##### [Slides](./Slides2023/Windows%20Port%20WebAssembly%20and%20FTL%20JIT.pdf)

##### Notes

- Hello everyone
- wasm work on windows
- ask questions about recourse center
- why improve the windows port?
- firstly, playwright gives people experience to test webkit on windows
- second, bun uses webkit windows port
- good for port alignment
- compared to gtk or wpe, different features on win
- would be great for the project to get cross-platform desktop apps working, currently corned by Electron
- which means Chromium
- other projects are using the system webview for this
- so webkit limited on windows limits many developers from choosing this
- more projects want to bring a browser to windows
- started by working on signal handlers on windows
- has landed in may, using exception handlers
- next step: enable low level interpreter
- currently has an open PR, uses some dll magic
- PR is open for feedback!
- current status roughly matches Safari's support for wasm
- with exception of JIT
- got JIT working to the point of supporting ARES-6
- there are some known issues left
- as a bonus, will unlock BBQ and OMG JIT
- ARES-6 shows a performance improvement with JIT
- next steps:
- land wip PRs
- work on static asserts, which will make it easier to enable some features
- more work needed on performance
- there is a large discrepancy between windows port performance and mac port
- cross-compilation, potentially running under wine
- interested in getting paid for this work, reach me on slack/email if interested!
- thanks to everyone who helped along the way!

##### Questions

- N/A

#### Shipping Web APIs to Customers

##### [Slides](./Slides2023/shipping-web-apis-to-customers.pdf)

##### Notes

- It's important to get APIs right on the web the first time — you can't unship something. Once web developers start using it, it stays
- There's no version 2 of the web. "there's web, and there's more web". It's an additive platform
- "Web 2.0 isn't really a thing. There's web, and then there's more web." Classic
- Consider developer experience when designing API. Is it easy / intuitive? How consistent is it with other APIs? How does it interact with other APIs? Does the API have unexpected behavior for end users?
- Providing feedback on WIP (or complete) specs is really helpful for spec editors — please provide feedback
- As implementors, this is part of the job, not just translating spec to code
- When building web API, building demos (which are different than testcases) is helpful. Show how developers will actually use the API. Show what the end user experience would be like.
- This helps communicate the value of what you're building
- Building demos help discover flaws in your API design
- Step 2: Test your implementation
- Web platform tests are great and should be part of the process, but you should determine if they match the spec, and whether they are exhaustive. Are all cases covered?
- Example: for layout, there are sometimes lots of edge cases not covered, like putting something in too small of a container
- Add a feature flag
- See UnifiedWebPreferences.yaml
- These are recently overhauled, with documentation available to help guide usage
- Measure the quality of your implementation
    - WPTs
    - Interop
    - Performance and power
    - How well do your demos work?
- Test in STP, not just minibrowser. Things like Autofill can introduce surprising interactions not present in Minibrowser
- Test on iOS (and work with Apple if needed)
- Ensure spec + implementations are aligned. If implementations are not aligned, and nobody speaks up, users and developers suffer
- Test your demo
- You should strive to ship three things:
    - Feature
    - Tests
    - Spec changes / improvements
- How to toggle feature flags in Safari?
    - Enable debug menu (docs online to do this)
    - Go to Feature Flags section, should find list of flags with toggles
- Some possible follow-ups after your feature ships:
    - Tools for web developers (e.g. in Web Inspector)
    - Tools for WebKit debugging for WebKit developers

##### Questions

- Demos are not only useful for guiding your feature development, but also for evangelism and helping teach developers about new web technology. You can ping @Jen Simmons or @jond if you have something you feel is worth showing
- Q: Is there a place where we can put such demos on webkit.org?
- A: webkit.org/demos. Also often embedded into webpages / posts / release articles. Reach out to Jen or Jon for help
- Q: What if the spec is under incubation? Would it be good to start upstreaming implementation? i.e. the spec isn't ready yet, changes are still happening
- A: It depends. How much is the spec expected to change?
- As a concrete example, CSS grid went through many iterations. There was an initial implementation from Microsoft that helped guide improvements. Once spec eventually stabilized, more implementors came on board
- Having the early implementation was really helpful in this case
- Different implementors might interpret specs differently, which can help expose ambiguity, ultimately creating a stronger web platform for everyone (edited)

#### Quirks: Kintsugi for the Web

##### [Slides](./Slides2023/quirks-webkit-contributors-oct-2023-dubost.pdf)

##### Notes

- A lot of things on the web are broken for many reasons, causing a negative user experience. This can be due to websites/libraries targeting a specific browser, a new feature, an old feature being removed, a bug fix that websites rely on, or tracking prevention.
- These problems can be rectified with UA overrides (lying about who you are, e.g., modifying the user agent or HTTP header), C++ quirks (working at code-level implementation), and hot-fixes on websites.
- The first browser to push website hotfixes was Opera BrowserJS (pre-Blink) by modifying JS/CSS content after it loaded.
- Source/WebCode/page/Quirks.cpp is a mostly true/false file which is based on domain and simple heuristics. The actual Quirks logic is elsewhere in the C++ codebase.
- Example of a quirk in practice: ikea.com experienced an issue where images at the bottom of the page would not load after a WebKit change. WebKit pushed a quirk that performed a specific, different behavior for that specific website. Ikea subsequently patched the issue, at which point the quirk was removed.
- Quirk implemented by @Brandon at: https://github.com/WebKit/WebKit/pull/6595
- Quirk removed by @Karl Dubost at: https://github.com/WebKit/WebKit/pull/14058
- For UA overrides: HTTP User-Agent + navigator.userAgent.
- Source locations:
    - GTK: Source/WebCore/platform/glib/UserAgentQuirks.cpp
    - Firefox iOS: https://github.com/mozilla-mobile/firefox-ios/blob/main/Shared/UserAgent.swift
    - Safari (via WebKit):
        - WebKit User Agent Overrides API
        - See this bug for more information
- Issues:
    - Quirks aren't clean! They modify the C++ codebase.
    - They're "all or nothing", meaning they're either all on or all off.
    - Long delay from coding quirks to their release (user experience suffers) -- outreach takes time and is sometimes unsuccessful.
    - Websites can end up being blocked by a Quirk if/when they want to change.
    - We don't always get notified if/when a site is fixed -- is it still needed?
- How can we minimize the users' pain?
    - A simpler configuration (plist/JSON/declarative?)
    - Have special power primitives for webpages (could be catastrophic for security and code injection attacks)
    - Dynamic quirks/UA overrides (ones that deactivate automatically)
    - Allowing WebKit GTK/Firefox iOS to use them?
    - Allow specificity further than domain name
    - Update mechanism independent of releases (Opera BrowserJS)
    - Manual QA/testing suites for removing quirks (e.g., Firefox/Opera)

##### Questions

- N/A