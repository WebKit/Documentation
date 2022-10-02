# Type Inference

<!--@START_MENU_TOKEN@-->Summary<!--@END_MENU_TOKEN@-->

## Overview

Type inference is achieved by profiling values, predicting what types operations will produce based on those profiles, inserting type checks based on the type predictions, and then attempting to construct type proofs about the types of values based on the type checks.

Consider this example to motivate type inference, and optimization, of JavaScript:

```javascript
o.x * o.x + o.y * o.y
```

Say that in the context where this code is used, 'o' is an object, and it indeed has properties 'x' and 'y', and those properties are nothing special - in particular, they are not accessors. Let's also say that 'o.x' and 'o.y' usually return doubles, but may sometimes return integers - JavaScript does not have a built-in notion of an integer value, but for efficiency JavaScriptCore will represent most integers as int32 rather than as double. To understand both the problem of type inference, and its solution in JavaScriptCore, it's useful to first consider what a JavaScript engine would have to do if it had no information about 'o', 'o.x', or 'o.y':

The expression 'o.x' has to first check if 'o' has any special handling of property access. It may be a DOM object, and DOM objects may intercept accesses to their properties in non-obvious ways. If it doesn't have special handling, the engine must look up the property named "x" (where "x" is literally a string) in the object. Objects are just tables mapping strings to either values or accessors. If it maps to an accessor, the accessor must be called. If it isn't an accessor, then the value is returned. If "x" is not found in 'o', then the process repeats for o's prototype. The inference required for optimizing the object access is not covered in this section.
The binary multiply operation in the expression 'o.x * o.x' has to first check the types of its operands. Either operand may be an object, in which case its 'valueOf' method must be called. Either operand may be a string, in which case it must be converted to a number. Once both operands are appropriately converted to numbers (or if they were numbers already), the engine must check if they are both integers; if so, then an integer multiply is performed. This may overflow, in which case a double multiply is performed instead. If either operand is a double, then both are converted to doubles, and a double multiply is performed. Thus 'o.x * o.x' may return either an integer or a double. There is no way of proving, for the generic JavaScript multiply, what kind of number it will return and how that number will be represented.
The binary addition operation in the expression 'o.x * o.x + o.y * o.y' has to proceed roughly as the multiply did, except it has to consider the possibility that its operands are strings, in which case a string concatenation is performed. In this case, we could statically prove that this isn't the case - multiply must have returned a number. But still, addition must perform checks for integers versus doubles on both operands, since we do not know which of those types was returned by the multiplication expressions. As a result, the addition may also return either an integer, or a double.
The intuition behind JavaScriptCore's type inference is that we can say with good probability what type a numerical operation (such as addition or multiplication) will return, and which path it will take, if we could guess what types flowed into that operation. This forms a kind of induction step that applies to operations that don't generally operate over the heap: if we can predict their inputs, then we can predict their outputs. But induction requires a base case. In the case of JavaScript operations, the base cases are operations that get non-local values: for example, loading a value from the heap (as in 'o.x'), accessing an argument to a function, or using a value returned from a function call. For simplicity, we refer to all such non-local values as heap values, and all operations that place heap values into local variables as heap operations. For arguments, we treat the function prologue as a "heap operation" of sorts, which "loads" the arguments into the argument variables. We bootstrap our inductive reasoning about type predictions by using value profiling: both the LLInt and Baseline JIT will record the most recent value seen at any heap operation. Each heap operation has exactly one value profile bucket associated with it, and each value profile bucket will store exactly one recent value.

A straw-man view of JavaScriptCore's type inference is that we convert each value profile's most recent value into a type, and then apply the induction step to propagate this type through all operations in the function. This gives us type predictions at each value-producing operation in the function. All variables become predictively typed as well.

In reality, JavaScriptCore includes in each value profile a second field, which is a type that bounds a random subset of the values seen. This type uses the SpeculatedType (or SpecType for short) type system, which is implemented in ​SpeculatedType.h. The type of each value profile starts out as SpecNone - i.e. the type corresponding to no values. You can also think of this as bottom (see ​Lattice), or the "contradiction". When the Baseline JIT's execution counter exceeds a threshold (see JIT::emitOptimizationCheck in ​JIT.cpp), it will produce a new type to bound both the last type, and the most recent value. It may also then choose to invoke the DFG, or it may choose to let the baseline code run more. Our heuristics favor the latter, meaning that when DFG compilation kicks in, each value profile will typically have a type that bounds multiple different values.

The propagation of SpecTypes derived at value profiles to all operations and variables in a function is performed using a standard ​forward data flow formulation, implemented as a flow-insensitive fixpoint. This is one of the first phases of DFG compilation, and is only activated once the Baseline JIT decides, based on its execution count, that a function would be better off executing optimized code. See ​DFGPredictionPropagationPhase.cpp.

After each value in a function is labeled with a predicted type, we insert speculative type checks based on those predictions. For example, in a numeric operation (like 'o.x * o.y'), we insert speculate-double checks on the operands of the multiplication. If a speculation check fails, execution is diverted from optimized DFG code back to the Baseline JIT. This has the effect of proving the type for subsequent code within the DFG. Consider how the simple addition operation 'a + b' will be decomposed, if 'a' and 'b' both had SpecInt32 as their predicted type:

```
check if a is Int32 -> else OSR exit to Baseline JIT
check if b is Int32 -> else OSR exit to Baseline JIT
result = a + b // integer addition
check if overflow -> else OSR exit to Baseline JIT
```

After this operation completes, we know that:

* 'a' is an integer.
* 'b' is an integer.
* the result is an integer.

Any subsequent operations on either 'a' or 'b' do not need to check their types. Likewise for operations on the result. The elimination of subsequent checks is achieved by a second data flow analysis, called simply the DFG CFA. Unlike the prediction propagation phase, which is concerned with constructing type predictions, the CFA is concerned with constructing type proofs. The CFA, found in ​DFGCFAPhase.cpp and ​DFGAbstractInterpreterInlines.cpp, follows a flow-sensitive forward data flow formulation. It also implements sparse conditional constant propagation, which gives it the ability to sometimes prove that values are constants, as well as proving their types.

Putting this together, the expression 'o.x * o.x + o.y * o.y' will only require type checks on the value loaded from 'o.x' and the value loaded from 'o.y'. After that, we know that the values are doubles, and we know that we only have to emit a double multiply path followed by a double addition. When combined with type check hoisting, DFG code will usually execute a type check at most once per heap load.

