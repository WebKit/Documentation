# Web Inspector: COMPATIBILITY Comments

Web Inspector (`Source/WebInspectorUI/`) has specific conventions for `// COMPATIBILITY` comments. For additional Web Inspector coding conventions, see the [Web Inspector Style Guide](StyleGuide.md). For general WebKit coding style (C++, Objective-C), see the [WebKit Code Style Guidelines](https://webkit.org/code-style-guidelines/).

---

## Overview

Web Inspector's frontend must support communicating with backends running older versions of the Inspector protocol (for example, a newer macOS inspecting an older iOS device). When the frontend uses a protocol feature that was added or changed in a specific release, a `// COMPATIBILITY` comment marks the compatibility boundary so the code can be cleaned up when support for older versions is dropped.

### Format

```
// COMPATIBILITY (<platform> <version>): <description>
```

**Example involving multiple platforms:**
```
// COMPATIBILITY (macOS 13.0, iOS 16.0): CSS.CSSRule.ruleId did not exist yet.
```

### Version Semantics

The version in a COMPATIBILITY comment is the **last inspector protocol snapshot version that lacks the feature** -- not the version that introduced it, and not necessarily the latest shipping OS version.

Protocol snapshots capture backend API changes between releases. If there are no protocol changes between point releases, there is no new snapshot -- the later release falls back to the previous minor version's snapshot. For example, if iOS 15.6 ships but the latest protocol snapshot was for iOS 15.4, then `// COMPATIBILITY (iOS 15.4)` is correct (not iOS 15.6).

This convention enables a simple cleanup rule: when the minimum supported backend version advances past version X, search for `// COMPATIBILITY` comments mentioning version X (or earlier) and remove the compatibility code.

For example:
```javascript
// COMPATIBILITY (iOS 14.0): Debugger.setPauseOnExceptions did not have an "options" parameter yet.
if (!InspectorBackend.hasCommand("Debugger.setPauseOnExceptions", "options"))
    return;
```

This means iOS 14.0 and earlier lack the `options` parameter. When iOS 14.0 is no longer a supported backend, this guard and its comment can be removed.

### Platform Tags

Use the platform name(s) and version where the feature is absent:

| Tag | Meaning |
|-----|---------|
| `iOS 16.0` | iOS 16.0 and earlier lack this feature |
| `macOS 13.0, iOS 16.0` | Both platforms; list macOS first |
| `macOS X.Y, iOS X.Y` | Placeholder for unreleased features |

When a feature ships on multiple platforms simultaneously, list all affected platforms separated by commas. By convention, macOS is listed before iOS.

Always include the minor version (e.g., `iOS 14.0` not `iOS 14`). Older code sometimes omits it, but new comments should be explicit.

### Description Patterns

Descriptions should be concise and state what the older backend **lacks or differs in**. Common patterns from the codebase:

| Pattern | Example |
|---------|---------|
| Did not exist yet | `Debugger.setPauseOnMicrotasks did not exist yet.` |
| Did not have a parameter yet | `DOMDebugger.setEventBreakpoint did not have an "options" parameter yet.` |
| Was renamed | `Canvas.resolveCanvasContext was renamed to Canvas.resolveContext.` |
| Was removed | `Page.setShowRulers was removed.` |
| Was removed in favor of | `Inspector.activateExtraDomains was removed in favor of a declared debuggable type` |
| Was renamed/expanded | `CSS.LayoutContextType was renamed/expanded to CSS.LayoutFlag.` |
| Was sent as ... instead of | `"stackTrace" was sent as an array of call frames instead of a single call stack` |

### When to Add a COMPATIBILITY Comment

Add one whenever the frontend:
- Calls a protocol command that did not exist in an older supported backend
- Passes a parameter that was added in a later version
- Handles event data whose shape changed between versions
- Works around a renamed or removed protocol symbol

The comment should appear immediately before (or on the same line as) the compatibility guard code (typically an `InspectorBackend.hasCommand()` or `InspectorBackend.hasEvent()` check, or a feature-detection conditional).

### When to Remove

When the minimum supported backend version advances past the version named in the comment. For example, once iOS 13.0 is no longer a supported inspection target, all `// COMPATIBILITY (iOS 13.0)` blocks can be removed along with their fallback code.

### The `X.Y` Placeholder

For features not yet shipped, use `X.Y` as a placeholder version:
```javascript
// COMPATIBILITY (macOS X.Y, iOS X.Y): DOM.GridOverlayConfig.showOrderNumbers did not exist yet.
```

Replace `X.Y` with the actual version numbers before the release ships. A pre-release audit should search for remaining `X.Y` placeholders.
