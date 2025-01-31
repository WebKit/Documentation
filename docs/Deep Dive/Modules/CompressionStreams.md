# Compression Streams

Compression Streams Module

## Overview

Compression Streams offer a built in way to compress and decompress data based on several common file formats.

## Supported Formats

| Format | Specification |
| ------ | ------------- |
| gzip   | [RFC1952](https://www.rfc-editor.org/rfc/rfc1952) |
| deflate (also known as ZLIB) | [RFC1950](https://www.rfc-editor.org/rfc/rfc1950) |
| deflate-raw | [RFC1951](https://www.rfc-editor.org/rfc/rfc1951) |

## Specification

* [Online Specification](https://wicg.github.io/compression/)
* [Compression Streams GitHub](https://github.com/WICG/compression)

## Design

Compression Streams work by passing a chunk of data (uint8 array) in and then returning the compression/decompression output of that chunk. There can be many chunks of data passed in during a compression/decompression stream.

Speed is of paramount importance when trying to compress/decompress data.

In Compression Streams, we try to allocate enough memory up front, so we only have to perform the compression once. For Decompression Streams, we employ a 2x increase in memory allocated each pass we attempt to decompress a chunk (with a cap of 1GB). This design was done to ensure minimal amounts of allocations being required, and to limit the number of times we needed to call inflate/deflate.

Of course with the increase in memory usage, on smaller memory devices we may hit a cap. To handle this, we implemented a back off algorithm that will quickly scale back memory allocation size if they start to fail.

We currently buffer all the compression/decompression output per chunk, and return them to the user all at once. We could also consider the possibility of returning the chunk output to the user after every call to inflate/deflate.

## Libraries

On Windows and Linux we exclusively use zlib to perform the heavy lifting for all compression and decompression algorithms. 

On Apple platforms we leverage the Compression Framework for the deflate-raw decompression to achieve extra performance. The rest of the operations use zlib. Compression Framework only supports deflate-raw for our use case, and there are currently no performance benefits for using this framework to handle compression over zlib.


## Notes

Compression Streams does contain one minor flaw for the gzip and deflate algorithms. There is a checksum located at the end of both of these file formats. This means that you can decompress a large file, but if any issue occurs during verifying the checksum step you may not be able to trust any of the output. This is ultimately due to the file formats design, but it does not allow for any real salvaging of any of the decompressed data if something goes wrong.
