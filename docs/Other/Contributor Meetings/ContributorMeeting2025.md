# WebKit Contributors Meeting 2025

WebKit Contributors Meeting 2025

## Schedule

| Talk | Speaker |
|---|---|
| Igalia and WebKit Status Update and Plans | Mario Sánchez Prada (Igalia) |
| Sony's 2025 Updates | Stephan Szabo (Sony) |
| Memory Integrity Enforcement in JavaScriptCore | Daniel Liu (Apple) |
| Memory Safety Roadmap (Year 2) | Geoffrey Garen (Apple) |
| Advancing Cloud Gaming: The GeForce NOW 2025 and 2026 Roadmap | Sun Shin (Nvidia) |
| JSC Regular Expression Engine | Michael Saboff (Independent) |
| Improving the WPE Port on Android | Adrian Perez de Castro (Igalia) |
| How to Not Make Bugs (in JSC), and the Future of 32-bits | Justin Michaud (Igalia) |
| Enabling Swift in Your Port | Adrian Taylor (Apple) |
| WebXR in Android & Linux with OpenXR | Sergio Villar Senín (Igalia) |
| WebDriver BiDi | Blaze Jayne Burg (Apple) |
| Performance Profiling with samply + JavaScriptCore | Yusuke Suzuki (Apple) |
| Wrapping Up Unowned UTF8 C Strings: CStringView | Xabier Rodríguez-Calvar (Igalia) |
| Largest Contentful Paint | Simon Fraser (Apple) |
| Strict Memory Safety in Swift | Doug Gregor (Apple) |
| Site Isolation | Alex Christensen (Apple) |
| WebDriver BiDi Demos | Lauro Moura (Igalia) |
| MathML Core in WebKit | Frédéric Wang (Igalia) |

## Talks

### Igalia and WebKit Status Update and Plans

**Speaker:** Mario Sánchez Prada (Igalia)

##### Notes

#### About Igalia

- Mario is coordinating the Igalia WebKit team, and other teams in Igalia collaboration
- Igalia is an open source consultancy, people working in different projects and in multiple countries
- Igalia started 16 years ago contributing to WebKit
- Igalia created WPE to develop a WebKit port that does not depend on a toolkit, we work in web standards too

#### Users

- The linux ports are used by different people in multiple scenarios: port users, platform providers, web developers and end users
- Depending on the usage every user has different requirements and expectations
- WebKit WPE runs in a lot of different devices: set-top-boxes, home appliances, GPS, audio conferencing systems, systems without screens, digital signage, QA and testing
- Thinking about all these users and devices we define our goals

#### Strategic Goals

- The goals we define are: compatibility, performance and efficiency, quality assurance and security, development tools and more efficient collaboration
- We created a new SDK used in the QA bots nowadays
- We did effort last year to reduce the port specific code to align with other ports more

#### Contributions by the Numbers

- Apple 80% Igalia 11% Sony 2% RedHat 0.44% other 5.33%
- Removing Apple from the picture we can see the same information we saw last year, Igalia gets to 60% of the contributions

#### Web Platform

- Reference target fix for cross-root ARIA, Trusted Types, Secure Curves, MathML and WebXR
- Big effort in WebXR, supported in the Linux port including AR module, it is supported in linux and android
- Command invokers, Popover and Dialog additions, Close Watcher
- Igalia added a web with a report of the specifications that WPE supports

#### Graphics

- Very important in embedded, refactor of the graphics pipeline, last year WPE moved from skia
- Removed Nicosia abstraction and heavy refactor
- Use skia DisplayLists to record
- Threaded GPU painting and hybrid mode
- Added damaging tracking all over the pipeline
- Added explicit fence support, improved format negotiation for buffers, AHardwareBuffer support Android, it enables WebXR in Android and the use of the new WPEPlatform API, enabled GPUProcess by default in WebGL
- This improved performance using MotionMark figures, we improved a lot in the rpi4, the Font Design test is improved a lot and we are continuing adding improvements with new proposals we will see later

#### Multimedia

- One of the main usages is the set-top-boxes, the multimedia pipeline is important, and we maintained all the code around this area. In polls we run people vote multimedia as one of the most important features for WPE

#### JSC

- Work in Temporal API, finishing in the next months
- Work around memory profiling and to detect leaks
- Added support for sysprof and samply for armv7
- Work around wasm for 32-bit
- JSC unification of 32-bit and 64-bit, the idea is to simplify maintenance and share more code
- It started the implementation and it would be one of the main focus in the next months

#### New WPEPlatform API

- New way of using WPE, simplifies the usage, it does not require external libraries
- It is almost complete the API, added multiple new features
- Headless, DRM and wayland are supported by default inside WebKit
- Added API tests
- Around June switched the bots to test this new API

#### WebKit on Android

- wpe-android is not inside the WebKit tree, it is a WebView for Android
- This year most of the patches required for wpe-android were ported back to WebKit
- Things like AHardwareBuffer or ASharedMemory which is a precondition for the new API
- At this point there are no downstream patches in the wpe-android project
- Updated to the latest versions of the NDK
- It is experimental and best effort

#### QA

- Last year the new SDK was presented
- It is a container that can be used for development to replicate easily the environment
- Now the bots are using the SDK
- Added a scalable cloud-based infrastructure, using kubernetes with an autoscaler to add or remove resources
- It should allow more easy maintenance and a central place
- A lot of work in gardening, in particular around July
- Closing the gap from WPE and GTK
- The gap is smaller between GTK and WPE
- Skipped tests is reduced in WPE
- As a consequence after June the ratio of interaction runs was flat for WPE
- Between March and June there were a lot of failures from Korean and Chinese, and that was causing problems
- It had problems because linux ports had more failures

#### Security

- Adding more releases, added more security releases, in the same day of the embargo
- Some of these releases reach the linux distributions really fast
- WPE dropped libsoup2 support, reducing the attack surface
- Improved the usage of smart pointers
- Enable the warning for unsafe usage

#### Plans

- **Web Platform:** more work around MathML and Close Watcher API, WebXR work
- **Graphics:** implementation of the abstraction of the RunLoopObserver, refactor of the threaded compositor, enable the GPUProcess for other things not just WebGL, remove the cairo support (there is still a bot testing it, main problem is BE architectures that depend on WebKit, there is a plan forward)
- **Multimedia:** continuistic work in this topic
- **JSC:** finish the Temporal implementation, unification of 32-bit and 64-bit, switched encoded JS value, finish IPInt for 32-bit, improve memory in long running applications (running WebKit continuously for months, in these cases it is important the memory management)
- **WPEPlatform API:** plan to release the new API for the next version 2.52
- **Android support:** complete migration to the WPE Platform API, integrate with testing infrastructure, adding bots
- **Quality Assurance:** finish migrating to the new cloud-based infrastructure, migrating bots
- **Security:** good release cadence, more smart pointers, etc.

##### Questions

- **Ian:** Move to libsoup3 for the network stack in GTK and WPE, are you going to migrate to a library that is closer to windows such as curl?
- **Mario:** Not really, we are focused in linux systems
- **Yusuke:** Typical application that is using wasm that are being used nowadays in your port?
- **Justin:** The best example we have is Amazon Luna, there is other stuff but we need to get more details and we will share with you when we have it
- **Yusuke:** That would be great because that insight can help to decide what to improve from Apple JSC team
- **Geoffrey Garen:** Do you deliver source code and binaries?
- **Mario:** If there is no downstream changes we provide a tag or release, with the code, they compile the image, in some situations they have downstream patches and they add them on top. The way we work is that we implement downstream patch and we move soon to upstream, reducing the downstream patch as much as possible. The customers use their own repository with a reduced delta and they drop everything. We never ship binaries, it is always the code
- **Basuke:** What does unification about 32-bit and 64-bit mean?
- **Justin:** There is a talk about that
- **Adrian:** Answering about the curl usage, we use libsoup for testing, client and server, with curl we still would need still the server part
- **Andrew Fryer:** May I ask who is working on profiling tooling (samply + sysprof)?
- **Adrian Perez de Castro:** Also we maintain libsoup, and it integrates well with the rest of the libraries in our ecosystem (gobject-based), and we expose some Soup types in the public API, and switching to curl would cause an ABI+API break, which we would rather avoid.
- **Alex Garcia:** Justin is the one that is working on that (Justin Michaud)
- **Adrian Perez de Castro:** Also Georges Stavracas has been working on the Sysprof integration, and in Sysprof itself (for example to optimize it so it can ingest and filter the huge amounts of trace data generated by WebKit)

