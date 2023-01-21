# Good First Tacks

Here are some proposals for tasks that new contributors might want to tackle. They are designed to be self-contained and asynchronous.

Please join the [WebKit slack](http://webkit.slack.com) and ping the listed mentor before you start to avoid duplicating work, especially for hard tasks. This would also help you get feedback soon, so that you don't spend time writing code that can't be merged.

## JavaScriptCore

### Easy tasks

#### Improve disassembly output

Mentor: [@justinmichaud](https://github.com/justinmichaud/) PST

We are missing SIMD ARM instructions in our disassembly. This task involves adding those, and making the disassembler output more pretty.

Please see [`Source/JavaScriptCore/disassembler/ARM64/A64DOpcode.h`](https://github.com/WebKit/WebKit/blob/main/Source/JavaScriptCore/disassembler/ARM64/A64DOpcode.h).

### Hard tasks

#### Implement the Relaxed SIMD proposal (stage 3)

Mentor: [@justinmichaud](https://github.com/justinmichaud/) PST

This task involves adding a new JSC feature flag, implementing the listed instructions in the proposal on ARM and Intel in both WASM JIT tiers, and importing the spec tests / writing your own.

#### Implement extended constant (stage 4)

Mentor: [@justinmichaud](https://github.com/justinmichaud/)  [@Constellation](https://github.com/Constellation) PST

This task involves adding a new JSC feature flag, implementing the listed instructions in the proposal to allow more expression for wasm constants, and importing the spec tests / writing your own.