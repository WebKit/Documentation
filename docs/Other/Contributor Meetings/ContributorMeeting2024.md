# WebKit Contributors Meeting 2024

WebKit Contributors Meeting 2024

## Schedule

| Talk | Speaker |
|---|---|
| Igalia and WebKit: Status Update and Plans | Mario Sánchez Prada (Igalia) |
| Sony's 2024 Updates | Ryosei Otaka & khei4 (Sony) |
| Handler IC (Inline Cache) Architecture in JSC | Yusuke Suzuki (Apple) |
| WebDriver BiDi | Lauro Moura (Igalia) |
| Shopify and the Web Platform | Yoav Weiss (Shopify) |
| Skia Integration in WebKit Linux Ports | Alex Garcia (Igalia) |
| WebKit Bugzilla Redesign | Jonathan Davis (Apple) |
| How Can We Be Less Assumptive About C++ Std Lib Versions? | Ross Kirsling (Sony) |
| Windows JSC JIT and Future Work | Ian Grunert (Pax Andromeda) |
| IPInt: The In-Place Wasm Interpreter | Daniel Liu (Apple) |
| Being Involved in Standards | Anne van Kesteren (Apple) |
| Shapes, Squircles, and border-shape | Simon Fraser (Apple) |
| MotionMark | Simon Fraser (Apple) |
| clangd | Alicia Boya García (Igalia) |
| Writing-Modes Refactor Work | fantasai (Apple) |

## Talks

### Igalia and WebKit: Status Update and Plans

**Speaker:** Mario Sánchez Prada (Igalia)

*A summary of Igalia's work on WebKit in 2024, our relationship to the project, and plans and priorities for 2025.*

##### [Slides](https://www.slideshare.net/slideshow/igalia-and-webkit-status-update-and-plans-72bd/272669557)

##### Notes

#### About Igalia

- CS Engineer, partner at Igalia - involved in open source for a long time
- Igalia is 23 years old
- Flat structure, worker owned, employee run
- Top contributors in several OSS projects - in all web engines we are top contributors
- Also V8, SpiderMonkey, LLVM, etc.
- Work in standards bodies
- Maintainers of two Linux-based WebKit ports: **GTK** and **WPE** (WPE is for embedded devices)
- Implementation of web standards and JavaScript features in WebKit, including port-independent work on WebCore and JavaScriptCore
- Bugfixing, security, performance, QA, 32-bit support, etc.

#### Users

- **Port users** — native app developers, integrators, embedders
- **Platform providers** — web-based frameworks, often for special tasks
- **Web developers** — we want to cater to their needs as well
- **End users** — often don't even know they are using it: smart TVs, set-top-boxes, video game consoles, medical devices, smart home appliances, even ones without screens, etc.

#### Strategic Goals

- Make sure our product is as useful to as many people as possible in as many situations as possible — compatibility/interoperability first
- Performance and efficiency in small devices — use as few resources as possible (embedded focus)
- QA and security
- Better development tools and documentation
- More efficient collaboration and a healthy open source community
- Fewer architectural differences / less port-specific code — working on integrating Skia

#### Contributions by the Numbers

- Still the **#2 contributor** in terms of commits, after Apple
- Apple has a little over 80% of commits; Igalia is around 13% (increase of ~2%)
- Excluding Apple, about 64% of commits are from Igalia — followed by Sony and Red Hat

#### Recent Web Platform Work

| Feature | Status |
|---|---|
| `content-visibility: auto` (skip painting/rendering offscreen) | Completed, enabled by default |
| Navigation API | Not completed yet, hope to finish by end of year |
| `hasUAVisualTransition` property | Completed, enabled by default |
| Secure Curves in Web Crypto | Worked on |
| Trusted Types | Implementation ready, preparing to enable by default |
| MathML (border, margin, padding support) | Increased WPT score by ~5% |

#### Graphics & Rendering

- **Cairo to Skia migration** — Skia is now the default backend for Linux ports. Cairo was nice in a few ways but unmaintained and ultimately very limiting.
- **Buffer-sharing APIs (DMABuf)** — more efficient
- **GPUProcess enablement** — not done yet, focused on performance, have support for WebGL
- **Graphics pipeline overhaul** — refactoring, buffer uploading, remove Nicosia layer (in progress)

#### New SVG Engine: LBSE

- Meant to replace the current engine
- SVG layers support as a first-class citizen, hardware acceleration, common CSS
- Thanks to **Wix** funding: added support for gradients and patterns, clipping and masking, and markers
- Performance work — reviewed implementation for SVG filters by Said Abou-Hallawa (thanks!)
- With proper dedication, should be able to close the gap on performance

#### Multimedia

- **DMABuf** related work for HW-accelerated video — merged GL-based GStreamer sink
- **WebCodecs backend** — completed audio/video encoding and decoding, enabled by default in 2.46
- Continued work on GStreamer **WebRTC** backends
- Added optional **text-to-speech** backend based on libspiel
- General maintenance

#### JavaScriptCore — 32-bit / ARMv7

- 80% done with OMG support
- Ported WASM BBQJIT
- Some work on the WASM garbage collector

#### New WPE API

- Initial implementation ready, development ongoing
- Historically, using WPE involved many pieces you'd have to get working together correctly — this gives you **one single entry point** to get going quickly and easily
- Added support for external platforms
- API additions for screen management, input methods, gestures, etc.
- Test automation support
- Still a work in progress