---

### Sony's 2025 Updates

**Speaker:** Stephan Szabo (Sony)

##### Notes

- General info - use WebKit on media applications, Paramount+, Peacock, etc.
- Less activity this last year, activity is around CI, Windows handover, build fixes, some JS features, team mostly working downstream to support media applications
- Discussion on team structure, Tokyo and SF
- Lost engineering resources to other projects
- SF development very upstream focused, Tokyo side more focused on downstream
- Lost more engineering resources to other projects
- Resources redirected to CI/CD to help prevent breakages
- Good news: reexamining priorities for web engine, looking at hiring new people to work on WebKit, looks like a rebuilding year for the team

---

### Memory Integrity Enforcement in JavaScriptCore

**Speaker:** Daniel Liu (Apple)

##### Notes

- As Maciej mentioned, Memory Integrity Enforcement shipped recently, Daniel will give a brief introduction to what it is
- MIE is a collection of memory safety defenses that form a "comprehensive memory safety defense", hardening the memory allocators to be more secure
- MIE relies primarily on a hardware extension, Enhanced Memory Tagging Extension (EMTE), or alternatively MTE, which is extended with defenses against speculative execution attacks
- MTE makes use of the high bits of pointers, which normally use only 48 bits per 64-bit word, to store a 4-bit "tag"
- Different allocations get different tags, which are stored in the pointer, and picked by the memory allocator
- Tags are also stored in backing memory, which allows us to catch out-of-bounds accesses - if a pointer with one tag reads an adjacent object with a different tag, a "tag mismatch" is raised, faulting the process
- MTE is implemented in JavaScriptCore/WebKit in the libpas level, the allocator used by most WebKit objects
- MTE is enabled by default on the iPhone 17 hardware generation, and its implementation has landed in open-source
- When we allocate an object (via `fastMalloc`), we start by creating a random 4-bit tag for the allocation, via the macro `PAS_MTE_CREATE_RANDOM_TAG`.
- Next, the tag is written into all granules (16 bytes) of the object, using the `PAS_MTE_SET_TAG` macro.
- Each 16-byte granule gets a 4-bit tag, so tagged objects have a 1/32, or ~3% memory overhead.
- Realistically, not all objects are tagged, so the actual overhead is less.
- For one, objects are only tagged on compatible hardware platforms - the iPhone 17 family.
- Next, objects marked as "compact" are not tagged under MTE. These are objects whose pointers are compressed, meaning they have no room to store nonzero tag bits.
- The stack and code are not tagged.
- Tagging also depends on process - the privileged (non-WebContent) processes tag allocations up to a size of 32kB. In WebContent, allocations are tagged up to 1.6kB, since it's more performance sensitive.
- System malloc (non-libpas/not using `fastMalloc`) allocations are also tagged up to 32kB.
- What do you need to know to develop WebKit under MTE? Mostly, you shouldn't modify the tag bits - the 4 bits 56-60 in the pointer word.
- If you do need to mess with these bits, most commonly to represent a compact/packed pointer, make sure the types you are pointing to are compact-allocated, via the `WTF_MAKE_COMPACT_*_ALLOCATED` family of macros. This guarantees the objects are given a zero tag, which can usually be trivially recovered when, say, decompressing a pointer.
- The Xcode Instruments app has some useful counters and metrics for debugging MTE, if you run into high overhead or bugs.
- Marcus Plutowski is a good point of contact for MTE questions or issues.
- There are also some public Apple blog posts about the feature, that you can use as reference: https://security.apple.com/blog/memory-integrity-enforcement/

##### Questions

- **Q:** For currently untagged objects (i.e. strings), what other types do we want to tag in the future? In what priority?
- **A:** Not sure, Marcus would be a good person to ask.
- **Q:** If the system allocated stuff is getting tagged, does that apply to WASM memory regions?
- **A:** No, they're bigger than 32kB
- **Q:** On Chrome, there's partition alloc, which does similar things. Is there anything special needed to adopt MTE?
- **A:** No, if the memory is a big region (>32kB) being allocated all at once, then the system allocator will leave it untagged. Unsure if the 32kB threshold is likely to change in the future. (Note-taker's note: this can also be decided at mmap time - if you mmap memory from the system, it won't be tagged, unless you explicitly ask for it)
- **Q:** Any information about performance overhead with regards to speed?
- **A:** It's been brought down from 3%, but can't share a specific answer. It's being looked into actively.

---

### Memory Safety Roadmap (Year 2)

**Speaker:** Geoffrey Garen (Apple)

##### Notes

Check-in on Year 1 of this roadmap.

Motivation is clear: there's a large and growing target on WebKit, as browsers are a large attack target. Memory safety is important to protect your users and distinguish yourself, and hopefully is a shared goal for all of us. We're all willing to work together for memory safety, unlike other communities.

Categories of memory safety bugs:

- Pointer bugs (lifetime, bounds, type)
- Undefined behavior

We're not talking about "being careful" here: if it's not safe, it should not compile, and what is safe should be built-in.

#### Two Main Components

- **Broad:** upgrade our code quickly and in-place: Safer C++ rules out classes of memory safety bugs from the start. We have too much code to rewrite, and rewriting introduces new bugs.
- **Deep:** write code that has no exceptions for memory safety and no UB: Swift-C++

Safer-C++ helps us rewrite our code quickly, and Swift-C++ allows us to verify memory safety. We can utilize Swift-C++ in our most at-risk code (for example, IPC).

Main difference between these is syntax and quality of enforcement.

#### "Are We Done Yet?" — Safer C++

Plan was to enforce reference-counted lifetime, bounds, and type checks on downcast through compiler checks and bounds-checked structures.

- 96% of all files enforce reference-counted lifetimes and bounds checking
- 99% enforce type checks on downcast
- We're way faster than expected, and thank you to everyone!

What's next?

- 100% file coverage: all files should enforce these by default
- Best to focus on the current set of properties: provides clarity on the bug
- Static analyzer bug fixes: avoid false positives and false negatives
- Platform-specific EWS bots: only have a macOS bot, but will be adding iOS soon, and hopefully other platforms can adopt this

Exceptions to Safer C++:

- Borrowed lifetimes: we don't have great enforcement for this
- Undefined behavior: no defense against this, and sometimes it bypasses our bounds checks

Check out CppNow 2025 talks:

- "C++ Memory Safety in WebKit"
- "Undefined Behavior From the Compiler's Perspective"

#### Swift-C++

Plan: prototype WebGPU Swift-C++ prototype, on Apple ports only. WebGPU is hard, and if we can get it working, it's a good first test for other parts of WebKit.

Plan: develop "Strict Safety", where the language will force you to use "unsafe", and integrate this with C/C++/Obj-C.

Motivating example:

- IPC 1: create buffer
- IPC 2: update buffer contents, but with too many bytes

How did it go?

- Pretty well! ~4000 lines of code, passes all tests
- Migrated build systems, toolchains, and software delivery; turned on in mainline!

Language Integration:

- We intentionally don't convert the whole class to Swift: we incrementally migrate member functions.
- C++ side:
  - `SWIFT_SHARED_REFERENCE` marks the object as reference-counted
  - `HAS_SWIFTCXX_THUNK` indicates the function is implemented in Swift
  - `SWIFT_PRIVATE_FILEID` indicates the Swift functions get access to our private member variables
