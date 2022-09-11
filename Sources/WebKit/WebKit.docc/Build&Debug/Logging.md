# Logging

Logging in WebKit.

## Setup

Each framework (WebCore, WebKit, WebKitLegacy, WTF) enable their own logging infrastructure independently (though the infrastructure itself is shared). If you want to log a message, `#include` the relevant framework's `Logging.h` header. Then, you can use the macros below.

Beware that you can't `#include` multiple framework's `Logging.h` headers at the same time - they each define a macro `LOG_CHANNEL_PREFIX` which will conflict with each other. Only `#include` the `Logging.h` header from your specific framework.

If you want to do more advanced operations, like searching through the list of log channels, `#include` your framework's `LogInitialization.h` header. These do not conflict across frameworks, so you can do something like

```
#include "LogInitialization.h"
#include <WebCore/LogInitialization.h>
#include <WTF/LogInitialization.h>
```

Indeed, WebKit does this to initialize all frameworks' log channels during Web Process startup.

## Logging messages

There are a few relevant macros for logging messages:

- `LOG()`: Log a printf-style message in debug builds. Requires you to name a logging channel to output to.
- `LOG_WITH_STREAM()` Log an iostream-style message in debug builds. Requires you to name a logging channel to output to.
- `RELEASE_LOG()`: Just like `LOG()` but logs in both debug and release builds. Requires you to name a logging channel to output to.
- `WTFLogAlways()`: Mainly for local debugging, unconditionally output a message. Does not require a logging channel to output to.

Here's an example invocation of `LOG()`:

```
LOG(MediaQueries, "HTMLMediaElement %p selectNextSourceChild evaluating media queries", this);
```

That first argument is a log channel. These have 2 purposes:

- Individual channels can be enabled/disabled independently (So you can get all the WebGL logging without getting any Loading logging)
- When multiple channels are enabled, and you're viewing the logs, you can search/filter by the channel

Here's an example invocation of `LOG_WITH_STREAM()`:

```
LOG_WITH_STREAM(Scrolling, stream << "ScrollingTree::commitTreeState - removing unvisited node " << nodeID);
```

The macro sets up a local variable named `stream` which the second argument can direct messages to. The second argument is a collection of statements - not expressions like `LOG()` and `RELEASE_LOG()`. So, you can do things like this:

```
LOG_WITH_STREAM(TheLogChannel,
    for (const auto& something : stuffToLog)
        stream << " " << something;
);
```

The reason why (most of) these use macros is so the entire thing can be compiled out when logging is disabled. Consider this:

```
LOG(TheLogChannel, "The result is %d", someSuperComplicatedCalculation());
```

If these were not macros, you'd have to pay for `someSuperComplicatedCalculation()` whether logging is enabled or not.

## Enabling and disabling log channels

Channels are enabled/disabled at startup by passing a carefully crafted string to `initializeLogChannelsIfNecessary()`. On the macOS and iOS ports, this string comes from the _defaults_ database. On other UNIX systems and Windows, it comes from environment variables.

You can read the grammar of this string in `initializeLogChannelsIfNecessary()`. Here is an example:

```
WebGL -Loading
```

You can also specify the string `all` to enable all logging.

On macOS/iOS and Windows, each framework has its own individually supplied string that it uses to enable its own logging channels. On Linux, all frameworks share the same string.

### Linux

Set the `WEBKIT_DEBUG` environment variable.

```
WEBKIT_DEBUG=Scrolling Tools/Scripts/run-minibrowser --gtk --debug
```

### macOS

On macOS, you can, for example, enable the `Language` log channel with these terminal commands:

```
for identifier in com.apple.WebKit.WebContent.Development com.apple.WebKit.WebContent org.webkit.MiniBrowser com.apple.WebKit.WebKitTestRunner org.webkit.DumpRenderTree -g /Users/$USER/Library/Containers/com.apple.Safari/Data/Library/Preferences/com.apple.Safari.plist; do
    for key in WTFLogging WebCoreLogging WebKitLogging WebKit2Logging; do
        defaults write ${identifier} "${key}" "Language"
    done
done
```

You may also need to specify these strings to `com.apple.WebKit.WebContent.Development`, the global domain, or the Safari container, depending on what you're running.

You may also pass this key and value as an argument:

```
Tools/Scripts/run-minibrowser --debug -WebCoreLogging Scrolling
```

### Windows

Set the `WebCoreLogging` environment variable.

## Adding a new log channel

Simply add a line to your framework's `Logging.h` header. Depending on how the accompanying `Logging.cpp` file is set up, you may need to add a parallel line there. That should be all you need. It is acceptable to have log channels in different frameworks with the same name - this is what `LOG_CHANNEL_PREFIX` is for.
