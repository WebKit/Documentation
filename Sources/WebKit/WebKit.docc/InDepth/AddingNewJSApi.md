# Adding JS APIs

## Overview

To introduce a new JavaScript API in [WebCore](https://github.com/WebKit/WebKit/blob/main/Source/WebCore/), 
first identify the directory under which to implement this new API, and introduce corresponding Web IDL files (e.g., "dom/SomeAPI.idl").

New IDL files should be listed in [Source/WebCore/DerivedSources.make](https://github.com/WebKit/WebKit/blob/main/Source/WebCore/DerivedSources.make)
so that the aforementioned perl script can generate corresponding JS*.cpp and JS*.h files.
Add these newly generated JS*.cpp files to [Source/WebCore/Sources.txt](https://github.com/WebKit/WebKit/blob/main/Source/WebCore/Sources.txt)
in order for them to be compiled.

Also, add the new IDL file(s) to [Source/WebCore/CMakeLists.txt](https://github.com/WebKit/WebKit/blob/main/Source/WebCore/CMakeLists.txt).

Remember to add these files to [WebCore's Xcode project](https://github.com/WebKit/WebKit/tree/main/Source/WebCore/WebCore.xcodeproj) as well.

For example, [this commit](https://github.com/WebKit/WebKit/commit/cbda68a29beb3da90d19855882c5340ce06f1546)
introduced [`IdleDeadline.idl`](https://github.com/WebKit/WebKit/blob/main/Source/WebCore/dom/IdleDeadline.idl)
and added `JSIdleDeadline.cpp` to the list of derived sources to be compiled.
