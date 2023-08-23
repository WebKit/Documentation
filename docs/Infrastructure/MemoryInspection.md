# Memory Inspection

Tracking WebKit's memory usage is important to ensure we do not use excessive resources.
The operating system (in combination with WebKit tools) provides numerous ways to inspect WebKit to discover where our memory is being allocated.

## Build Settings

### Malloc Heap Breakdown

Malloc Heap Breakdown allows for fine-grained analysis of memory allocated per class. Classes marked with `WTF_MAKE_FAST_ALLOCATED_WITH_HEAP_IDENTIFIER(ClassName);` will be individually marked when using tools like `footprint`.

To enable this build setting you need to flip two flags. One in `PlatformEnable.h` and the second in `BPlatform.h`.

```cpp
/* Source/WTF/wtf/PlatformEnable.h */

/*
 * Enable this to put each IsoHeap and other allocation categories into their own malloc heaps, so that tools like vmmap can show how big each heap is.
 * Turn BENABLE_MALLOC_HEAP_BREAKDOWN on in bmalloc together when using this.
 */
#if !defined(ENABLE_MALLOC_HEAP_BREAKDOWN)
#define ENABLE_MALLOC_HEAP_BREAKDOWN 0
#endif
```

```cpp
/* Source/bmalloc/bmalloc/BPlatform.h */

/* Enable this to put each IsoHeap and other allocation categories into their own malloc heaps, so that tools like vmmap can show how big each heap is. */
#define BENABLE_MALLOC_HEAP_BREAKDOWN 0
```

## Commands

### Footprint

Footprint is a macOS specific tool that allows the developer to check memory usage across regions.

```shell
> footprint WebKit
Found process com.apple.WebKit.WebContent [27416] from partial name WebKit
======================================================================
com.apple.WebKit.WebContent [27416]: 64-bit    Footprint: 142 MB (16384 bytes per page)
======================================================================

  Dirty      Clean  Reclaimable    Regions    Category
    ---        ---          ---        ---    ---
 108 MB        0 B        23 MB         11    WebKit malloc
9664 KB        0 B          0 B         24    MALLOC_TINY
6384 KB        0 B        16 KB          8    MALLOC_SMALL
3904 KB        0 B          0 B        768    JS VM Gigacage
...
    ---        ---          ---        ---    ---
 142 MB      21 MB        23 MB       7001    TOTAL

Auxiliary data:
    dirty: N
    phys_footprint_peak: 424 MB
    phys_footprint: 142 MB
```

#### Results

Refer to `man footprint` for a full guide on this tool.

##### Dirty

Memory that is written to by the process. Includes Swapped, non-volatile, and implicitly written memory.

##### Clean

Memory which is neither dirty nor reclaimable.

##### Reclaimable

Memory marked as available for reuse.

##### Regions

Number of VM Regions that contribute to this row.

##### Category

Descriptive name for this entry.
