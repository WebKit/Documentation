# Unified Build System

An overview of how the WebKit build system is structured.

## Overview

In order to reduce the compilation time, which used to take 40+ minutes on a fully loaded 2018 15“ MacBook Pro,
we bundle up multiple C++ translation units (.cpp files) and compile them as a single translation unit.
This is a common technique known as *Unified Sources* or *Unified Builds*.

Unified Sources are generated under `WebKitBuild/X/DerivedSources` where X is the name of build configuration such as `Debug` and `Release-iphonesimulator`.
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

## Build Failures with Unified Sources

Because of Unified Sources, it is possible that adding a new file will cause a new build failure on some platforms.
This happens because if `UnifiedSource1.cpp` contains `a.cpp`, `b.cpp`, `c.cpp`, then `#include` in `a.cpp` could have pulled in some header files that `c.cpp` needed.
When you add `b2.cpp`, and `c.cpp` moves to `UnifiedSource2.cpp`, `c.cpp` no longer benefits from `a.cpp` “accidentally” satisfying `c.cpp`’s header dependency.
When this happens, you need to add a new `#include` to `c.cpp` as it was supposed to be done in the first place.
