# JavaScriptCore

JavaScriptCore is the built-in JavaScript engine for WebKit, which implements ​ECMAScript as in ​ECMA-262 specification.

## Overview

JavaScriptCore is often referred with different names, such as ​SquirrelFish and ​SquirrelFish Extreme. Within the context of Safari, Nitro and Nitro Extreme (the marketing terms from Apple) are also commonly used. However, the name of the project and the library is always JavaScriptCore.

JavaScriptCore source code resides in WebKit source tree, it's under ​Source/JavaScriptCore directory.

## Core Engine

JavaScriptCore is an optimizing virtual machine. JavaScriptCore consists of the following building blocks: lexer, parser, start-up interpreter (LLInt), baseline JIT, a low-latency optimizing JIT (DFG), and a high-throughput optimizing JIT (FTL).

#### Lexer

Lexer is responsible for the ​lexical analysis, i.e. breaking down the script source into a series of tokens. JavaScriptCore lexer is hand-written, it is mostly in ​parser/Lexer.h and ​parser/Lexer.cpp.

#### Parser

Parser carries out the ​syntactic analysis, i.e. consuming the tokens from the lexer and building the corresponding syntax tree. JavaScriptCore uses a hand-written ​recursive descent parser, the code is in ​parser/JSParser.h and ​parser/JSParser.cpp.

#### LLInt

LLInt, short for Low Level Interpreter, executes the bytecodes produced by the parser. The bulk of the Low Level Interpreter is in ​llint/. The LLInt is written in a portable assembly called offlineasm (see ​offlineasm/), which can compile to x86, ARMv7, and C. The LLInt is intended to have zero start-up cost besides lexing and parsing, while obeying the calling, stack, and register conventions used by the just-in-time compilers. For example, calling a LLInt function works "as if" the function was compiled to native code, except that the machine code entrypoint is actually a shared LLInt prologue. The LLInt includes optimizations such as inline caching to ensure fast property access.

#### Baseline

Baseline JIT kicks in for functions that are invoked at least 6 times, or take a loop at least 100 times (or some combination - like 3 invocations with 50 loop iterations total). Note, these numbers are approximate; the actual heuristics depend on function size and current memory pressure. The LLInt will on-stack-replace (OSR) to the JIT if it is stuck in a loop; as well all callers of the function are relinked to point to the compiled code as opposed to the LLInt prologue. The Baseline JIT also acts as a fall-back for functions that are compiled by the optimizing JIT: if the optimized code encounters a case it cannot handle, it bails (via an OSR exit) to the Baseline JIT. The Baseline JIT is in ​jit/. The Baseline JIT also performs sophisticated polymorphic inline caching for almost all heap accesses.

Both the LLInt and Baseline JIT collect light-weight profiling information to enable speculative execution by the next tier of execution (the DFG). Information collected includes recent values loaded into arguments, loaded from the heap, or loaded from a call return. Additionally, all inline caching in the LLInt and Baseline JIT is engineered to enable the DFG to scrape type information easily: for example the DFG can detect that a heap access sometimes, often, or always sees a particular type just by looking at the current state of an inline cache; this can be used to determine the most profitable level of speculation. A more thorough overview of type inference in JavaScriptCore is provided in the next section.

#### DFG

DFG JIT kicks in for functions that are invoked at least 60 times, or that took a loop at least 1000 times. Again, these numbers are approximate and are subject to additional heuristics. The DFG performs aggressive type speculation based on profiling information collected by the lower tiers. This allows it to forward-propagate type information, eliding many type checks. Sometimes the DFG goes further and speculates on values themselves - for example it may speculate that a value loaded from the heap is always some known function in order to enable inlining. The DFG uses deoptimization (we call it "OSR exit") to handle cases where speculation fails. Deoptimization may be synchronous (for example, a branch that checks that the type of a value is that which was expected) or asynchronous (for example, the runtime may observe that the shape or value of some object or variable has changed in a way that contravenes assumptions made by the DFG). The latter is referred to as "watchpointing" in the DFG codebase. Altogether, the Baseline JIT and the DFG JIT share a two-way OSR relationship: the Baseline JIT may OSR into the DFG when a function gets hot, and the DFG may OSR to the Baseline JIT in the case of deoptimization. Repeated OSR exits from the DFG serve as an additional profiling hint: the DFG OSR exit machinery records the reason of the exit (including potentially the values that failed speculation) as well as the frequency with which it occurred; if an exit is taken often enough then reoptimization kicks in: callers are relinked to the Baseline JIT for the affected function, more profiling is gathered, and then the DFG may be later reinvoked. Reoptimization uses exponential back-off to defend against pathological code. The DFG is in ​dfg/.

#### FTL

FTL JIT kicks in for functions that are invoked thousands of times, or loop tens of thousands of times. See FTLJIT for more information.

At any time, functions, eval blocks, and global code in JavaScriptCore may be executing in a mix of the LLInt, Baseline JIT, DFG, and FTL. In the extreme case of a recursive function, there may even be multiple stack frames where one frame is in the LLInt, another is in the Baseline JIT, while another still is in the DFG or even FTL; even more extreme are cases where one stack frame is executing an old DFG or FTL compilation and another is executing a new DFG or FTL compilation because recompilation kicked in but execution did not yet return to the old DFG/FTL code. These four engines are designed to maintain identical execution semantics, and so even if multiple functions in a JavaScript program are executing in a mix of these engines the only perceptible effect ought to be execution performance.