- Swift side:
  - `extension` indicates we're implementing the class
  - `SpanUInt8` is a C++ span (declared via using declaration)
  - We need to return unsafe in this case since the span doesn't know its lifetime (we have some work to do on this)

Had roughly 154 unsafe expressions when we turned it on. With strict safety mode, we are now at 21; we're working on driving it down to 0.

It's ambitious:

- "unsafe" in a memory safe language means we can't explain what we should do here
- Switching cost: adding a new programming language to WebKit is hard; we need to justify its presence and demonstrate we don't need to keep trying out newer languages that shave down on unsafety
- Lots of people say "use unsafe and move on": we need to push back against that

#### Bugs Found

- **Missing Reference Count:** caught by both Safer C++ and Swift-C++
- **Missing/Incorrect Bounds Check:** caught by both Safer C++ and Swift-C++
- Swift-C++ can cover undefined behavior, but we didn't find any of those bugs in WebGPU
- **Dangling View/Reference (borrow checking error):**
  - Safer C++ can't catch this...
  - Swift-C++ can catch this! However, it doesn't tell us what we're supposed to do
  - Working on a way to model lifetimes for this

#### Swift-C++ in WebKit is Feasible!

- We've gotten moderate incremental safety gains so far: you get told "something bad is happening"
- Goal: algorithmic enforcement without exception

What's next?

- Zero unsafe in WebGPU: working on it
- Shared toolchain: make Swift-C++ available for anyone working cross-platform
  - swiftc, clang, libc++
  - Enables Swift-C++ in cross-platform code, enables modern C++, and enables more shared code

Proposal for a change:

- Memory safety cannot be an add-on or something we hide away: the only way we know to get memory safety is at the language level, which requires a toolchain
- Looking for thoughts! Are you willing on trying out the shared toolchain?

##### Questions

- **Q:** Rewrites of existing code in Swift: have we made determinations of specific areas where we'd want to rewrite in Swift? Ladybird is planning on implementing things in Swift moving forward, for example, parsing untrusted data.
- **A:** Rewrites are expensive and create bugs: why would we want to do this in general. However, we did rewrite GPU process strategically as a test. We'd like to follow this method for rewrites to see how they compare. The value of algorithmic safety is the choices we make about vulnerable code: we can choose to rewrite code strategically on important parts. For new things, we should just choose memory safe languages; maybe not best to try to rewrite all of WebCore though. We get to decide what we want to rewrite depending on priority.
- **Q:** Why isn't undefined behavior going away, especially with our control over clang?
- **A:** The reality of UB is that the compiler is running a series of optimizations which could delete information that should have been passed into your bounds checks. Trying to "define" UB becomes way too complicated, and creates way too many behaviors to reasonably define.
- **Q:** Evaluation of FilC for WebKit?
- **A:** Two ways to get memory safety: take unsafe code and run it in a VM (FilC, Java, etc); or make the source code right to begin with. Main merit is performance. Systems programming: we want our code to have control, rather than having the VM get full control; we can also interact with systems outside of the VM.
- **Q:** Performance estimates for Swift-C++ prototype?
- **A:** No performance difference: on purpose! IPC is usually the bottleneck; if we do a few extra checks, it's generally negligible. Performance will almost never be a concern in the main areas we're interested in.
- **Q:** We're signing up for a permanent phase where you'd need to know both Swift and C++ to contribute to WebKit. What influence does WebKit have over the direction of Swift?
- **A:** WebKit integration has been the biggest project for C++ interoperability. If we go this way, it's going to be permanently dual-language; the future seems to be that memory safe languages won't really replace existing C/C++, but will be added in incrementally where necessary. We have pretty good influence! Swift / WebKit are both important to Apple; it's important to Swift that this project matters. Windows support: Apple has been staffing up Windows-specific engineers for runtime work and debugging work. Working on VSCode support across every platform; hit feature parity with other platforms that we support. It's still a bit behind other ports such as Linux, but catching up.
- **Q:** Swift supports libstdc++ as well; why require libc++?
- **A:** "Because I didn't know that"; may consider.
- **Q:** For some systems, there's interoperability concerns with things using other STLs; we need to consider this for shared toolchain. Will the shared toolchain become "the toolchain" or a preferred toolchain?
- **A:** Proposal is that the toolchain would become the universal build toolchain for WebKit; it's possible that other combinations could work but unaware of other projects making it work.

---

### Advancing Cloud Gaming: The GeForce NOW 2025 and 2026 Roadmap

**Speaker:** Sun Shin (Nvidia)

##### Notes

#### Background

- WebKit Contributor since 2012 representing LG Electronics
- Became a committer in 2015
- Major contributions to WTF and accelerated compositing based on GPU
- LG webOS TV platform moved to Chromium in 2015
- Joined NVIDIA Cloud gaming team in 2022
- Got back to WebKit for the cloud gaming experiences improvement on the Web and recovered committership

#### Recap 2023 Presentation

- Talked about what is cloud gaming and its requirements
- Asked for collaboration on the following areas:
  - WebRTC-HEVC
  - Keyboard and pointer lock API support
- Gamepad API support still needs improvements

#### GeForce NOW 2025 Update

- GeForce NOW's Blackwell RTX 5080 launch
- RTX 5080 GPUs are offering up to 2.8x the performance of the previous RTX 4080 servers
- They support DLSS 4, full ray tracing and ray reconstruction bringing cutting edge graphics to cloud gaming

New Streaming modes:

- Cinematic quality streaming for visually rich single player experiences (YUV 444)
- Competitive modes:
  - 1080p at 360FPS for ultra smooth gameplay in titles like Overwatch
  - 1440p at 240FPS with NVIDIA Reflex for low latency performance
- 2200+ install to play titles

#### Supported Platforms

- **Desktop:** macOS / ChromeOS / Windows
- **Browser:** Safari / Chrome / Edge / Opera
- **Mobile:** iOS and iPadOS / Android / Gaming
- **Handheld devices:** SteamDeck / Razer Edge
- **TV:** Smart TV / Android TV
- **VR Headsets:** Apple Vision Pro / Meta Quest

#### Collaborations in 2025

- Web applications: enable fractional coordinates for pointer events and touch events
- Full screen based keyboard lock API
- Gamepad interop
- WebRTC: L4S (low latency low loss scalable throughput)
- Device capabilities: HDR/HFR / 8K support
- 5G network slicing

#### Device Capabilities: HDR/HFR / 8K

- HDR support is identified by dynamic-range and color gamut
- CSS media queries, specifying Dynamic Range: High and Color Gamut: P3
- Additionally, HFR and 8K Resolution support are identified by the Media Capability API

#### KeyboardLock API Support

- Interface and testable feature flag definition
- Landed initial implementation based on Full Screen API on WebKit
- Also currently following up the iOS keyboard attach and detach event supports
- Follow up: update GFN implementation based the full screen based keyboard lock
- Unify implementation of keyboard lock API across browsers

#### Gamepad API Testing

- Due to the lack of unified evaluations on cloud gaming APIs on web platform tests, the gaming related APIs are vulnerable to be broken on each browser's major releases
- No actual input tests are allowed because of permission issues
- In the web application working group meeting at TPAC 2024, we discussed about proposing interim proposal
- Collaborators: WebKit/Chrome/NVIDIA GFN team
- This investigation effort ended to the Gamepad API and is focused on improving test coverage rather than fixing existing tests
- Add a means to test the API
- Reviewed the current status of Gamepad test
- Evaluation of the gamepad testing frameworks across user agents
- Refined the manual test API to better reflect real-world usage scenarios and identified key gaps and inconsistencies in browser behaviour
- Defined interfaces for automation, laying the groundwork for future automated testing

Proposal for the 2026 investigation effort:

- NVIDIA team is working on estimating the work efforts for the WebKit side implementation
- WebKit does not fully support WebDriver BiDi but there has been a great progress since last November 2024

#### 2026 Roadmap