#### WebKit on Android

- WPE-based alternative to Android WebView
- Discarded the idea of another port — using the WPE public API
- Focused only on 64-bit architectures (Intel and ARM) for now
- Native integration with Android — hardware acceleration
- Best resource: Jani's blog
- Upgraded to latest version of WPE/Android — APKs available for download
- Added support for WebDriver and WPT tests, instrumentation tests, CI pipeline
- Remote Web Inspector support
- Uses Skia
- Wrapped in a library on **Maven Central** — just declare your dependency and you're off
- HTTP/2 support, bug fixes, etc.

#### QA & Infrastructure

- Spent a lot of time fixing API test failures and assertion-related crashes
- Bots were in very bad shape — spent significant time fixing assertions
- Enabled assertions in release bots, allowing detection of more severe problems (enabled a couple of weeks ago)
- Bots all running (with 1 exception) with Skia enabled
- Working on a new SDK for bots — fixes problems with previous Flatpak solution, provides a reproducible environment you can replicate on your laptop
- Continued same release cadence
- Trying to increase speed of security releases
- Released new SDK based on containers — http://blog.tingping.se
- Contributions to docs.webkit.org

#### Next Steps / 2025 Plans

**Web Platform:**

- Finish and ship **Navigation API** / **Trusted Types**
- **MathML**
- Cross-root ARIA — reference target proposal
- Explore and prototype formatted text with canvas — **Canvas Place Element** proposal

**Graphics:**

- Continue WebKitGTK and WPE graphics rendering architecture work (funded mainly by Comcast and Philips)
- New GPU-based rendering backend architecture on top of Skia
- Activate GPU Process for more rendering targets
- New SVG Engine

**JavaScriptCore:**

- Enable OMG for WASM
- Investigate replacing register pairs for JS values with MIs

**WPE:**

