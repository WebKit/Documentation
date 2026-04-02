# Web Inspector Style Guide

This document covers coding conventions specific to Web Inspector (`Source/WebInspectorUI/`). For general WebKit coding style (C++, Objective-C), see the [WebKit Code Style Guidelines](https://webkit.org/code-style-guidelines/).

## Quick Reference

- [COMPATIBILITY Comments](Compatibility.md) -- version-gated compatibility guards for older Inspector backends

## Top Code Style Issues

The rules most likely to come up in code review:

1. **Next-line braces for methods and top-level functions.** Same-line braces for `if`/`for`/`while`/`switch`, nested functions, and arrow functions.
2. **Views never call protocol agents.** Only Managers (`Controllers/`) and some Models talk to the backend.
3. **`_handle` prefix for event handlers**, not `on`. The `on` prefix is not used.
4. **`let` is the default**, even if the variable is never reassigned. `const` is only for named constant parameters and true constants.
5. **Spell things out.** `identifier` not `id`, `element` not `el`. Abbreviations are avoided.
6. **Always pass `this` to `WI.Object` `addEventListener`.** The three-argument form `addEventListener(eventType, listener, thisObject)` is required. Omitting `this` triggers a `console.assert` in debug builds. (This applies to `WI.Object`'s event system, not DOM `EventTarget`.)


## Formatting

### Indentation

4 spaces. No tabs. No trailing whitespace. Applies to both `.js` and `.css` files.

### Strings

Use **double quotes** for all string literals. Single quotes are not used.

```js
let name = "network-manager";
this.element.classList.add("content-view");
```

Use `WI.UIString()` with `.format()` for user-visible interpolated strings. Template literals are acceptable for non-localized strings (debug output, CSS generation, technical strings):

```js
// Localized strings: .format()
WI.UIString("Import (%s)").format(WI.saveKeyboardShortcut.displayName);

// Non-localized: template literals are fine
styleText += `.show-whitespace-characters .CodeMirror .cm-whitespace-${count}::before {`;
```

### Braces

**Named functions and class methods** -- opening brace on the **next line**:

```js
WI.Object = class WebInspectorObject
{
    static addEventListener(eventType, listener, thisObject)
    {
        // ...
    }
};
```

**Nested functions and arrow functions** -- opening brace on the **same line** (K&R style):

```js
class Foo {
    bar()
    {
        function nested() {
            /* ... */
        }

        this.baz(() => {
            /* ... */
        });
    }
}
```

**Control flow** (`if`, `for`, `while`, `switch`) -- opening brace on the **same line**:

```js
if (target.hasDomain("Network")) {
    target.NetworkAgent.enable();
}

for (let item of this._items) {
    item.reset();
}
```

**Single-statement bodies** may omit braces:

```js
if (!supported)
    continue;
```

### Semicolons

Always use semicolons. No reliance on [Automatic Semicolon Insertion](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Lexical_grammar#automatic_semicolon_insertion).

### Trailing Commas

Use trailing commas in all multi-line object and array literals:

```js
WI.DOMManager.Event = {
    AttributeModified: "dom-manager-attribute-modified",
    AttributeRemoved: "dom-manager-attribute-removed",
    InspectedNodeChanged: "dom-manager-inspected-node-changed",
};
```

## Variable Declarations

Use **`let`** for all local variables. Do not use `var` in new code.

Use **`const`** only for named constant parameters and true constants -- values whose constancy is semantically important:

```js
// Good: const for self-documenting boolean arguments
const shouldGroupNonExclusiveItems = true;
this._scopeBar = new WI.ScopeBar("filter", items, items[0], shouldGroupNonExclusiveItems);

// Good: let for everything else, even if never reassigned
let target = WI.assumingMainTarget();
let listenersForEventType = this._listeners.get(eventType);
```

This is the **opposite** of the `const`-by-default convention common in many JS projects.

### Constructor Calls Without Arguments

Omit parentheses for no-argument constructors:

```js
this._frameIdentifierMap = new Map;
this._downloadingSourceMaps = new Set;
```

## Naming Conventions

### Classes

Almost all classes live on the `WI` namespace. The class expression name mirrors the property name:

```js
WI.NetworkManager = class NetworkManager extends WI.Object
{
```

Exceptions: generic utilities (`Multimap`, `Debouncer`) and Worker-only classes (`HTMLParser`, `JSFormatter`) live at the top level.

### Properties and Methods

- **Spell out full words**: `identifier` not `id`, `representedObject` not `repObj`.
- **Boolean getters** use `is` prefix: `get isAttached()`, `get isClosed()`.
- **Private members** use underscore prefix: `this._mainFrame`, `_resetCollection()`.
- **Event handlers** use `_handle` prefix: `_handleFrameMainResourceDidChange(event)`.

### Localized Strings

Wrap user-visible strings in `WI.UIString()`. Wrap intentionally-unlocalized strings in `WI.unlocalizedString()`:

```js
WI.UIString("Clear Network Items (%s)").format(WI.clearKeyboardShortcut.displayName);
WI.unlocalizedString("css");
```

## Class Structure

Classes follow a strict section ordering using comment headers:

```js
WI.ExampleManager = class ExampleManager extends WI.Object
{
    constructor()
    {
        super();
        this._items = new Map;
    }

    // Static

    static supportsFeature()
    {
        return InspectorBackend.hasCommand("Example.doThing");
    }

    // Target

    initializeTarget(target)
    {
        // Per-target protocol setup (Manager classes only).
    }

    // Public

    get items() { return this._items; }

    addItem(item)
    {
        // ...
    }

    // Protected

    protectedMethod()
    {
        // For subclass use only.
    }

    // Private

    _handleItemChanged(event)
    {
        // ...
    }
};
```

The section order is: constructor, `// Static`, `// Target`, `// Public`, observer/delegate sections, `// Protected`, `// Private`.

Common section headers include:

```js
// Static
// Target
// Public
// NetworkObserver
// Table delegate
// Protected (GeneralTreeElement)
// Protected
// Private
```

When overriding a superclass method, annotate the section: `// Protected (ClassName)`. Always invoke `super` in overrides unless there is a specific reason not to.

### Inline Getters

Simple getters that return a backing property go on one line:

```js
get element() { return this._element; }
get layoutPending() { return this._dirty; }
get isAttached() { return this._isAttachedToRoot; }
```

### Abstract Methods

Use `WI.NotImplementedError.subclassMustOverride()` for methods subclasses must implement:

```js
get displayName()
{
    throw WI.NotImplementedError.subclassMustOverride();
}
```

## Architecture

### Directory Structure

| Directory | Contents |
|-----------|----------|
| `Base/` | Core utilities (`WI.Object`, settings, URL/DOM utilities) |
| `Controllers/` | Manager singletons (own protocol state and domain logic) |
| `Models/` | Data model classes (`Resource`, `Script`, `DOMNode`) |
| `Views/` | UI classes, each paired with a `.css` file |
| `Protocol/` | Protocol observer dispatchers and target classes |
| `External/` | Third-party code (CodeMirror, Esprima) -- exempt from these rules |

### The Protocol Firewall

```
Protocol Agent  <-->  Observer      <-->  Manager      <-->  Model / View
   (backend)         (Protocol/)        (Controllers/)      (Models/ + Views/)
```

- **Observers** receive backend events and forward to Managers. They are thin dispatchers with no logic.
- **Managers** are the primary layer that calls protocol commands (`target.FooAgent.method()`). Some Model classes also call protocol agents directly.
- **Models** hold data and fire `WI.Object` events.
- **Views** listen to Model/Manager events and update DOM. They never call protocol agents directly.

### View Lifecycle

Views extend `WI.View`. Key lifecycle methods:

- **`initialLayout()`** -- Called once when first shown. Create complex DOM here, not in constructor.
- **`layout()`** -- Called when the view needs updating. Request via `needsLayout()`. Check `layoutReason` for `WI.View.LayoutReason.Resize` if only resize handling is needed.
- **`didLayoutSubtree()`** -- Called after `layout()` completes for the entire subtree.
- **`sizeDidChange()`** -- Called when the view's size changes.
- **`attached()`** / **`detached()`** -- Called when entering/leaving the view hierarchy. Add event listeners in `attached()`, remove in `detached()`.

```js
attached()
{
    super.attached();
    WI.networkManager.addEventListener(WI.NetworkManager.Event.FrameWasAdded, this._handleFrameWasAdded, this);
}

detached()
{
    WI.networkManager.removeEventListener(WI.NetworkManager.Event.FrameWasAdded, this._handleFrameWasAdded, this);
    super.detached();
}
```

## Event System

### Declaring Events

Events are declared as a static `Event` property outside the class body. Keys are PascalCase; values are hyphenated-lowercase prefixed with the class name:

```js
WI.NetworkManager.Event = {
    FrameWasAdded: "network-manager-frame-was-added",
    MainFrameDidChange: "network-manager-main-frame-did-change",
};
```

Use string literals for enumeration values, not `Symbol()`. `Symbol` is not cheap to create, and the uniqueness guarantee is rarely needed for enums. Reserve `Symbol` for unique identifiers in loops (e.g., `promiseIdentifier` in `Debouncer`) or expando properties on objects (e.g., `WI.TabBrowser.NeedsResizeLayoutSymbol`).

```js
// Do -- string literals for enums
WI.Resource.ResponseSource = {
    Unknown: "unknown",
    Network: "network",
    MemoryCache: "memory-cache",
};

// Don't -- Symbol is unnecessary overhead for enums
WI.Resource.ResponseSource = {
    Unknown: Symbol("unknown"),
    Network: Symbol("network"),
    MemoryCache: Symbol("memory-cache"),
};
```

### Listening and Dispatching (`WI.Object`)

The following applies to `WI.Object`'s custom event system, not the DOM `EventTarget` API.

Use the three-argument `addEventListener(eventType, listener, thisObject)`. Always pass `this` as the third argument -- it enables proper cleanup and `this`-binding:

```js
WI.Frame.addEventListener(WI.Frame.Event.MainResourceDidChange, this._mainResourceDidChange, this);
```

Dispatch with `dispatchEventToListeners`:

```js
this.dispatchEventToListeners(WI.DOMManager.Event.AttributeModified, {node, name});
```

Listen on a **class constructor** to hear events from all instances. Listen on a **specific instance** for just that object.

### One-Shot and Async Events

```js
// Listen once
WI.Target.singleFireEventListener(WI.Target.Event.Removed, this._targetRemoved, this);

// Await as a Promise (thisObject required)
await WI.DOMManager.awaitEvent(WI.DOMManager.Event.DocumentUpdated, this);
```

### Global Notifications

For application-wide events, use `WI.notifications`:

```js
WI.notifications.addEventListener(WI.Notification.GlobalModifierKeysDidChange, this._handleModifierKeysChanged, this);
```

## Collections and Iteration

Prefer `Map` and `Set` over plain objects for dynamic keys:

```js
this._frameIdentifierMap = new Map;
this._downloadingSourceMaps = new Set;
```

Prefer `for...of` for iteration:

```js
for (let override of serializedOverrides) {
    let localResourceOverride = WI.LocalResourceOverride.fromJSON(override);
    // ...
}
```

## Arrow Functions

Use arrow functions for callbacks. Always parenthesize parameters, even single ones:

```js
// Do
let results = listenersForEventType.filter((item) => item.listener === listener);

// Don't
let results = listenersForEventType.filter(item => item.listener === listener);
```

Use single-line arrow functions only when using the return value (e.g., `.filter()`, `.map()`). For side-effect-only callbacks, use multi-line form:

```js
// Do -- multi-line for side effects
target.DOMAgent.getDocument()
    .then((result) => {
        /* ... */
    })
    .catch((error) => {
        WI.reportInternalError(error);
    });

// Don't -- single-line for side effects
target.DOMAgent.getDocument()
    .then((result) => doSomething(result))
    .catch((error) => WI.reportInternalError(error));
```

## Async Patterns

Both `async`/`await` and `.then()` chaining exist. Prefer `async`/`await` for new code:

```js
WI.Target.registerInitializationPromise((async () => {
    let serialized = await WI.objectStores.localResourceOverrides.getAll();
    for (let entry of serialized) {
        // ...
    }
})());
```

### Promise Gotchas

**Always add a `.catch()` to promise chains.** Dropped promise rejections are silent and cause hard-to-debug failures. Most promise chains should have error handling:

```js
// Do
target.DOMAgent.getDocument()
    .then((result) => { /* ... */ })
    .catch((error) => { WI.reportInternalError(error); });

// Don't -- rejection silently disappears
target.DOMAgent.getDocument()
    .then((result) => { /* ... */ });
```

**Chain promises -- don't nest them.** Nested `.then()` calls create "promise pyramids" that are hard to read and easy to break:

```js
// Do -- flat chain
fetchA()
    .then((a) => fetchB(a))
    .then((b) => process(b))
    .catch(handleError);

// Don't -- nested pyramid
fetchA().then((a) => {
    fetchB(a).then((b) => {
        process(b);
    });
});
```

**Return promises from `.then()` callbacks.** Forgetting to `return` breaks the chain -- subsequent `.then()` calls receive `undefined` instead of the result:

```js
// Do -- return the inner promise
.then((result) => {
    return target.RuntimeAgent.evaluate.invoke({expression: "1+1"});
})

// Don't -- chain is broken, next .then() gets undefined
.then((result) => {
    target.RuntimeAgent.evaluate.invoke({expression: "1+1"});
})
```

**Use `Promise.all()` for parallel work**, not sequential `.then()` chains:

```js
// Do -- parallel
let [scripts, stylesheets] = await Promise.all([
    fetchScripts(),
    fetchStylesheets(),
]);

// Don't -- needlessly sequential
let scripts = await fetchScripts();
let stylesheets = await fetchStylesheets();
```

**Wrap async IIFEs when registering initialization promises:**

```js
WI.Target.registerInitializationPromise((async () => {
    // async work here
})());
```

Note the double parentheses: `(async () => { ... })()` -- the IIFE is invoked immediately and the resulting promise is passed to `registerInitializationPromise`.

## Assertions

Use `console.assert()` liberally. Pass relevant values after the condition for debugging:

```js
console.assert(target instanceof WI.Target, target);
console.assert(!disabled || typeof disabled === "boolean", disabled);
```

## CSS Conventions

### Z-Index

Never use raw z-index numbers. Use custom properties from `Views/Variables.css`:

```css
:root {
    --z-index-highlight: 64;
    --z-index-header: 128;
    --z-index-resizer: 256;
    --z-index-popover: 512;
    --z-index-tooltip: 1024;
    --z-index-glass-pane-for-drag: 2048;
    --z-index-uncaught-exception-sheet: 4096;
}
```

### Colors and Theming

Use semantic color custom properties from `Variables.css`. Dark mode is handled by redefining properties in `@media (prefers-color-scheme: dark)` blocks:

```css
.my-view {
    color: var(--text-color);
    background-color: var(--background-color-content);
}
```

### CSS Class Names

Use hyphenated-lowercase names. Each View has a paired CSS file with the same base name (`NetworkTableContentView.js` / `NetworkTableContentView.css`).