Still pending features:

- Full screen API support — should give huge flexibility from the PWA
- Keyboard and pointer lock API support — required to support keyboard and mouse gaming with full screen API
- Gamepad trackpad support — Sony DS4/DS5 trackpad support (NVIDIA GFN team volunteered to support this)

Releasing the experimental features:

- L4S, 5G network slicing
- Full screen based keyboard lock API

Gamepad interop 2026:

- Add the automation interface by the API design on 2025 interim
- Phase 1: WPE or GTK ports
- Phase 2: Mac Port (??)

---

### JSC Regular Expression Engine

**Speaker:** Michael Saboff (Independent)

##### Notes

Michael - former member of JSC. Talking about Yarr (Yet Another Regular Expression Runtime): the RegExp engine in WebKit. Background about JS RegExp syntax and capabilities, how we process RegExp in Yarr, some optimizations we have in Yarr, and some future plans.

#### RegExp Terminology

- **Atom:** building block for matching
- **CharacterClass:** group of characters (range or list)
- **Disjunction:** set of atoms; grouped disjunction can be an atom itself
- **Quantified atoms:** match multiple times before matching the rest of the regular expression

CharacterClass have:

- Built in: whitespace, word characters, etc.
- Constructed: `[a-zA-Z]`
- `[^a-zA-Z]`: what's not in those ranges

Assertions: "anchors" that do some matching but don't include their match into the resulted output

- BOS/EOS: (`^` for beginning, `$` for end)

- **Term:** Atom or Assertion, lowest level of something we'll match
- **Alternative:** list of one or more terms to match
- **Disjunction:** one or more Alternatives, tried in order given
- Alternations and disjunctions can all be nested

#### Quantifiers

Atoms by default match once, unless they're quantified:

- `a{3}` matches 3 times
- `a{3,}` matches at least 3 times
- `a{3,7}` matches anywhere from 3 to 7 times
- `a*` matches 0 or more times (`{0,}`)
- `a+` matches 1 or more times (`{1,}`)
- `a?` matches 0 or 1 times

These all match greedily: match as many times as they can, until they can't match or run off the string, and then move on.

Adding an extra `?` at the end makes it "non-greedy", it will start by trying to match the minimum and then match more times if needed.

#### Flags

Flags are added after the regular expression: for example, `/abc/i`

- `i`: ignore case; simple for 8-bit characters, very involved for 16-bit characters, even more involved for Unicode
- `s` (DotAll), `m` (Multiline): change meaning of how whitespace behave
  - `.` by default doesn't match newline/CR and some weird Unicode characters unless DotAll is set
  - `m` allows `^`/`$` to match newlines
- `g` (Global), `s` (Sticky): change where the match starts
  - `g` tells the regular expression to start matching right after the prior match finished
  - `s` tells the regular expression the next match must start exactly where the prior match finished
- `u` (Unicode) / `v` (UnicodeSet): more in a bit

These flags can affect each other: for example, Unicode flags will change behavior of `i` to include Unicode case folding, etc.

#### Unicode Mode

Unicode mode (`u`):

- Allow matching 16-bit characters and surrogate pairs (65536 – big number)
- Matches against surrogate pairs will give 2 characters
- Support for Unicode properties:
  - `\p{General_Category=Lowercase}`: any lowercase character
  - `\p{Script=Greek}`: Greek characters

UnicodeSet mode (`v`):

- Also matches Unicode characters, but syntax not compatible with `u` mode
- Kind of like a "strict mode" for `u` mode: syntax is a bit stricter
- Adds set operations for CharacterClasses:
  - `[[ABC][123]]` is union (equivalent to `[ABC123]`)
  - `[\p{Greek}&&\p{Lowercase}]` is intersection (only lowercase Greek characters)
  - `[[a-z]--[aeiou]]` is set subtraction (only consonants)
- Strings in class sets:
  - `[\p{RGI_Emoji_Tag_Sequence}--\q{:ru:}]` matches everything but the Russian flag

#### Pattern Matching Examples

- `/abc/`: match the string "abc"
- `/\d{3,5}/`: match three to five digits
- `/Yes|No/`: match "Yes" or "No"
- Can group constructs using parentheses: capture groups allow us to grab the result of a specific group
- Assertions anchor the match to various positions in the string

#### Regular Expressions are Not Regular

- Regular languages consist of concatenation, repetition, and alternation; we cannot save any state when matching a regular language
- Regular expressions now are pattern matchers! Many cases where we need to save state to process modern regular expressions
- Lookaround assertions allow for matching something without recording the lookaround: need to store where we started the lookbehind/lookahead
- Backreference: match a prior captured subpattern: need to store our prior captures
- Variable counted parentheses: need to keep going back to restore state depending on complexity of parenthesized expression

#### Two Broad Classes of Matchers

**Backtracking Matcher:**

- Backtracking matchers try to match, and if they fail, they'll backtrack and try different ways to match the pattern.
- Very fast to compile: just need to turn the RegExp into some instructions for the matcher
- Execution speed can be exponential: backtracking can become exponential

**Finite Automata: DFA/NFA:**

- Follow a state machine based on the regular expression
- Very fast to execute, compilation takes a long time (especially for DFA)
- Not compatible with non-regular languages, so can't always be used
- https://swtch.com/~rsc/regexp/regexp1.html has some discussion on matching algorithms. This is in the context of matching across files, though, so compilation time didn't really matter as much as it does for Yarr

#### Yarr Internals

`YarrPattern.h`: structure names closely match the standard!

- YarrPattern breaks down into a PatternDisjunction, which has PatternAlternatives, which break down into PatternTerms, etc.

YARR parser utilizes the delegate pattern, with three backends:

- Syntax checker: "null delegate". Parser itself emits syntax errors
- YarrJIT and interpreter: creates data structures for YarrPattern
- URLParser for adblockers: generates DFA, and errors if you try to do non-regular things. DFA compilation for an adblock list takes a while, so that's why adblocker installation sometimes can be slow

YARR parser has some amount of lookahead (up to 5, but generally around 3 characters at most). Only a few errors that can't be handled by the parser (inverted strings and exceeding limits).

#### YARR JIT

YARR JIT converts YarrPatterns directly into JIT code. Emits code for:

- Body Alternative Begin/Next/End (top level alternatives)
- Nested Alternative Begin/Next/End: similar
- Subpatterns: variations based on fixed, counted, or end of pattern
- Assertions and PatternTerms
- DotStarEnclosure: special optimization

#### YARR Interpreter

YARR Interpreter: transforms YarrPatterns into `Yarr::ByteTerms`. Many types are directly mapped from Atom/CharacterClass, but with information about counting (`/a*/` becomes PatternCharacterGreedy).

`matchDisjunction` runs the interpreter, which processes ByteTerms in a loop; uses goto to jump between match and backtracking switches (`MATCH_NEXT()` and `BACKTRACK()` macros).

#### JIT Code Details

JIT code takes 4 arguments:

- Subject string address (x0)
- Start index of subject string (x1)
- Length of subject string (x2)
- Pointer to integer array where we put results of the match: beginning/end of match, and beginning/end of capture subgroups (x3)

When we compile `\w+`, we turn it into `\w` followed by `\w*`; we do this for all our non-zero based variable counted constructs (for example, `{3,5}` becomes `{3}` followed by `{0,2}`).

Backtracking is reversed: we'll keep falling through out of terms until we need to jump back into matching / drop into the exit, write -1 for no match, and return.

#### Optimizations

