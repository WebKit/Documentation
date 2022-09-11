# How To Build And Test

This section describes how to build libpas standalone. You'll be doing this a
lot when making changes to libpas. It's wise to run libpas' tests before
trying out your change in any larger system (like WebKit) since libpas tests
are great at catching bugs. If libpas passes its own tests then basic browsing
will seem to work. In production, libpas gets built as part of some other
project (like bmalloc), which just pulls all of libpas' files into that
project's build system.

Build and Test

    ./build_and_test.sh

Build

    ./build.sh

Test

    ./test.sh

Clean

    ./clean.sh

On my M1 machine, I usually do this

    ./build_and_test.sh -a arm64e

This avoids building fat arm64+arm64e binaries.

The libpas build will, by default, build (and test, if you're use
`build_and_test.sh` or `test.sh`) both a testing variant and a default variant.
The testing variant has testing-only assertions. Say you're doing some
speed tests and you just want to build the default variant:

    ./build.sh -v default

By default, libpas builds Release, but you can change that:

    ./build.sh -c Debug

All of the tools (`build.sh`, `test.sh`, `build_and_test.sh`, and `clean.sh`)
take the same options (`-h`, `-c <config>`, `-s <sdk>`, `-a <arch>`,
`-v <variant>`, `-t <target>`, and `-p <port>`).

Libpas creates multiple binaries (`test_pas` and `chaos`) during compilation, which are used by `test.sh`. Calling these binaries directly may be preferred if you would like to test or debug just one or a handful of test cases.

`test_pas` allows you to filter which test cases will be run. These are a few examples

      ./test_pas 'JITHeapTests' # Run all JIT heap tests
      ./test_pas 'testPGMSingleAlloc()' # Run specific test
      ./test_pas '(1):' # Run test case 1
