# Introduction

The Web Inspector allows you to view the page source, live DOM hierarchy, script debugging, profiling and more!

## Enabling the Web Inspector

### Safari

* Enable the Develop menu option in the Advanced preferences.
* Use the optional toolbar button, Develop menu or Inspect Element context menu to access the Web Inspector.

### Other WebKit clients

* Find the application's bundle identifier.
* Enter the following command once in Terminal (inserting the bundle identifier)

```
defaults write "bundle-identifier-here" WebKitDeveloperExtras -bool true
```

* Relaunch the application in order to use the Web Inspector

## Using the Web Inspector

The Web Inspector can be opened by '''right clicking anywhere on a web page''' and choosing '''Inspect Element'''.  Once open, it highlights the node on the page as it is selected in the hierarchy. You can also search for nodes by node name, id and CSS class name.

The Node pane shows the current node type and name, as well as any element attributes.

Under the Style pane we show all the CSS rules that apply to the focused node. These rules are listed in cascade order with overridden properties striked-out—letting you truly see how cascading stylesheets affect the page layout. All shorthand properties have a disclosure-triangle to show and hide the expanded properties created by the shorthand.

The Metrics pane provides a quick visual look at how margins, borders and padding affect the current node.

Various HTML and JavaScript properties, including length of text nodes, offsetWidth/Height, class names, and parent/sibling information are vieweable in the Properties pane.

See [Safari User Guide for Web Developers](http://developer.apple.com/safari/library/documentation/AppleApplications/Conceptual/Safari_Developer_Guide/UsingtheWebInspector/UsingtheWebInspector.html) for more details on other panels of the Web Inspector.

## Hacking on the Web Inspector

Most of the Web Inspector's code is HTML, JavaScript, and CSS—so it's very easy to implement new features and fix bugs!

[List Web Inspector bugs and feature requests](http://tinyurl.com/2vqypl)

## Related Blog Posts

* [Introducing the Web Inspector](http://webkit.org/blog/41/introducing-the-web-inspector)
* [Yet another one more thing… a new Web Inspector!](http://webkit.org/blog/108/yet-another-one-more-thing-a-new-web-inspector)
* [Web Inspector Redesign](http://webkit.org/blog/197/web-inspector-redesign)
* [Web Inspector Updates](http://webkit.org/blog/829/web-inspector-updates/)
* [State of Web Inspector](https://www.webkit.org/blog/2518/state-of-web-inspector/)

## Shortcut Keys

### Safari

|                            | Mac   | Windows / Linux  |
|----------------------------|-------|------------------|
| Toggle Web Inspector       | ⌥⌘I   | Ctrl-Alt-I       |
| Show Error Console         | ⌥⌘C   | Ctrl-Alt-C       |
| Start Profiling Javascript | ⌥⇧⌘P  | Ctrl-Alt-P       |

### Web Inspector

|                             | Mac | Windows / Linux |
|-----------------------------|-----|-----------------|
| Next Panel                  | ⌘]  | Ctrl-]          |
| Previous Panel              | ⌘[  | Ctrl-[          |
| Toggle Console              | ⎋   | Esc             |
| Focus Search Box            | ⌘F  | Ctrl-F          |
| Find Next                   | ⌘G  | Ctrl-G          |
| Find Previous               | ⇧⌘G | Ctrl-Shift-G    |

### Console

|                             | Mac      | Windows / Linux |
|-----------------------------|----------|-----------------|
| Next Suggestion             | ⇥        | Tab             |
| Previous Suggestion         | ⇧⇥       | Shift-Tab       |
| Accept Suggestion           | →        | Right           |
| Previous Command / Line     | ↑        | Up              |
| Next Command / Line         | ↓        | Down            |
| Previous Command            | ⌃P       |                 |
| Next Command                | ⌃N       |                 |
| Clear History               | ⌘K or ⌃L | Ctrl-L          |
| Execute                     | ⏎        | Enter           |

### Elements Panel

|                             | Mac    | Windows / Linux |
|-----------------------------|--------|-----------------|
| Navigate                    | ↑ ↓    | Up/Down         |
| Expand/Collapse Node        | ← →    | Right/Left      |
| Expand Node                 | Double-Click on tag | Double-Click on tag |
| Edit Attribute              | ⏎ or Double-Click on attribute | Enter or Double-Click on attribute |

### Styles Pane

|                                   | Mac                        | Windows / Linux |
|-----------------------------------|----------------------------|-----------------|
| Edit Rule                         | Double-Click               | Double-Click |
| Edit Next/Previous Property       | ⇥ / ⇧⇥                     | Tab/Shift-Tab |
| Insert New Property               | Double-Click on whitespace | Double-Click on whitespace |
| Increment/Decrement Value         | ⌥↑ /⌥ ↓                    | Alt- Up/Alt-Down |
| Increment/Decrement Value by 10   | ⌥⇧↑ / ⌥⇧↓                  | Alt-Shift-Up/Alt-Shift-Down |
| Increment/Decrement Value by 10   | ⌥PageUp / ⌥PageDown        | Alt-PageUp/Alt-PageDown |
| Increment/Decrement Value by 100  | ⌥⇧PageUp / ⌥⇧PageDown      | Shift-PageUp/Shift-PageDown |
| Increment/Decrement Value by 0.1  | ⌃⌥↑ /  ⌃⌥↓                 | Control-Alt-Up/Control-Alt-Down |

### Debugger

|                               | Mac          | Windows / Linux  |
|-------------------------------|--------------|------------------|
| Select Next Call Frame        | ⌃.           | Ctrl-.           |
| Select Previous Call Frame    | ⌃,           | Ctrl-,           |
| Continue                      | F8 or ⌘/     | F8 or Ctrl-/     |
| Step Over                     | F10 or ⌘'    | F10 or Ctrl-'    |
| Step Into                     | F11 or ⌘;    | F11 or Ctrl-;    |
| Step Out                      | ⇧F11 or ⇧⌘; | Shift-F11 or Ctrl-Shift-; |
| Evaluate Selection            | ⇧⌘E          | Ctrl-Shift-E     |
| Toggle Breakpoint Condition   | Click on line number | Click on line number |
| Edit Breakpoint Condition     | Right-Click on line number | Right-Click on line number |


## Using the Web Inspector remotely

### Remote Web Inspector on GTK+ and EFL ports

 * For the GTK and EFL ports, this can be enabled with an environment variable. Check the documentation on EnvironmentVariables

```
Computer1 # export WEBKIT_INSPECTOR_SERVER=${ip.ad.dre.ss}:${port}
Computer1 # MiniBrowser http://google.com
#
Computer2 # MiniBrowser http://${ip.ad.dre.ss}:${port}
```

  * The very same version of WebKit has to be used on the other side

### Apple Web Inspector Remote Experiment

[Safari User Guide for Web Developers](http://developer.apple.com/safari/library/documentation/AppleApplications/Conceptual/Safari_Developer_Guide/UsingtheWebInspector/UsingtheWebInspector.html)
In early 2010, an experiment was made to get Web Inspector to run in a plain old web page, debugging a remote web browsing session in another browser window.

A write-up is available here:
[weinre - Web Inspector Remote](http://muellerware.org/papers/weinre/manual.html), and the relevant source and demo archives are attached to this page.