- **DotStarEnclosure:** people looking for `abc`, write `/.*abc.*/`, which is quite bad (first `.*` goes all the way to the end, then starts backtracking). We'll recognize this pattern, as well as `/^.*abc.*$/`.
- **Sort PatternTerms** so we handle characters before matching character classes: character classes are more involved to match, so we can reject faster
- **String matching:** matching "abc" means we read two characters, and then one more character. If we're matching 8-bit characters, we can match 8 characters at a time with a 64-bit load. If you're matching 4 characters, we used to do a 4, 2, 1B load. Now, we optimized this to match 4 bytes, then an overlapping 4 byte load, giving us two loads.
- **JIT separately for 8-bit and 16-bit**
- **Custom JIT code** just for test where we don't save any results, just need to know if it matches
- Total 4 variations for JIT code: 8/16 bit and regular/test
- **Inline** `RegExp.test` code into DFG/FTL
- **JIT processing of some variable counted parenthesis:** bump allocator allows us to save/restore state
- **Boyer-Moore optimization** for finding the first part of the string: good at failing fast
- **Character Class Processing:** range checks, binary search, bit maps allow us to match character classes
- **JIT handling of 16-bit case folding** in backreferences: calls out to a helper which does case folding
- **JIT avoids branch-over-branch** more, invert the condition to make it one branch

#### Debugging Yarr

`--dumpCompiledRegExpPatterns=1`, `--dumpRegExpDisassembly=1`, `--verboseRegExpCompilation=1`, `--useRegExpJIT=0`

`YarrInterpreter.cpp`: set the verbose flag to trace interpreter execution

#### Michael's Priorities for Yarr

- JIT support for lookbehinds: engine needs to go backwards, so we need to check if we have enough characters
- JIT for nested variable counted parentheses: we need new constructs for this
- NFA engine for eligible hot expressions: we already have a backend which determines if the expression is actually regular. We don't want to do this for regular expression that run once, though.
- Various misc. optimizations

##### Questions

- **Q:** How much performance gain would we get from NFA?
- **A:** There's a class of RegExp where this would be significant. NFA looks at each character just once. Some patterns that are a bit more complicated (alternations) would likely give a good win.
- **Q:** Have we looked into exploits on the JIT engine?
- **A:** We've looked into it a bit; we pass in an array of 32-bit integers and we trust that this is set up correctly. Probably the main memory safety exploit, could be improved a bit.
- **Q:** What are the tier-up thresholds from interpreter to JIT?
- **A:** If a RegExp cannot be JIT'ed, then we go to interpreter; we tier down. If our bump allocator runs out of space, we'll fail in JIT but ask the interpreter to try. It doesn't seem worth starting in interpreter because the interpreter's performance is quite bad compared to JIT.

---

### Improving the WPE Port on Android

**Speaker:** Adrian Perez de Castro (Igalia)

##### Notes

- Adrian introduced himself, his interests in retro computers
- This talk will cover the status of the WPE Android project
- WPE Android is NOT a port — it uses WPE WebKit. This doesn't mandate any toolkit or windowing system
- We can see a "minibrowser" running on Android and showing web pages
- Android supported by HW manufacturers, so WPE Android can target them
- APIs are stable, which allows us to provide binaries
- Bringing WebKit back to Android is fun!
- WebKit is easier to customize and helps avoiding reliance on Chromium / Google
- History of the project, going from 2017 all the way to now, 2025
- Highlights: Skia for Android, no downstream patches (we can run from main) and now AHardwareBuffer, WebXR
- Git activity building up
- Preparation for platform guards, logging improvements to help with debugging
- Integrating the WebKit logging with Android properties
- Shared memory on Android using ASharedMemory API
- Graphics Buffers support using AHardwareBuffer API — the trickiest part was to get it to work well through IPC
- Cleanups, improving naming based on earlier assumptions, plus refactorings
- WebXR! (stay tuned for another dedicated talk)

---

### How to Not Make Bugs (in JSC), and the Future of 32-bits

**Speaker:** Justin Michaud (Igalia)

##### Notes

Justin introduces himself, started working on WebKit in 2020 while at Apple, now working at Igalia mostly focused on the 32-bit port of JSC. Would love to also make the 64-bit port better.

#### Challenges of the 32-bit Port

- Lack of registers and the fact that a JSValue is not able to fit in a 32-bit register
- Also issues with reusing registers in multiple places
- Also we have a small VA space, but we can enable some optimizations

#### What is a JSValue?

- It's the base for everything you represent in JS. Could be a double, an int32... although from the perspective of the program it's still a double
- There are differences between V8 and JSC JSValues
- It's convenient that we can have a pointer in C++ to JS values in our JSC
- Explains the differences between the internal representation of a double and a 32-bit int
- One of the problems with 32-bit integers is that we can't do concurrent GC as it is now, using 64-bit for their representation
- It boxes a double/int, and allows to check if it's a JSCell* or a Small Integer (SMI)

#### Why Doing This?

- We want to avoid different code paths vs 64-bit and we want to have concurrent GC
- This should reduce maintenance burden and really hope we can have something useful we can play around with, even if we can't have a 64-bit mini mode
- Hoping that this will make 64-bit better and help there too
- For i64s not sure we want to box them, for WASM we probably stick to static register pairs
- We haven't measured yet, we want to further investigate and keep reducing the difference between 32 and 64 bits

#### GC Bugs

- We might not want to do generational GC because of White barriers, which are a new way of telling the collector the information they need
- In JSC the way our collector works limits what we can do. If you have a particularly evil JS code it can create more work for the collector than what it can complete
- Conservative stack scanning: on 32-bit we have encountered some problems and we expect to encounter more in production
- It seems V8 is switching away from this in some cases, would be nice to have a discussion on why this is
- Example of a GC bug that causes a use-after-free situation
- Justin is curious about what will happen if the compilers become more aggressive optimizing stuff

#### Generational Barriers

- The hypothesis is that in general objects are short-lived and if they survive they usually do for a long while
- We want to scan only the young objects then, instead of doing a full GC
- A generational barrier means we don't see older objects

#### Concurrent Barriers

- We need these for other cases around marking and sweeping objects with assignments in between
- Safe point: places where it's safe to run sweeps
- You need to be careful when you do sweep points, make sure it's a safe point

#### 32-bit Barriers

- We don't want to replace a burden with another burden of maintaining 32-bit barriers

#### Speculation

- What is an Int8Array? They are arrays that are not internally boxed, no need to run conversions
- They seem to be faster
- Poll in the room: if we mix typed and regular arrays... is it going to be faster or slower than using just regular arrays? 12 people think we'll be slower, no one thinks it will be faster
- Using a regular array and a typed array you get a 22.8x slowdown. This was surprising
- It seems JSC assumes your program will eventually be type-stable
- V8 is generally slower for the mixed cases and then faster for the regular cases

#### Language Performance Comparison

- Comparing against other languages: JS, C++, Rust, Java, Swift, PyPy, Python
- C++ is way faster, also Rust and Java
- Swift is 3.8x slower than JS, this is surprising, maybe I did something wrong
- PyPy 5x slower and Python 71x slower...
- JS is actually really fast — actually close to Java performance, and far away from Python
- If we are adopting a memory safe language.... why not JS? (only said half-seriously)

##### Questions

- **Q:** Reason for the performance difference?
- **A:** I think it's an interesting discussion, in some cases JSC is faster than V8.
- **Yusuke:** Comments about the encoding used, needs to be as simple as possible. We can have a discussion about the possible proposal.
- **Justin:** Appreciates Yusuke's feedback, looking forward to have further discussion. Thinks that adopting Swift will mean having more control over features, having support for a side table in Swift for JSValues could be useful.
- **Mark Lam:** Word of advice on picking the encoding to minimize the amount of checks needed.
- **Justin:** Agrees.

---

### Enabling Swift in Your Port

**Speaker:** Adrian Taylor (Apple)

##### Notes

- Will cover Swift C++ Interop
- Want to add memory safety in the privileged processes
- WebContent is assumed compromised

Swift-C++ interop:

- C++ calls to Swift
- Swift calls into C++

- Prototyping this with the BackForwardList

Where does the Swift code live in WebKit?

- We are talking about Swift within WebKit
- Parts of the WebKit implementation which are done in Swift
- BackForwardList: https://github.com/WebKit/WebKit/pull/48676

