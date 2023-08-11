# Web Inspector Syle Guide

These are JavaScript coding styles used in the [https://trac.webkit.org/browser/trunk/Source/WebInspectorUI/ Source/WebInspectorUI/UserInterface](https://trac.webkit.org/browser/trunk/Source/WebInspectorUI/ Source/WebInspectorUI/UserInterface) folder.

(Note: Few if any of these guidelines are checked by `check-webkit-style`. There's a tracking bug for that: [https://bugs.webkit.org/show_bug.cgi?id=125045](https://bugs.webkit.org/show_bug.cgi?id=125045))

## Non-code Style

For user-facing strings, we follow the macOS Human Interface Guidelines.

* [Guidelines for help tags](https://developer.apple.com/library/content/documentation/UserExperience/Conceptual/OSXHIGuidelines/Assistance.html) (aka tooltips)
* [Guidelines for UI labels](https://developer.apple.com/library/content/documentation/UserExperience/Conceptual/OSXHIGuidelines/TerminologyWording.html#//apple_ref/doc/uid/20000957-CH15-SW4)
* [Guidelines for keyboard shortcuts](https://developer.apple.com/library/content/documentation/UserExperience/Conceptual/OSXHIGuidelines/Keyboard.html#//apple_ref/doc/uid/20000957-CH84-SW1)

## Localization

* Include a unique key and comment when dealing with arbitrary strings. Use `@` in the key to denote where in the interface the string can be found. (ex: `WI.UIString("Frames")` vs `WI.UIString("Frames", "Frames @ Execution Context Picker", "Title for list of HTML subframe JavaScript execution contexts")`).

## Tokens, spacing, indentation, syntax

* No trailing whitespace.
* Indent with 4 spaces.
* Double quoted strings; use template strings if a bunch of interpolation is required.
* The `{` after a named, non-inlined function goes on the next line. Anywhere else, the `{` stays on the same line.
* Style for object literals is: `{key1: value1, key2: value2}`. When key and variable names coincide, use the syntax `{key}` rather than `{key: key}`. If the object is complex enough, each `key: value,` should be on its own line.
* Always include a trailing comma for object literals.
* Add new lines before and after different tasks performed in the same function.
* Else-blocks should share a line with leading `}`.
* Long promise chains should place `.then()` blocks on a new line.
* Calling a constructor with no arguments should have no parenthesis `()`. (ex: `var map = new Map;`)
* Put anonymous functions inline if they are not used as a subroutine.
* Prefer `let` to `var`, unless the variable is not used in a block scoping manner. Be careful when using `let` with `case` switches, as [all switch cases share the same block by default](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Statements/let#Temporal_dead_zone_and_errors_with_let). Only use `const` for values that will not change between executions (i.e. actual constants).
* Use arrow functions when possible, unless it makes code less readable. See below for examples.
* For default parameters, add a space around the default assignment: `function foo(isGood = false)`
* Trivial public getters can be made a single line and moved to the top of the list of getters in a class, unless there is a corresponding setter.

## Naming things

* Avoid using the "on" prefix where possible. The `_onFoo` methods can just be `_foo` or `_handleFoo` (preferred for event listeners).
* New class names should use the name of the base class as a suffix. (ex: `TimelinesContentView` < `ContentView`). Exceptions: classes extending `WI.Object` (unless they are a represented object).
* Spell out `identifier` instead of `id` if not doing so would result in a name ending with capitalized `Id`. For example, just `this.id` is fine, but `this.breakpointId` should be `this.breakpointIdentifier`.
* An object's events live on the `Event` property of the constructor. Event names are properties on the `Event` object, and property values duplicate the event name, but are lowercased, hyphenated, and prefixed with the constructor name. See the skeleton example below.
* When serializing a function to be evaluated in a different execution context, such as from inspector to inspected page or layout test to inspector, make it obvious where the function is going to be evaluated. For example, if a function will be sent from Inspector context to inspected page context, the name `inspectedPage_node_getFlowInfo()` signifies that the function will be evaluated in the inspected page, with `this` bound to a node, and it performs the action `getFlowInfo`.

## API preferences

* Use `Map` and `Set` collections instead of plain objects if the key values are unknown or not monotonic (i.e., frequently added then removed).
* Use `hsla()` over hex or `rgba()` for colors in CSS.
* Use `for..of` syntax when performing actions on each element. Use `forEach` when chaining methods in a functional style. Use a classical for loop when doing index math.
* When using `forEach` or `map`, use an arrow function or supply the `this`-object as the optional second parameter rather than binding it.
* In promise chains, use arrow functions for lexical `this`, rather than assigning `const instance = this;' or `.bind`ing every function's `this`-argument.
* Use destructuring assignment when digging values out of a JSON object or "args" object.
* Use default parameters when it makes sense.
* Use `super` to make calls to base class (possibly overridden) methods.

## Layering and abstractions

* Firewall the protocol inside the Manager classes. JSON objects received from the protocol are called "payload" in the code. The payload is usually deconstructed at the Managers level and passes down as smart objects inheriting from `WI.Object`.
* Avoid accessing *View classes from *Manager or *Object classes. This is a layering violation that prevents writing tests for models.
* Avoid storing DOM elements in *Manager or *Object classes. (see above.)
* In the backend, avoid using Inspector TypeBuilders outside of InspectorAgent classes. We want to isolate protocol considerations from other functionality in JavaScriptCore and WebCore.

## Understanding and Using Promises

[What's so great about Promises?](http://blog.parse.com/2013/01/29/whats-so-great-about-javascript-promises/) [The point of promises is to give us back functional composition](http://domenic.me/2012/10/14/youre-missing-the-point-of-promises/) and error bubbling in the async world. They do this by saying that your functions should return a promise, which can do one of two things:

1. Become __fulfilled__ by a **value**
2. Become __rejected__ with an **Error instance** or by throwing an exception

A promise that is eiher fulfilled or rejected is said to be __settled__. A promise that has not settled is said to be __pending__.

And, if you have a correctly implemented `then()` function, then fulfillment and rejection will compose just like their synchronous counterparts, with fulfillments flowing up a compositional chain, but being interrupted at any time by a rejection that is only handled by someone who declares they are ready to handle it.

### Promise Gotchas

(Summarized from [change.org Blog](http://making.change.org/post/69613524472/promises-and-error-handling) and [The Art of Code Blog](http://taoofcode.net/promise-anti-patterns/))

* Don't nest promises to perform multiple async operations; instead, chain them or use `Promise.all()`.
* Beware of storing or returning promise values that are not from the end of a chain. Each `.then()` returns a new promise value, so return the last promise.
* Use `Promise.all()` with `map()` to process an array of asynchronous work in parallel. Use `Promise.all()` with `reduce()` to sequence an array asynchronous work.
* If a result may be a promise or an actual value, wrap the value in a promise, e.g., `Promise.resolve(val)`
* Use `.catch()` at the end of a chain to perform error handling. '''Most promise chains should have a catch block to avoid dropping errors'''.
* To reject a promise, throw an `Error` instance or call the `reject` callback with an `Error` instance.
* A `.catch()` block is considered resolved if it does not re-throw an `Error` instance. Re-throw if you want to log an error message and allow other parts of a chain (i.e, an API client) to handle an error condition.
* Don't directly pass a promise's `resolve` function to `Object.addEventListener`, as it will leak the promise if the event never fires. Instead, use a single-fire `WI.EventListener` object defined outside of the promise chain and connect it inside a `.then()` body. Inside the `.catch` block, disconnect the `EventListener` if necessary.
* For APIs that return promises, document what the fulfilled value will be, if any. Example: `createSession() // --> (sessionId)`

## Arrow Functions

Arrow functions simplify a common use of anonymous functions by providing a shorter syntax, lexical binding of `this` and `arguments`, and implicit return. While this new syntax enables new levels of terse code, we must take care to keep our code readable.

### Implicit return

Arrow functions with one expression have an implicit return. All of these are equivalent (modulo `this` binding, arguments, constructor usage, etc.):

```
1   let foo = val => val;
2   let foo = (val) => val
3   let foo = (val) => val;
4   let foo = (val) => { return value++; };
5   let foo = (val) => {
        return value++;
    };
6   let foo = function doStuff(val) { return value++; };
7   let foo = function doStuff(val) {
        return value++;
    };
```

Never use option (1), because it is a special case that only applies when the function has one argument, reducing predictability.

In cases where the return value is used and the single expression is a constant ("foo"), a variable (foo), a member (this.foo), or evaluates to a Promise, use option (2). Never use braces though, because implicit return only works if there are no braces around the single expression.

In cases where the expression computes a value (a + 42) or performs a side effect (++a), prefer option 5.
In some sense, curly braces are a signpost to the effect of "careful, we do actual work here".

If the implicit return is not used (4, 5, 6, 7), always put the function body on new lines from the `{` and `}` (as demonstrated in 5 and 7).

GOOD:

```
setTimeout(() => {
    testRunner.notifyDone();
}, 0);
```

BAD:

```
// return value not implicitly returned

setTimeout(() => {
    testRunner.notifyDone()
}, 0);
```


```
// implicit return value not used

setTimeout(() => testRunner.notifyDone(), 0);
```

### When not to arrow

When assigning a function to a subclass prototype (in the old way of setting up classes), always use the normal function syntax, to avoid breaking subclasses who use a different 'this' binding. Note that arrow functions are NOT acceptable for assigning functions to singleton objects like `WI`, since the captured lexical `this` is typically the global object.

GOOD:

```
Base.prototype.compute = function(a, b, c) {
    // ...
};

Foo.prototype.compute = function(a, b, c) {
    Base.prototype.compute.call(this, a, b, c);
};

WI.UIString = function(format, args) {
    // ...
};
```

BAD:

```
// `this` will be `window`

Base.prototype.compute = (a, b, c) => {
    // ...
};

Foo.prototype.compute = (a, b, c) => {
    Base.prototype.compute.call(this, a, b, c);
};

WI.UIString = (format, args) => {
    // ...
};
```

Also use the normal function syntax when naming an anonymous function improves readability of the code. In this case, use Function.prototype.bind or assign the arrow function into a local variable first.

GOOD:

```
Promise.resolve().then(
    function resolved(value) { ... },
    function rejected(value) { ... }
);
```

BAD:

```
Promise.resolve().then(
    (value) => { ... },
    (value) => { ... }
);
```


## New class skeleton

New Inspector object classes use ES6 class syntax and should have the following format:

```
WI.NewObjectType = class NewObjectType extends WI.Object
{
    constructor(type, param)
    {
        console.assert(param instanceof WI.ExpectedType);

        super();

        this._type = type;
        this._propertyName = param;
    }

    // Static

    static computeBestWidth(things)
    {
        // ...
        return 3.14159;
    }

    // Public

    get type() { return this._type; }

    get propertyName()
    {
        return this._propertyName;
    }

    set propertyName(value)
    {
        this._propertyName = value;
        this.dispatchEventToListeners(WI.NewObjectType.Event.PropertyWasChanged);
    }

    publicMethod()
    {
        /* public methods called outside the class */
    }

    // Protected

    protectedMethod(event)
    {
        /* delegate methods and overrides */
    }

    // Private

    _privateMethod()
    {
        /* private methods are underscore prefixed */
    }
};

WI.NewObjectType.Event = {
    PropertyWasChanged: "new-object-type-property-was-changed",
};

```

## CSS

### z-index

Z-index variables are defined in [Variables.css](https://trac.webkit.org/browser/trunk/Source/WebInspectorUI/UserInterface/Views/Variables.css). Usage example:

```
.popover {
    z-index: var(--z-index-popover);
}
```

Read more about the rationale in [Bug 151978](https://bugs.webkit.org/show_bug.cgi?id=151978).
