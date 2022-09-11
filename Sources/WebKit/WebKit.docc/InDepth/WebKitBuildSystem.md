# Build System

An overview of how the WebKit build system is structured.

## Overview

Apple’s macOS, iOS, watchOS, and tvOS ports use Xcode and the rest use [CMake](https://en.wikipedia.org/wiki/CMake) to build WebKit.
There is an ongoing effort to make Apple's ports also use CMake.

In order to reduce the compilation time, which used to take 40+ minutes on the fully loaded 2018 15“ MacBook Pro,
we bundle up multiple C++ translation units (.cpp files) and compile them as a single translation unit.
We call this mechanism *Unified Sources* or *Unified Builds*.

Unified sources are generated under `WebKitBuild/X/DerivedSources` where X is the name of build configuration such as `Debug` and `Release-iphonesimulator`.
For example, `WebKitBuild/Debug/DerivedSources/WebCore/unified-sources/UnifiedSource116.cpp` may look like this:

```cpp
#include "dom/Document.cpp"
#include "dom/DocumentEventQueue.cpp"
#include "dom/DocumentFragment.cpp"
#include "dom/DocumentMarkerController.cpp"
#include "dom/DocumentParser.cpp"
#include "dom/DocumentSharedObjectPool.cpp"
#include "dom/DocumentStorageAccess.cpp"
#include "dom/DocumentType.cpp"
```

## How to add a new .h or .cpp file

To add a new header file or a translation unit (e.g. `.cpp`, `.m`, or `.mm`),
open WebKit.xcworkspace and add respective files in each directory.

Make sure to uncheck the target membership so that it’s not compiled as a part of the framework in xcodebuild.
Instead, add the same file in Sources.txt file that exists in each subdirectory of Source.
e.g. [Source/WebCore/Sources.txt](https://github.com/WebKit/WebKit/blob/main/Source/WebCore/Sources.txt) for WebCore.
This will ensure the newly added file is compiled as a part of *unified sources*.
![Screenshot of adding a file to Xcode](xcode-add-file.png)
When a header file in WTF is used in WebCore, or a header file in WebCore is used in WebKit or WebKitLegacy,
we need to export the file to those projects.
To do that, turn on the target membership in respective framework as set the membership to “Private” as seen below.
This will ensure the relevant header file is exported from WTF / WebCore to other downstream projects like WebKitLegacy.
![Screenshot of exporting a header file](xcode-export-header.png)

FIXME: Mention WTF_EXPORT_PRIVATE and WEBCORE_EXPORT.

FIXME: Add instructions on how to add files to CMake.

## Build Failures with Unified Sources

Because of Unified Sources, it’s possible that adding a new file will cause a new build failure on some platform.
This happens because if `UnifiedSource1.cpp` contains `a.cpp`, `b.cpp`, `c.cpp`, then `#include` in `a.cpp` could have pulled in some header files that `c.cpp` needed.
When you add `b2.cpp`, and `c.cpp` moves to `UnifiedSource2.cpp`, `c.cpp` no longer benefits from `a.cpp` “accidentally” satisfying `c.cpp`’s header dependency.
When this happens, you need to add a new `#include` to `c.cpp` as it was supposed to be done in the first place.

## Conditional Compilation

Every translation unit in WebKit starts by including “config.h”.
This file defines a set of [C++ preprocessor macros](https://en.cppreference.com/w/cpp/preprocessor)
used to enable or disable code based on the target operating system, platform, and whether a given feature is enabled or disabled.

For example, the following `#if` condition says that the code inside of it is only compiled if
[SERVICE_WORKER](https://developer.mozilla.org/en-US/docs/Web/API/Service_Worker_API) feature is enabled:

```cpp
#if ENABLE(SERVICE_WORKER)
...
#endif
```

Similarly, the following `#if` condition will enable the in-between code only on macOS:

```cpp
#if PLATFORM(MAC)
...
#endif
```

For code which should be enabled in iOS, watchOS, tvOS, and Mac Catalyst we use `PLATFORM(IOS_FAMILY)`.
For each specific variant of iOS family, we also have `PLATFORM(IOS)`, `PLATFORM(WATCHOS)`, `PLATFORM(APPLETV)`, and `PLATFORM(MACCATALYST)`.

The following `#if` condition will enable the in-between code only if CoreGraphics is used:

```cpp
#if USE(CG)
...
#endif
```

Finally, if a certain piece of code should only be enabled in an operating system newer than some version,
we use  `__IPHONE_OS_VERSION_MIN_REQUIRED` or `__MAC_OS_X_VERSION_MIN_REQUIRED`.
For example, the following #if enables the in-between code only on macOS 10.14 (macOS Mojave) or above:

```cpp
#if PLATFORM(MAC) && __MAC_OS_X_VERSION_MIN_REQUIRED >= 101400
...
#endif
```