- Clang Module: Way of storing set of headers on disk as an abstract syntax tree
- C++ code needs a header file to understand Swift types — this is called `WebKit-Swift.h`

How do we enable Swift in a WebKit port:

- Ensure you have a Swift toolchain
- Configure Swift to see the C++ headers
- Add a build step to emit a generated C++ header representing usable Swift types and functions

`Tools/Scripts/build-webkit --gtk --debug --swift-demo-uri-scheme`

- This is a simple demo feature. This is a starting point to resolve problems. Please try and build this and start a conversation on Slack
- How do we make a message handler in Swift? We are trying this to understand what is difficult to progress.
- Example of things to investigate: how to bridge between Swift and C++ reference counting..

Please come and find Adrian for a chat about C++ Swift interop.

---

### WebXR in Android & Linux with OpenXR

**Speaker:** Sergio Villar Senín (Igalia)

##### Notes

- Sergio works for Igalia, he started in 2010 working from Igalia on the GTK port, he implemented grid layout and flexbox

#### What is WebXR?

- WebXR definition: XR content in the Web, core spec + modules for other things
- Adopted by major engines, WebKit and Blink the most complex implementation
- For rendering it uses WebGL or WebGL2 or WebGPU lately

#### OpenXR

- OpenXR is an API from Khronos
- It is device, platform and system agnostic
- It is implemented by OpenXR runtimes using proprietary SDKs
- It solves the fragmentation in the XR world
- Adopted by most hardware vendors

#### History

- Igalia started implementation in 2020, added WebXR Core and tests
- Igalia paused the investment because at that point the main devices used were Android
- Apple took over and redesigned it because initially everything was in the WebProcess, using multiprocess architecture
- Igalia resumed the work this year to try to bring it back to GTK and WPE

#### WebXR Rendering Pipeline

- UIProcess gets access to the XR devices, creates the images and shares them with the WebProcess
- WebProcess uses WebGL to render content and signals the UIProcess that the content is ready to show it in the devices using fences
- Using OpenXR it is pretty similar — it provides a swap chain that generates images as OpenGL textures that shares with the WebProcess
- It uses the OpenGL fences to signal
- It uses for the moment 1 layer but it is prepared to use multiple layers

#### Rendering Pipeline Design

- The code is mostly shared with Cocoa and WPE
- The opaque framebuffer just landed because the code is mostly similar
- The design is flexible because it uses different framebuffers for drawing and displaying
- The content is rendered in the drawing framebuffers and after that blitting
- You need this copy to use MSAA and it is required for framebuffer scaling feature, that allows to request a smaller buffer than the hardware to allow more FPS with smaller resolutions
- The design allows 2 different layouts: shared (1 texture shared by the 2 eyes, currently used in Linux) and layered (one texture per eye)
- Images are exported just once and cached, the engine just changes between both
- Shared layout requires less blits and it is simpler but it is not supported by visionOS

#### Android Case

- Instead of using DMABuf buffers support we had to add support for Android Hardware Buffer
- The problem is that AHardwareBuffer can not use the buffers from OpenXR
- The solution is to use AHB for sharing the buffers, but it requires a blit to copy the contents to the final OpenXR texture
- Performance is ok even with this blit

#### Supported Specs

- WebXR Device API, Test API, AR Module and Hand Input Module
- Demo of WebXR in desktop using an OpenXR implementation using Monado — can be used in desktop and devices

#### Further Improvements

- Plan to use Vulkan as a transport mechanism — that way the graphics resources would be simpler to allow sharing code between Linux and Android
- Fast path for content that does not use MSAA or framebuffer scaling; in those cases you can render on the textures, it can complicate the current code but it can be checked
- Adding instrumentation to check performance

#### Future Plans

- Work implementing more modules: WebXR Layers, Hit Testing and Anchors
- Initially trying to avoid the use of WebGPU for layers because the current implementation uses Swift
- Interest in implementing the Anchors module

##### Questions

- **Q:** Accessibility experience with WebXR — WebXR maps to assistive technologies and it is exposed
- **Sergio:** Not an expert, WG meet from time to time to try to check how a11y and WebXR can work
- **Tyler Wilcock:** Took a stab at making WebXR content accessible. It sort of worked, but there's a lot more to do (both in WebKit and in assistive technologies) before it would be shippable. The patch adds new web-exposed APIs (e.g. XRSceneGraph), with the intention being that popular libraries like three.js would adopt them. Got VoiceOver to read object names in a WebXR scene. But would need to do the hard work of proposing these APIs as web standards. The WebKit patch itself needs a fair amount of work, and probably Apple assistive technologies like VoiceOver would need some changes too.
- **Sergio:** If you have a proof of concept it'd be easier to present your ideas to the W3C
- **Tyler Wilcock:** The experience was a bit flakey for non-WebKit reasons, so hoping to get back to it eventually
- **Sergio:** We have a very good a11y team in house at Igalia, can tell them about the efforts, maybe they could have some slack to help/research

---

### WebDriver BiDi

**Speaker:** Blaze Jayne Burg (Apple)

##### Notes

The talk will be including other topics like Site Isolation, and UI Testing/Web Inspector.

#### Web Inspector History

- In the beginning, we had a single target: Page
- The inspector was introduced 19 years ago, and you could inspect locally, attached, or remotely
- Beyond Page, other target types were added over time, like JSContext (JSC), offering Debuggers, Runtime, Console domains
- Other target type supported was ITML/TVML
- With Workers, now we had more than one addressable item per process
- At this point, they were supported as the Worker Domain in the Page Target
- Eventually, the Inspector supported proper Worker targets

#### PSON: Process Swap On Navigation

- This required the Inspector to be aware of the WebProcess changing
- With `<iframe>`, a Page target can connect to multiple WebProcesses, breaking many assumptions from the original Inspector
- To address, we added "Frame Target Type" — it belongs to the WebPage target, representing a LocalFrame
- In the backend, we changed code that targeted the whole Page to target Frames, with the Frontend combining the results from different Frame targets
- Multiple different configurations in Frontend, depending on whether we're targeting a Frame Tree or a WebPage

#### Working in Site Isolation

- FrameInspectorController / FrameInstrumentingAgents / Forwarding commands for protocol tests
- WIP: FrameConsoleAgent / FrameTarget support in WebKitLegacy / Page and Network domain for Frame Target
- Eventually, adding support for other domains like CSS, Timelines, etc.

Summary:

- Web Inspector is 19 years old and Not Safe
- Web Inspector UI test coverage is absent
- Web Inspector test coverage for `<iframe>` is scarce
- Supporting WebKitLegacy continues to be a burden
- Having a suite of test content is super important

#### What is WebDriver BiDi?

- WebDriver: An API for automation of browsers
- Behind the scenes, the code is issuing REST commands and waiting for results
- WebDriver-BiDi is based on WebSocket, which is already supported by the browser, in comparison to REST
- Before WebDriver-BiDi, you had to keep asking the browser for the results
- There are events also to be notified of creation of new elements, like new iframes
- Alongside other stuff like network interception and bootstrap scripts
- Currently, we have a dual implementation, with Classic and BiDi similar commands

#### WebDriver-BiDi in WebKit

- Lauro (Igalia) started it last year, the Automation protocol wraps the BiDi protocol, which is based on JSON-RPC

Recent progress:

- Session domain
- Log domain
- Browsing Context domain
- Storage domain
- Permissions domain

When can I use it?

- We can't ship it yet, and enable it by default, as there are some CI issues preventing proper testing

#### UI Testing for WebInspectorUI

Current coverage:

- Protocol Tests
- Model tests
- Tools tests
- API tests
- CodeMirror, External Libraries tests
- Remote inspection tests
- But no UI tests

- The most important requirement for the UI tests would be not pulling complicated 3rd party test dependencies — ideally, using WebKit to test WebKit

WebDriver for WebInspector UI Testing:

