# Conditional Compilation

## Overview

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