- Finish new WPE API — settings API, accessibility support, API tests, documentation
- Subject to interest and funding: WebKit on Android — aim for production-ready quality
- Bring back ready-to-use WPE images (people want to try WPE and don't know how)

**QA & Tooling:**

- Improve uptime and scalability
- Tooling and documentation improvements

##### Questions

- **John (Apple):** Particularly interested in hearing about Trusted Types. There were some discoveries from Mozilla that the Chromium implementation didn't align with the spec — is there a feeling that they are aligning?
    - **Brian Kardell:** Yes, and there is an Interop proposal for it in 2025. You should ask your representative to support that if it is very interesting to you.
- **Yoav:** Are there Chromium bugs?
    - **Brian:** Yes.
- **Q:** Are you planning on adding a bot to test ARMv7/32-bit?
    - **Mario:** I thought we already have one? Maybe Justin can tell us.
    - **Justin:** Yeah, there is already one... Is it not working?
- **Q:** Is it a perf bot?
    - **Justin:** No.

---

### Sony's 2024 Updates

**Speakers:** Ryosei Otaka & khei4 (Sony)

*Updates for the Sony team's work this year and areas of focus over the coming year.*

##### Notes

#### Team & Products

- WebKit is the current web engine across all Sony products
- Team is split across Tokyo and US
- Tokyo side has expanded in the last year by 2 new members

#### What We Did & 5-Year Plan

**Windows Port:**

- EWS layout tests
- WebDriver
- Playwright team was generous to provide 8 Azure VM instances to expand EWS testing
- Aiming to migrate to Skia

**PlayStation Priorities:**

- CPU rendering stability, so that GPU is limited to games rendering
- Leverage CFI sanitizer more
- Planning to expand the EWS to cover the PlayStation build

**WASM Support:**

- Thank you for enabling the JITless
- Very excited to contribute back and utilize
- Ross continued with TC39 activities and contributions

**GPU Process:**

- Focusing on GraphicsLayer WC — new compositor
- Implement device scale factor
- Media apps are also important users

##### Questions

- **Q:** Are you concerned about JITless WASM, is it up to expectations?
    - **Ross Kirsling:** It is true in the sense it is unclear which scenarios will win for now, but still desire to play with it due to its advantages. Having JSC and not JITless WASM seems incomplete now, and the desire to try and see if different application/usage demand different approaches.

##### Related

- [Every JIT tier enabled for JavaScriptCore on Windows](https://iangrunert.com//2024/10/07/every-jit-tier-enabled-jsc-windows.html) — article by Ian Grunert about his work on Windows + WebAssembly

---

### Handler IC (Inline Cache) Architecture in JSC

**Speaker:** Yusuke Suzuki (Apple)

##### Notes

#### Speedometer 3.0 Improvements

- Speedometer 3 improvement continues from previous year — improved in all areas
- Reminder: data from Ryosuke Niwa's last year's slides showed +25 points in score
- This year: continuously improving, reaching 33 points (up from last year's 25)
- macOS Sequoia Safari 18 achieves roughly 20% improvement against macOS Sonoma Safari 17.6
- Further 20% improvement since Speedometer 3 was announced

#### Major Improvements

- JSC Handler IC
- More SIMD
- Faster rendering tree teardown
- Compositor improvements
- Less costly repainting

#### The Old IC Mechanism

- IC was per-callsite, which was the fastest form for hot code
- Too costly for non-hot code — requires IC code compilation for each IC site
- IC was the fastest form once compiled, but setup itself takes a long time if code is not too hot
- Profiling pointed out too much time spent on IC compilation

#### Handler IC

- Make IC a handler and call this handler instead of jumping
- This allows sharing IC code for one particular case (e.g., structure 1 and offset X)
- Each IC site can chain a linked list of IC stubs

#### Handler IC — Additional Details

- As a latecomer to the party, JSC can take an interesting approach by using its own IC mechanism
- Uses watchpoint mechanism to invalidate IC sites — watchpoint does not invalidate code itself
- Wipe runtime check for IC validity (this is validated at runtime in the other engines)
- Some JSC ICs are super complex and hard to make pre-compiled code
- **Hybrid approach:** generate code in these cases, and reuse it when hitting the same object structure

#### Handler IC — Future Work

**FTL:**

- Considering whether to extend the current IC mechanism to inline collected feedbacks directly in FTL code instead of using current IC
- As a fallback, deploy Handler IC for FTL too
- Long-term goal: use Handler IC everywhere and remove current IC

**LLInt:**

- Would like to remove ad-hoc LLInt IC mechanism and use Handler IC on LLInt too
- Unifying LLInt and Baseline IC to accelerate both

---

### WebDriver BiDi

**Speaker:** Lauro Moura (Igalia)

##### [Slides](https://www.slideshare.net/slideshow/webdriver-bidi-in-webkit-status-updates/272669608)

##### Notes

#### Background

- Joined Igalia in 2020, part of the WebKit team — working on WebDriver
- WebDriver is not a testing framework — it is an automation tool which happens to be used for testing
- Originates all the way back in the 2000s, became a W3C standard in 2018

#### WebDriver Classic

- Main focus was to emulate user actions — issue a request through the driver
- Implemented as HTTP requests (driver as the server), synchronous and language agnostic
- Driver may be accessed remotely (useful for embedded testing / cloud scenarios)

#### Limitations of Classic

- Browser can't notify that some change has happened
- Synchronous approach means you are limited to polling as an unreliable fallback
- Not suitable for long operations
- Both issues have become more impactful in event-heavy applications — a problem for testing today's web apps

#### Prior Art

- Some tools try to solve this by injecting JS code to talk to the browser (like Cypress) — but still has to respect the browser sandbox
- DevTools have become more and more powerful — some tools use the Chrome DevTools Protocol (CDP) for bidirectional messages and event monitoring (like Playwright)
- **CDP** — used by Playwright and Puppeteer, but too tied to Chromium, not a standard — they can change whatever they want, whenever
- Firefox added a subset for its own protocol, but plans to remove support this year

#### Enter WebDriver BiDi

- An industry standard for a new bidirectional API
- Designed as an extension of WebDriver Classic to help transition codebases — allows both mixed and BiDi-only sessions
- Async, using WebSockets instead of HTTP — designed based on experiences with CDP
- There is an editor's draft in the Browser Testing and Tools WG, with a call to consensus to advance

#### Main Concepts

- **Commands** — requests from the client to the server
- **Replies** — results and errors returned from commands
- **Events** — messages from the driver that the client can subscribe to (both global and client-specific)
- **Modules** — groups of related commands and events (like session, input, log, network)

#### Scenarios Enabled

- Logging of console messages and JS errors
- Network request interception (to replace with mock data, for example)
- Observing changes made to the DOM tree (custom push messages from the browser)
- Other scenarios listed in the roadmap

#### Security

- BiDi spec requires TLS encryption
- Opt-in — must start the browser with an automation flag and with an anonymous session to avoid leaking data to the automation script

#### Client Libraries

- Selenium, WebDriverIO, Playwright, and Cypress are all related client libraries working on support — there are open issues

#### WebKit Implementation

- Already good support in Chrome and Firefox, but WebKit is lagging — hoping for good interoperability by next contributors meeting
- Main part of the code is in `Source/WebDriver`
- Uses the inspector protocol, mainly `WebAutomationSession.cpp`
- Imported test suites from Selenium and WPT
- Initial focus: take advantage of mixed session support by implementing new features not covered by Classic
- Added `log.entryAdded` — can get push messages from the browser going
- Hopefully can get this done without having to start rewriting everything in BiDi first
- Using libsoup implementation of the WebSocket driver, but most of the code is port-agnostic
- Commands already covered by the Classic API will be added later in future patches

#### Recent & Upcoming PRs

- Last week: landed the first PR
- Next: under review for dispatching BiDi commands (message parsing)
- After that: event subscription with plain console text messages (submitting for review)
- **Metabug:** https://webkit.org/b/281932

#### Next Steps

- Enable CI coverage (currently skipped)
- Expand coverage of more parts of the spec
- Talked to Blaze Jayne Burg about the possibility of relaying BiDi commands for easier processing
- Might want to send messages directly to the browser

##### Questions

- **Ryosuke Niwa:** Can we rename this feature? "BiDi" is about bidirectional text — this is very confusing.
    - **Lauro Moura:** I agree. Given that it is already a new working draft, I am not sure. Maybe you could require it to be "WebDriver BiDi" always.
    - **Jen Simmons:** +1 that the "BiDi" name is confusing. A rename would be welcome.
    - **Alexey Proskuryakov:** WebDriver BiDi seems only relevant as a name until it's implemented everywhere, and BiDi text layout seems only relevant as long as it's buggy. Hopefully we can simply refer to "WebDriver" and "text layout" in the foreseeable future.
    - **Devin Rousso:** I've always thought of "WebDriver BiDi" as an internal name for this particular architecture/version of WebDriver as opposed to something the wider developer community will know about.
    - **Sam Sneddon:** At a spec level, there are internal "bidi" flags (to distinguish implementations that support only-HTTP, only-BiDi, and both); at a protocol level, the only thing exposed is the "webSocketUrl" capability.

- **Yoav Weiss:** I know that there are some efforts to integrate this with WPT — will this also be supported once all of this lands?
    - **Lauro Moura:** I have not checked yet, but as soon as the support matures in the main browsers, I think we might start to get some movement in this area. The problem is that it's still just a bit of a draft — I don't think we can really make it part of WPT yet.
    - **Sam Sneddon:** There shouldn't need to be any work beyond just supporting WebDriver BiDi for it to work with `testdriver.bidi` for anything using wptrunner's WebDriver executor (which is everything except for Firefox); that said, `run-webkit-tests`/WKTR/DRT isn't using WebDriver in any way, so everything in `testdriver.js` (including `testdriver.bidi`) needs its own implementation.

- **Moe Bazzi:** What type of commands from the client are available that aren't available in Chrome DevTools Protocol?
    - **Lauro Moura:** I have not checked specific commands. I think the biggest thing is that CDP is not a standard, so this is a way to take what we learned there and move it toward a standard — less of a limitation of CDP as I understood.
    - **Devin Rousso:** Part of the reason we did this is because none of the browsers wanted to standardize their dev tools protocol because there are different ideas and needs for those.

- **Devin Rousso:** One of the things worth keeping in mind is that the current Web Inspector design is that it has to route through the UI process — there's always going to be at least that, more than likely.
    - **Sam Sneddon:** Also, providing a means to not go through the UI process means the WebContent sandbox would need to allow inbound WebSocket connections, and it seems unlikely we'd want to loosen the sandbox to allow that.
    - **Devin Rousso:** Though we already launch a special version of the WebProcess when doing automation things, so perhaps we could just tweak the sandbox of that — but I'd probably prefer not to.
    - **Sam Sneddon:** But also, yes, there's a variety of commands that almost certainly need to route to the UI process anyway.

---

### Shopify and the Web Platform

**Speaker:** Yoav Weiss (Shopify)

##### [Slides](https://docs.google.com/presentation/d/12mQUO6cJGmiN56Scb6f6ZRNKcNTsnxrX72QQE3O8T64/edit?usp=sharing)

##### Notes

- Shopify cares about the web, needs the web, and therefore it makes sense to contribute to the web platform
- Mission: "Make Commerce Better for Everyone"

#### Vision

Want the web to be:

- Frictionless
- Commerce
- Secure
- Fast
- Private
- Capable (some capabilities that were disabled due to privacy could hopefully be returned in a privacy-preserving way)

#### Autofill

- Autofill is important — 30% of non-authenticated checkouts use autofill
- Completion rate when autofill works is **41% higher**
- There's an autofill interop issue with addresses due to the dynamic nature of addresses (e.g., need to select the country before the website will show the other relevant fields for that country)
- Submitted a proposal for Interop on Autofill
- Would like to see better UX and privacy for autofill as well — currently websites use hidden fields to capture all the data a browser might autofill and then maybe expose that to the user. This is not a great experience for any party.
- Would love to see more participation from the WebKit community: https://github.com/WICG/address-autofill

#### PCI v4 & Subresource Integrity

- PCI v4 — one of the novel requirements of this payment industry standard is that a website needs to keep track of all its scripts
- Shopify would like to deploy SRI everywhere and add it to various features:
    - ES modules SRI (added to the HTML standard and some browsers)
    - Hash reporting API (TBD)
    - `require-sri-for` (TBD)
    - Signature-based SRI (TBD)
- PCI v4 goes into effect in March, which is why this is important

#### Security

- Shopify worked on **COOP `noopener-allow-popups`** to allow a same-origin document to ensure it cannot be scripted by other documents on the same origin (unless it opened them itself)

#### Performance

- Various kinds of apps — single-page, multi-page, both from Shopify and merchants
- Seeing inefficiencies in how scripts are loaded
- **Import maps** can help here, but import maps have a limitation in that they cannot be mutated
- **Multiple Import Maps** solves the mutability problem by allowing later import maps to selectively overwrite the initial global import map
- https://github.com/whatwg/html/pull/10528 explains the various scenarios in more detail
- Would love to hear opinions from the WebKit community and get the standards-positions issue resolved

#### Real-User Measurement

- A lot of metrics related to "Real-User Measurement" are not available in WebKit — this presents a problem for Shopify merchants
- The major missing APIs are **LCP** (loading) and **Event Timing** (responsiveness)
- Would love to discuss improving that situation

#### Identity

- Starting to experiment with **FedCM**: https://w3c-fedid.github.io/FedCM/
- Would love to see WebKit invest in FedCM as it presents a good experience for when third-party cookies are not there
- Also interested in **fenced frames + unpartitioned data**:
    - Customized login buttons
    - Customized payment buttons
    - Customized discounts/shipping
    - Allows the IDP to prove to the user that things are "ok" despite the merchant and IDP not having access to each other
- Shopify relies on and is excited about **WebAuthn** — there are a couple of UX issues to be raised in the relevant W3C Working Group

#### How Will Shopify Be Involved?

- Attended W3C's TPAC and want to collaborate directly with browser teams on features of interest
- Shopify will also directly contribute features as time allows

##### Questions

- **Brian Grins:** PCI v4 is coming into effect March 2025? Many of these features will not be ready by the time the regulation goes into effect?
    - **Yoav Weiss:** Yes, it's likely not going to be ready, but some of it may be if we put in enough effort. This is going to be an industry-wide problem, so there may be some leniency at first if it's not possible to comply. Philosophy is to be as ready as we can be, as soon as possible.

- **Ryan Reno:** Which web APIs are being used for the metrics on slide 22 (Real User Measurement) and which ones does WebKit lack?
    - **Yoav Weiss:** The major ones are LCP (loading) and Event Timing (responsiveness).

---

### Skia Integration in WebKit Linux Ports

**Speaker:** Alex Garcia (Igalia)

##### [Slides](https://www.slideshare.net/slideshow/skia-integration-in-the-webkit-linux-ports/272669585)

##### Notes

#### History: Cairo Era

- When WebKitGTK was first implemented (~2007), Cairo was the 2D rendering library for Linux — no discussion, it was the library everyone used
- Cairo does the rendering of buffers (CPU), later composited with OpenGL (GPU) via the TextureMapper
- In the beginning this was a very good idea and everyone was happy — no one was doing GPU-based rendering, so Cairo performed well
- Over time, Cairo brought challenges: no one was developing it anymore, rendering features were missing and no one implemented them
- 2D rendering became the main performance bottleneck compared to other browsers
- Cairo once had a GPU backend, but it was abandoned soon after
- Advantage of Cairo: very stable API. Disadvantage: easily got stuck

#### Exploring Alternatives

- ~6-7 years ago, started looking for alternatives — none met expectations
- Skia was considered but had many cons: non-stable API, no official releases, no packages in Linux distros
- Naively tried to convince Skia devs to overcome those problems — didn't work
- Started an in-house implementation for a GPU-enabled 2D rendering library
- Spent a lot of time exploring, implemented several algorithms, and eventually got it working
- Performance was impressive — even better than Skia GPU in some cases
- Unfortunately found quality-related problems: issues with triangulation of bezier curves, antialiasing, corner cases
- Had to balance resource constraints (small team) — development + maintenance would be too much

#### Re-evaluating Skia (End of 2023)

- Re-evaluated Skia right after the previous WebKit Contributors Meeting
- Talked to the Skia team at Google again about the sore points
- Opened a good communication channel — realized they had experience maintaining other Google libraries (e.g., libwebrtc)
- Convinced that the issues identified before were not as much of a problem as thought
- Decided to go ahead (December 2023)
- Secured time and financial support from customers

#### Initial Prototype

- Goals:
    - Use an external compilation of the library
    - Run and evaluate performance using MotionMark benchmark
    - Test on desktop and embedded device (iMX8)
- All this took **less than 1 month** — could already render pages and see fonts
- Performance improvements were really significant: GPU-based Skia scores **doubled** compared to Cairo
- Learned that depending on hardware, GPU rendering was not always a good idea
- Even in CPU-based scenarios, Skia was similarly performant to Cairo (surprising given Cairo was unmaintained for 10 years)
- Codebase was simplified, could implement new features

#### Landing Upstream

- Created an initial patch ready for upstream (CMake compilation of Skia inside WebKit)
- Integrated in the third-party directory
- Talked to people at Google, Apple, Red Hat, and Sony — everyone was happy and positive
- February 2024: announced on the webkit-dev mailing list

#### Achieving Feature Parity

- Split the task into goals:
    - All basic features working, no major regressions
    - Core geometry operations, gradients, text rendering, multimedia support
    - WebKit Test Runner support and layout tests — stable testing environment, layout tests passing at acceptable level
- **Finished one month ahead of schedule** (April instead of May)
- Next step: enable Skia in the next stable release — deadline July, everything ready for September release
- Before end of June 2024, everything was ready
- Flipped the switch — all bots running tests with Skia. Only one bot remains using Cairo (compilation check only, no tests)

#### New Features (Beyond Cairo Parity)

- Accelerated Filters — improves performance of visual effects
- Accelerated Offscreen Canvas — enhances offscreen rendering capabilities
- Accelerated ImageBitmap — speeds up image processing tasks
- Color spaces support — advanced color management previously unsupported in Cairo
- Completed all before end of May

#### Big Endian

- Cairo supports Big Endian, but Skia does not
- Some distros support Big Endian
- Skia devs said they won't support Big Endian
- Explained this is a regression — if you need Big Endian, you need Cairo. Not happy about it, but it is what it is

#### Release

- **September 2024:** released WebKitGTK and WPE 2.46 with Skia enabled by default

#### Current Architecture

- Replaced Cairo with Skia; composition still done with TextureMapper
- Not an optimal architecture for GPU-based rendering, but performing very well
- Desktop: GPU backend by default. Embedded (WPE): CPU backend

#### MotionMark Results

- **Cairo:** 162.57
- **Skia GPU:** 617.42
- Some tests not faster (e.g., Images)

#### Future Work

**Short-term:**

- Maintain a cadence of updating Skia in the WebKit repo every 2 weeks
- Add color palette support
- Complete color spaces implementation
- Test threaded GPU rendering — already have a prototype using multiple threads (previously had to disable threaded GPU due to context issues)
- Hybrid GPU rendering — decide at runtime whether GPU or CPU rendering is used (already have a patch being tested)
- Implement the rest of SVG filters

**Long-term:**

- Refactoring of GPU architecture
- Unblock the main thread from composition and enable the GPU process
- Test bigger changes, refactor and simplify the code
- Currently using the old Ganesh backend (per Google's recommendation) instead of the newer Graphite backend — would like to test other backends
- Big Endian support remains an open discussion

#### Complementary Work

- New WPE API
- Buffer sharing/fencing
- New container SDK release
- Profiling tools (sysprof)

##### Questions

- **Simon Fraser:** Have you seen differences in rendering quality?
    - **Alex:** No, we didn't detect any rendering quality issues. When rebasing tests there were small differences, but that's something we can check. You can find differences even between CPU and GPU within Skia itself. The only glitch we fixed about 2 weeks ago was about font rendering, but it was more about system settings as Cairo previously didn't pay attention to the system. Other than that, we didn't see anything.

- **Q:** Have you found some regression in the size of the library?
    - **Alex:** Yes, there is a regression in build time (takes more time). Initially we didn't know what to compare with, so we checked libwebrtc and ANGLE and realized Skia was much smaller. Specifically about binary size — we work in embedded so a few MBs is too much — however Skia was not the main thing to blame for the increase. While Skia increased it a bit, the main blame is on other parts of WebKit. We also realized the growth of WebKit over the last 2 years has been relevant and we are trying to handle that problem.

- **Q:** What architectures does WebKit support that are Big Endian?
    - **Alex:** We don't actively support Big Endian as a team, but some people are compiling WebKit for Big Endian architectures, mainly because some distros do. Cairo folks are adding a default for Big Endian, but Skia does not care about that. If someone cares and wants to support it, I'm all ears. When talking to Firefox people, distro developers say they are using some patches to support Big Endian with old patches, and distros don't seem to be sure about this either.

---

### WebKit Bugzilla Redesign

**Speaker:** Jonathan Davis (Apple)

*No notes available for this talk.*

---

### How Can We Be Less Assumptive About C++ Std Lib Versions?

**Speaker:** Ross Kirsling (Sony)

##### Notes

- Working on WebKit since 2017 and TC39
- New features are exciting — no exception to this
- C++ is chaotic. In a nice normal language the compiler has a standard library, but C++ is not a nice normal language
- It's much easier for a platform to commit to compiler support than a standard library
- For the last two years, every time a C++20 feature was added, had to go add it

#### Example: `optional::transform`

- `optional::transform` — the method which a normal language would call `map`
- Is it a C++23 standard library feature? Yes, and it has a feature check with a few values
- Does it pull its own weight? Maybe not — a one-liner becomes a one-liner
- Can we add it to WTF? We can and should — it's what we used to do before C++20

#### EWS Coverage

- There is a valid complaint that you would not see anything but green
- As per the Sony update, would like to prioritize an EWS

##### Questions

- **Q:** Do we want to not use a C++23 feature in the short term?
    - **Ross:** Seems like a difficult ask, but want to talk to the community about the situation and its complexity. Use of Clang does not imply use of a particular standard library. Just because something is in WTF, a platform might still want to use the standard library. I don't want to say not to use C++23 features. Alex has been more interested in C++23 features. That would be a solution but seems drastic — maybe an ease-in approach rather than all-or-nothing.

- **Q:** What's the suggested way to deal with these?
    - **Ross:** This is just an idea — you could imagine we have a similar function in WTF, so we could have something like `mapOptional`.
- **Q:** Would WTF be a wrapper around the C++23?
    - **Ross:** That is my suggestion.

---

### Windows JSC JIT and Future Work

**Speaker:** Ian Grunert (Pax Andromeda)

##### Notes

- Works for a startup, Pax Andromeda
- Working on Windows JIT for JavaScriptCore — will talk about plans for the year to come

#### Background

- Baseline JIT broke, so JIT was disabled on Windows
- Free to experiment on Windows JIT without fear of breaking things
- Dropped support for MSVC and went all in on Clang — laid out a few opportunities that Clang could improve

#### Key Changes with Clang

- **`sysv_abi` function attribute** — allows annotating a C++ function so callers use the System V ABI instead of the MS ABI, allowing the same calling convention as Mac and Linux ports
- Inline assembly now matches the other platforms
- With the System V boundary, can now share codepaths for entrypoints between the interpreter/JIT code and the C++ boundary
- Can use the same register mapping — no difference in callee/caller register assignments
- Clang supports GAS-style inline assembly in AT&T syntax; previously only had Intel support, so offlineasm had to do extra work just for Windows
- offlineasm also had a special Windows mapping for registers — now can get rid of those

#### Feature Parity Achieved

- **Baseline JIT, DFG, and FTL (new!)** on Windows
- LLInt, BBQ, OMG for WASM
- YarrJIT and all regex optimizations work
- CSS Selector JIT works too
- **It can run Doom!**
- Currently faster than Firefox, not quite as fast as Chrome, but there are things to close that gap

#### Code Cleanup

- Got rid of 169 `OS(WINDOWS)` and 42 mentions of `MSVC`
- Got rid of `X86_64_WIN` in offlineasm — no need to distinguish `X86_64` or `X86_64_WIN`

#### What's Next

- **libpas** — get custom allocator working on Windows port
- **Skia** — see if they can also remove Cairo
- **Cross-compiling on Linux** — a lot closer now that they're not relying on the Microsoft assembler
- **EWS** — add coverage for Windows JSC
- **Media Streaming / WebRTC** — want to match Linux port
- Long laundry list of things that never got enabled on the Windows port

##### Questions

*No questions.*

---

### IPInt: The In-Place Wasm Interpreter

**Speaker:** Daniel Liu (Apple)

##### Notes

#### Design Overview

- Current WASM interpreter: LLInt
    - LLInt bytecode is its own representation to generate
- IPInt interprets the WASM binary **in place**, just with some metadata
- Metadata holds things like:
    - Resolved i32 constant values
    - Pre-calculated branch targets
- Easy instructions like `i32.add`, `local.get` need no metadata

#### Benchmarking (JS2)

| Benchmark | Startup Improvement |
|---|---|
| hashset | +16.7% |
| tsf | +11.5% |
| richards | +0% |

- Startup is really good to begin with — helps with startup time due to less generation

#### Looking Forward

- Core of IPInt was done summer '23
- Plans for performance optimization and new WASM exception specs

#### Optimizations

- Reduce register usage
- Dispatching opcodes with one load
- Opcode load hoisting
- Varying alignment of instructions
- Determining "real target" of branches (not jumping to a purely control-flow instruction)

#### WASM Extensions

| Extension | Status |
|---|---|
| WASM 2.0 (non-SIMD) | Done |
| Atomics | Done |
| Tail calls | WIP |
| Typed func refs | Planned |
| GC | Planned |
| `try_table` exceptions | Planned |
| SIMD + relaxed SIMD | Planned |

---

### Being Involved in Standards

**Speaker:** Anne van Kesteren (Apple)

##### Notes

- WebKit Standards Positions: https://github.com/WebKit/standards-positions/issues
- Slack channels: `#standards` (and `#standards-github` for bot noise)

---

### Shapes, Squircles, and border-shape

**Speaker:** Simon Fraser (Apple)

##### Notes

#### CSS Shapes

- CSS has notions of basic shapes like `circle()`, `ellipse()`, `polygon()`, ...
- These shapes can be used in CSS properties like `clip-path`, `shape-outside`, ...

#### `shape()`

- `path()` allows specifying a CSS shape using SVG paths — two problems: SVG paths are confusing to understand, and the paths are in absolute units
- `shape()` allows specifying a shape the same way as `path()`, but in an easier-to-understand form
- Ongoing discussion on the syntax of `shape()`
- Demo: clip path with a shape made by `shape()` — done on the GPU
- `shape()` is also animatable
- Implemented behind a flag so people can try it out — syntax still in flux

#### `border-shape`

- `border-shape` allows setting the border — in the original form, it allows specifying the corner shape, border radius, etc.
- Extended `border-shape` to allow specifying the shape of a border as a CSS shape
- Also extended to allow specifying the shape as **two CSS shapes** — one for the outer edge and one for the inner edge
- Demo: single-path `border-shape` with animation that changes the border shape
- Demo: two-path `border-shape` — paths are responsive to window resizes (using relative units). Animation also works.
- Still being discussed in CSS WG: https://github.com/w3c/csswg-drafts/issues/6997
- `border-shape` is not merged yet

#### Squircle

- `squircle` is a new CSS shape — a hybrid between a circle and square
- Underlying implementation is a "superellipse"

#### Implementation Changes

- Boxes are not just rounded rects
- Hit testing must use a path

##### Questions

- **Q:** Does `border-shape` affect inline layout?
    - **Simon:** There's been a proposal, but it might make hiding text content too easy. What I presented today didn't affect layout — it's just different ways to paint the border.

- **Q:** How does this affect hit testing?

---

### MotionMark

**Speaker:** Simon Fraser (Apple)

##### Notes

#### Overview

- MotionMark at browserbench.org
- Designed to benchmark graphics on the web — not testing hardware-accelerated animations like WebGL, WebGPU
- Trying not to overlap with Speedometer

#### Current Version (1.3.1) — Subtests

| Subtest | Description |
|---|---|
| Multiply | Rotating divs with border-radius |
| Design | Text with tables, tests text rendering |
| Leaves | Small images with transforms |
| Suits | SVG test, uses clips and masks |
| Canvas Lines | 2D canvas line drawing |
| Canvas Arcs | 2D canvas arcs |
| Canvas Paths | 2D canvas path drawing |

- Good spread of what is being tested for

#### Scoring

- Ramping the complexity of a scene until frame is stable at 60fps
- Contrast with Speedometer: measures the wall clock time it takes to run a fixed workload

#### Scoring Limitations

- Only measures work on the main thread — doesn't measure anything off the main thread (e.g., off-process compositing)

#### MotionMark 1.4

- Doesn't fix the scoring problem, but aims to be achievable within 12 months and move to an open governance model
- Changes:
    - Consolidate canvas subtests
    - More HTML/CSS coverage
    - More SVG (with D3)
- New HTML subtest with box shadow, text shadow, images, etc.
- New canvas subtest that exercises a number of APIs like gradients, images, texts

#### MotionMark 2

- Timeline: long term, >12 months
- Possibly new scoring mechanism
- Might be WebDriver-driven to measure performance off main thread — but it would mean tests can't be run in-browser
- May include WebGL/WebGPU benchmarks

##### Questions

- **Q:** Will there be tests to exercise image decoding of different formats?
    - **Simon:** Usually decoding is only done once on warmup and subsequent display will just render the decoded image. Technically we can auto-generate test images to test image decoding, but there can be thousands of images on a page.

- **Q:** How about very low performance devices where score is always 1?
    - **Simon:** Then the test is not good.

- **Q:** What about 120fps `requestAnimationFrame`?
    - **Simon:** We changed the test so it'll show if rAF is 60fps or 120fps. You can't compare scores between 60fps and 120fps rAF.

---

### clangd

**Speaker:** Alicia Boya García (Igalia)

##### [Slides](https://ntrrgc.github.io/2024-wcm-clangd-lightning-talk)

##### Notes

#### What Is clangd?

- A code indexer for C and C++
- Uses the same parser as the Clang compiler
- Big difference in your workflow — find where a method is used, go to definition, find compiler errors straight in the code
- With clangd you can feel C++ is another language
- Even able to keep up with WebKit, having reasonable performance to use even on a laptop
- Indexing takes a long time (like building WebKit) but it's a background process and things stay pretty responsive
- Takes a few seconds to analyze a single `.cpp` file — feels instantaneous

#### Availability

- Part of the LLVM tree — binaries can be downloaded from the LLVM project and work on all major systems (Linux, macOS, Windows)
- Uses the **Language Server Protocol (LSP)** — an effort from Microsoft to decouple language support from the editor itself
- LSP is a success with implementations for many editors — unfortunately, Xcode does not support LSP

#### WebKit Support

- clangd support is already upstream and should work both with CMake and Xcode
- With CMake: generated automatically
- Xcode: works as well, no problems

#### Setup

**Linux (Container SDK):**

- Recommended to use the WebKit Container SDK (the new SDK)
- Use VSCode inside the container — everything works out of the box and installs all extensions automatically
- If you don't get autocompletion with WebKit, it's a bug — please report or ping Alicia

**macOS with Xcode:**

- A bit clunkier, needs an extra step:
    ```
    make release EXPORT_COMPILE_COMMANDS=YES
    generate-compile-commands WebKitBuild/Release
    ```
- Documented in the wiki: https://trac.webkit.org/wiki/Clangd#macOS1

**Other setups:**

- Doesn't mean it won't work — means you'll have to set it up yourself, but it's worth it

#### New: Auto-Setup Infrastructure

- Provides more useful defaults, bigger chances for things to work right out of the box
- Auto-configures the `.clangd` configuration file, tweaked and adapted for your OS
- Things get auto-generated when building WebKit for the first time
- Auto-updates the file when needed (e.g., newer compiler support) — you can also modify it yourself
- For CMake builds: creates `update-compile-commands-symlink.conf` that adapts to src dir / build dir automatically
- Considers different types of builds (e.g., release and debug) and configures them accordingly

#### Tips

- `clangd --enable-config --check=your_source_file.cpp` is extremely useful for troubleshooting indexing problems
- clangd adds includes automatically — disable with `--header-insertion=never` passed to clangd
- If a `.cpp` file is missing an include but compiles in unified builds, clangd will still complain on non-unified builds
- clangd 18 highlights unused includes

---

### Writing-Modes Refactor Work

**Speaker:** fantasai (Apple)

##### Notes

#### Background

- Writing mode is all the info to draw text
- `writing-mode` is the block flow
- `direction` is the bidi orientation
- `text-orientation` is the orientation of the glyph

#### New WritingMode Object

- Many methods are now gone
- New `WritingMode` object: `RenderObject/RenderStyle::writingMode()`
- Many methods were moved into that object
- Only **1 byte**
- Designed to be super fast to answer questions about writing mode — lots of bit manipulation
- Booleans for common logic, enums and computed value getters

#### "What Is Left?"

Many meanings for "left":

- **Physical left** — left side of the page
- **Logical left** — zero coordinate of the box

#### Key Methods

- `isLeftToDirection` is gone
- `isBidiLTR()` — text layout; returns true for LTR text, use this for typesetting/layout operations
- `isInlineLTR()` / `isInlineTopToBottom()` — map inline side of the box
- `isLogicalLeftInlineStart` — is this the start side of the box?
- `computedTextDirection()` — computed value of LTR/RTL, usually the same as `isBidiLTR`. Should call this outside of layout.
- `isLogicalLeftLineLeft()`
- A lot of functions for matching/mismatching

#### Coordinate Notes

- Discussion of flipped/inverted coordinates

#### Bottom Line

- New `writingMode` is efficient and easy to pass around
- Use the query methods — don't write custom logic
- Add queries if you need new ones

##### Questions

- **Q:** Can you go over the difference between the different methods?
    - `isBidiLTR()`: returns true for LTR text — use this for typesetting, layout operations
    - `isInlineLeftToRight()` / `isInlineTopToBottom()`: mapping inline side of the box
    - `isLogicalLeftInlineStart`: whether this is the start side of the box