- Add support for MiniBrowser to run with WebDriver-BiDi enabled
- Separate runner, to control the browser that will be tested
- Add the Inspector Domain to BiDi
- Using WebDriver is a natural choice for this kind of tests, as it simulates a user controlling the browser

Open questions:

- What commands should go in the Inspector domain?
- How does the example map to WebDriver commands?
- How does one debug a WebInspector UI Test?
- How to support uses of inspector automation outside testing? (i.e. Agents)

##### Questions

- **Shin:** We have been thinking of using BiDi. Is there any timeline for release for Mac?
- **Blaze:** Unfortunately, no, as there are some blockers. It works for WebKitGTK, but not yet with SafariDriver.
- **Q:** Are there any difficulties to use with MiniBrowser instead of Safari?
- **A:** The main problem is that safaridriver uses its own server/network library to talk to Safari.
- **Q:** In the case of WebDriver BiDi, does the server live in a separate process or in the browser?
- **A:** Right now, the server lives in safaridriver.

---

### Performance Profiling with samply + JavaScriptCore

**Speaker:** Yusuke Suzuki (Apple)

##### Notes

Demonstrating profiling mechanisms with Samply.

JetStream2 scores are continuously improving; we're working on switching focus to JetStream3.

"Performance is a top priority for WebKit. We adhere to a simple directive for all work we do on WebKit: The way to make a program faster is to never let it get slower."

Performance offense: how do we get faster? Two main wheels: analysis and implementation. Both are necessary and need to be done in parallel: as we implement new features, we need to analyze the new bottlenecks. Most talks focus on implementation: how we designed optimizations and how we found improvements. This talk focuses more on the analysis side, including tooling.

#### Profiling with samply

- samply is an existing open source out-of-process sampling profiler, which came from Gecko-profiler (Mozilla)
- Sampling profilers suspend and take a sample of a target application at periodic intervals. Each point gives us a stack trace, and we can start to understand where the program is spending its time. We can construct a call graph without having to incur severe performance costs. This is similar to Apple's Instruments tool.
- One big problem is that we can't look into JIT code: it's just opaque hex addresses. We don't know what those addresses are. However, we have a tool called JITDump, which allows us to look into what specific code the JIT code corresponds to.

#### JITDump

- JITDump is a semi-standardized JIT debugging information format, which was introduced originally for Linux perf. It's become relatively standard, and nearly all production JIT compilers support it (JSC, V8, SpiderMonkey, Hotspot JVM, etc.)
- JITDump records the PC range -> function name as a mapping, and passes this to the profiler to resolve JIT symbols later during analysis.
- samply spawns JSC and injects its own dynamically linked library. JSC opens a JITDump file, which then is passed onto samply. samply will collect all this information.

#### Demo

- Demo showing the results of samply's analysis; we can scroll across the timeline and showing various parts of JSC, such as OMG JIT code and YarrJIT code, appearing as a result of JITDump results.
- We can emit signposts, which appear as markers; this allows us to look at individual tests. We can look at the profiles throughout that test's duration, and see what samples show up.
- We can see that during Kotlin-compose-wasm, we have a lot of time spent in the OMG compiler. Earlier in the execution, we see a lot of time spent in the interpreter, and then BBQ (baseline Wasm). Eventually, we end up all in the highest tier of execution (OMG).
- Samply allows us to look at the source code as well as the assembly, and we can see what code is taking more time from the samples.
- If we look at the OMG code, we're able to also look at the disassembled JIT code, and see where samples were taken. We then can see if the JIT code is compiled correctly or if there are any weird patterns in where we're hitting slow paths, etc.
- We can also look at these results as a flamegraph, which also includes JIT code, and shows what functions are creating a lot of stack frames.
- Additionally, we have the stack chart view, which shows the call stack samples (y axis) across time (x axis). The stack chart allows us to see the execution sequence and specific function call patterns. We see a repetitive pattern here because of JetStream3 running multiple iterations of the benchmark. The first few iterations we see more baseline compilation, while later on, we see higher tiers taking up more and more of our time.

#### Using samply with V8

- We can also use samply with V8! We can use this to analyze V8's performance.
- Firefox profiler doesn't quite work on Safari due to local file access.
- We can look at V8's profile, also annotated with JITDump function names. Similarly, we can also look at the disassembly of JIT code.
- We can't directly compare the results, because of samply's overhead, but we can see what other engines are doing.
- We can also use this to develop new benchmarks, to check that we're measuring what we intend to measure across all engines.

#### Apple's Contributions to samply

- Implemented support for ARM64E, allowing us to use samply on Safari/JSC on ARM64E systems.
- Improved display of JSC's JIT code.
- samply is great! Give it a try and check out what bottlenecks your application has.

##### Questions

- **Q:** Apple folks: legal approval for contributing to samply?
- **A:** Yes, need to go to open-source contribution page.
- **Q:** Selecting multiple marker intervals?
- **A:** Samply doesn't support this right now, although maybe possible by customizing Firefox profiler code.
- **Q:** Are there plans for JSC to add categories to samply for JS JIT code?
- **A:** Already have this; showed Wasm OMG/BBQ, but we've categorized JS, IC, Wasm, etc. all in there.
- **Q:** How fast is samply compared to Instruments, sysprof, etc.?
- **A:** Seems to depend on target application, although not 100% sure. It seems that samply has relatively larger overhead compared to Instruments, ~10% ish. samply is crafting all the profiling mechanisms in userspace, so we're suspending and collecting each thread of the target application and all child processes. For example, in JS3, we're looking at all the threads for GPU, Networking, WebContent processes; if we have a lot of threads, then samply probably takes longer. samply has new implementations which can parallelize sample collection, so maybe we'll see reduced overhead in the near future.
- **Q:** How do we profile JS interacting with WKWebViews on iOS?
- **A:** If your focus is JS, look into WebInspector's sampling profiler; JSC has an in-process sampling profiler which can do similar things. samply targets the optimization of C++/JIT code, while JSC's sampling profiler targets optimization of the JS code itself.

---

### Wrapping Up Unowned UTF8 C Strings: CStringView

**Speaker:** Xabier Rodríguez-Calvar (Igalia)

##### Notes

Xabier introduced a talk about handling unowned UTF-8 C strings, thanking the audience for the opportunity to discuss the topic.

He explained that some C and GStreamer APIs return `const char*` pointers that remain valid only while their associated objects are alive. When using these strings in higher-level computations, copying them is inefficient, but directly wrapping them poses challenges.

The team initially used StringView for these C strings. However, when StringView was reworked to internally use spans, AddressSanitizer (ASan) started reporting memory issues because the null terminators were lost. This revealed the need for a safer and more efficient wrapper for unowned C strings.

As part of the possible solutions, continuing to use StringView is unreliable, as `rawCharacter()` could lead to memory safety issues. We should remove it. Calling `utf8()` to obtain a C string made unnecessary copies, reducing efficiency. Using spans also created semantic issues since the span's length did not account for the null terminator.

To solve these issues, we decided to write a new class. It went through several naming iterations, including UnownedString and CStringView. Different implementations were tested, such as aliasing ASCIILiteral, but this led to lifetime and encoding problems.

Further encoding issues arose because using `char` could conflict with other encodings. During the reviews, there were debates about whether the new class should be feature-rich or minimal with external helper functions.

Although the class has not yet been finalized, the current version, CStringView, uses `char8_t` to enforce UTF-8 correctness at compile time. It offers basic constructors, proper handling of null terminators and length, access to spans, and helper methods for emptiness and null checks. In addition to CStringView, related helper utilities in StringCommon and StdLibExtras were added or improved to enable proper string computations efficiently.

Next steps include ensuring that CString itself becomes encoding aware and compliant at compile time. He attempted a patch but it was huge, so further thoughts about this are in order. If this happens we should also consider renaming CStringView.

---

### Largest Contentful Paint

**Speaker:** Simon Fraser (Apple)

##### Notes

#### Core Web Vitals

- Set of metrics that measure real-world UX for loading performance, interactivity, etc.
- Used for things like real user monitoring (comparable over time/region, not browsers) and Google page ranking (one of the inputs for ranking)

#### Largest Contentful Paint

- Implements painting of images/video/text on a per-element basis, tracking the largest by area (computes and remembers the largest rectangle created)

Implementation details:

- Painting hooks (`didPaintText`/`didPaintImage`)
- Image loading hook (`didPaintImage`)
- Logic in `LargestContentfulPaintData`
- Optimized for performance neutrality (data collection continues until the user interacts with the page, so this was a lot of work!)

Limitations:

- Tracks paints and not compositing (some visual changes not tracked, e.g., moving an image from out of frame to in frame)
- Ignores canvas

#### Interaction to Next Paint

- Measures the time between a user interaction and display (e.g., taps/clicks/typing, not scrolling)
- Based on event timing
- Not standardized (heuristics in a Google JS library)
- Event timing now implemented in WebKit!

Event Timing Implementation: implement `performance.eventCounts`, which uses maplike.

#### Cumulative Layout Shift

- Measures how much things move around during loading
- We haven't done this yet
- Based on proposed layout instability API

#### Demo

- Very basic support in Web Inspector
- Went to timelines tab + reloaded the page, showed on the layout & rendering timeline
- Hovered over largest contentful paint, element on page highlighted
- Both LCP and INP now enabled by default in WebKit!

---

### Strict Memory Safety in Swift

**Speaker:** Doug Gregor (Apple)

##### Notes

Doug is from the Swift language steering group. He notes we've been talking about Swift and memory safety already. He's trying to answer the question "how is Swift memory safe", and "why if it's memory safe do we have to say strict".

When we think about memory safety from a language design perspective there are 5 different axes: lifetime, bounds, type, initialization, thread. C/C++ don't provide any of them without extra static analysis.

#### Lifetime

- Automatic ref counting, copy-on-write, noncopyable types
- (anything referring to memory that isn't still there)
- For objects on the heap, mostly ARC. Easy to use. Programmers mostly don't think about it. Low overhead, small runtime, no pauses like a GC etc., very deterministic and optimisable.
- On top of that, copy-on-write is an optimisation to make things quicker.
- Performance profile very good for most code, but some code requires noncopyable types (move-only in C++ terminology). Deploying for best perf and code size.

#### Bounds

- Easy for a new programming language. Just make everything do bounds checks.

#### Type

- To prevent type confusion attacks etc. Very easy when building into the language. e.g. discriminated unions, checked casts.

#### Initialization

- Similarly easy in a new language. Compiler is mean to you if you forgot to initialize something.

#### Thread

- The big one. Sendable checking, actors. But really hard. If you don't build it into your language model, then a data race can compromise any of the other things here.
- Example: discriminated union, where one thread updates the discriminant and the other updates the payload, you suddenly have type confusion.
- Doug points out that Go has this problem.
- Swift introduced support for this data race safety hole in Swift 6.

#### Unsafe and Strict Safety

- Any safe language needs to have an opt-out. Swift has an opt-out which is unsafe pointer types. Made them as ugly as possible so people felt bad using them.
- For C interoperability, favours ergonomics over safety, which is not fine in safety critical code. So the strict memory safety mode requires such cases to be marked as unsafe so that reviewers/auditors can spot it.

Two resources for people to learn: swift.org, douggregor.net. The latter teaches you Swift if you already know C++ well.

---

### Site Isolation

**Speaker:** Alex Christensen (Apple)

##### Notes

#### What is Site Isolation?

- If you have an iframe from sites that are not the same as the main-frame, they are put into another process
- If you call `window.open`, that goes in another process as well

Why?

- If you call `window.open` to sites like gmail.com, and do a speculative execution attack with JS, you can read someone's email — not good
- Accessing the cookies for another domain can also cause security issues without site isolation
- Other browsers have already implemented site isolation

#### Current Status

- This has been worked on for many years, and lots of progress has been made
- People are living on site isolation with great success (though buying pizza has been a known source of bugs)
- Many complicated websites do work with site isolation on
- Great effort has been made in the implementation to be made platform-agnostic

#### Drawing Implementation

- One exception to platform-agnostic is in the drawing implementation. Windows and Linux have very distinct drawing code relative to Apple platforms
- To implement drawing, one process says, I've drawn everything except the iframe, and the iframe process says I've drawn everything in the iframe, and they need to be slotted together

#### API Changes

- Alex has worked through some APIs that will not work with site isolation on, and has been replacing them
- One example: InjectedBundle APIs
- `InjectedBundlePage` `APIUIClient` has been chipped away at, and is now not used by Apple platforms via ifdefs, but other platforms still use it. It would be ideal to remove this outright
- `APIUIClient.toolbarsVisible` replaced with site-isolation friendly version with async IPC, needs to be hooked up on other platforms
- `_WKJSHandle` is a UI process object that represents something in the web content process. You can pass as a parameter. Useful for registering callbacks in extensions. Started as a node handle, and has been expanded to a more general object
- `_WKStringMatcher` matches strings against large sets of regexes, recent prototype
- Alex is iterating on replacements for InjectedBundle API replacements, would love input and collaboration

#### Performance

- Change made to mitigate performance regressions for SI — makes all third-party iframes share process, which helps a ton e.g. on news websites with lots of ads

---

### WebDriver BiDi Demos

**Speaker:** Lauro Moura (Igalia)

##### Notes

- Lauro shows a demo of WebDriver BiDi
- There is a ball bouncing on the screen
- To use WebDriver here, he inserts some code via a Python script to do some polling and check the results are the intended one
- Problem: sometimes you might get events at the same time
- Other problem: sometimes you get a lot of messages which can be a problem in embedded devices, especially with huge web applications
- To mitigate this problem, WebDriver allows you to subscribe to specific events
- With the subscription added, he re-runs the demo and only the relevant events are shown in the log
- This is the beginning of WebDriver BiDi in WebKit

---

### MathML Core in WebKit

**Speaker:** Frédéric Wang (Igalia)

##### Notes

- MathML Core is a subset of MathML 3, intended to be well integrated in the browser, it provides very precise data tools and it aims for better interoperability
- It is already implemented in the 3 major engines
- Covered by 3000 tests. A subset but it requires more things than MathML 3, for example animations. There is a comparison showing a variety of formulas in a static PNG from LaTeX and animated using MathML and CSS

#### Contributors

- Right now there is work on this area by Eri supported by the Sovereign Tech Agency. A few months ago we had a Coding Experience student, Harry. There is also work by Fred and Ahmad (Apple)

#### New CSS Features

- It is really important to select a proper math font family, specially for stretchy symbols. Moved from a hardcoded list to the standard way with `font-family: math` which can be configured by preferences
- `math-style` allows for rendering more compact formulas
- `math-shift` is more subtle and it tells how much superscripts should be raised, for example under radicals
- `math-depth`/`font-size: math` adjusts the size of nested formulas, reducing the size with nesting. There was a previous incomplete implementation which we rewrote using CSS properties. There are already some open patches for this
- `mathvariant` is to create automatic math italic for identifiers. There was already a legacy way but we rewrote it to be more CSS compatible

#### Interaction with Existing CSS Properties

- Border and padding still need some work
- There are properties that can cause issues, such as float and absolute position. WebKit has some workarounds but they aren't complete
- Want to disable `writing-mode` for now, since we didn't find a use case. There is a discussion about Japanese formulas but it wasn't very clear
- RTL (right to left) direction has a use case for Arabic math and there are some specific cases that we need to handle still, such as rtlm mirroring
- `length-percentage` has to do with SVG. In the past MathML and SVG had the same syntax for lengths. However, in MathML Core lengths are the same as length-percentage, and it is not fully implemented in WebKit yet

#### Additional Work

- We noticed that the new CSS properties were not animatable so we fixed that in the spec and we will be working on adding support for that
- We will probably work on more issues during this year



