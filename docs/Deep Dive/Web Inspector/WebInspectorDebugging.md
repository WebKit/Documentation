# Debugging the Web Inspector

This page contains tips and suggested workflows for isolating, understanding, and fixing code in the Web Inspector, particularly in the user interface.

## Inspecting the Inspector

For the Mac port, set the following defaults to allow inspecting a '''local''' Web Inspector.

```
defaults write com.apple.Safari WebKitDeveloperExtrasEnabled -bool YES
defaults write com.apple.Safari WebKitDebugDeveloperExtrasEnabled -bool YES
```

NOTE: You may need to first give Terminal Full Disk Access. Remember to turn this off afterwards.

```
System Preferences > Security & Privacy > Privacy give Terminal "Full Disk Access"
```


## Rebuilding When Files Change

The Web Inspector interface is loaded from the build directory (./WebKitBuild/), not the source tree (./Source/WebInspectorUI/).
Its code is not compiled like other parts of WebKit, but it is processed by scripts that copy its resources to the build directory.
Thus, to see changes you've made to Web Inspector's JS, CSS, or images, you must re-run the inspector build scripts. This can be done without recompiling all of WebKit by running the following:

```
make -C Source/WebInspectorUI/ release
```


To automate this step, you can connect the above command to `entr`.
The `entr(1)` tool (http://entrproject.org/) can perform an action when it detects that files have changed.
The following command will run indefinitely, invoking the inspector's build scripts whenever any interface files change.

```
find -E Source/WebInspectorUI/ -regex ".*\.(js|css|html|svg|png)" | entr make -C Source/WebInspectorUI/ release
```

Then, you can open and close the inspector (or reload with Cmd+R) to see the new changes.

NOTE: depending on your system configuration, you may need to adjust the maximum open files limit for entr to work in this case. There are approximately 1000 inspector files, so this can be fixed with the following:

```
ulimit -n 2048
```

## Using Logging inside WebInspectorUI

To log console messages from the inspected page and inspector pages to the system console, set the following preferences.

```
defaults write com.apple.Safari "com.apple.Safari.ContentGroupPageIdentifier.WebKit2LogsPageMessagesToSystemConsoleEnabled" -bool YES
defaults write com.apple.Safari WebKitLogsPageMessagesToSystemConsoleEnabled -bool YES
defaults write com.apple.Safari WebKitDebugLogsPageMessagesToSystemConsoleEnabled -bool YES
```

Using `console.log` and friends in the inspector interface's code will log messages in the next-level inspector.
However, both will be interleaved if you enable output to the system console as above.

# Tips for Debugging Tests

## Force Synchronous TestHarness Output

Setting `InspectorTest.debug()` will log all inspector protocol traffic and `console.log` output to stderr which can be observed when the test completes or times out.

Setting `InspectorTest.forceDebugLogging = true` will force all test output to be emitted via window.alert, which in a LayoutTest will add a message to test output without modifying the test page.

This is useful if you suspect problems in the test harness itself, or if the test crashes before writing buffered output into the test page (which is usually scraped to produce the test output).

## Logging to System Console/stderr While Running Tests

This is basically the same as above, except that the defaults domain is different. Since the test executable WebKitTestRunner resets its domain defaults on every run, you must set logging defaults globally. This is not recommended for other purposes since it may cause unrelated WebKit instances to log lots of messages.

```
defaults write -g "com.apple.Safari.ContentGroupPageIdentifier.WebKit2LogsPageMessagesToSystemConsoleEnabled" -bool YES
defaults write -g WebKitLogsPageMessagesToSystemConsoleEnabled -bool YES
defaults write -g WebKitDebugLogsPageMessagesToSystemConsoleEnabled -bool YES
```

## Disabling Minification and Concatenation

By default, all Inspector resources are combined in a single file to minimize the time spent loading many small local files through WebKit's loading infrastructure. Unfortunately, this can make stack traces in test output hard to read. To disable combining of test resources:

### On Mac

Go to the file:

```
./OpenSource/Source/WebInspectorUI/Configurations/DebugRelease.xcconfig
```

and set `COMBINE_TEST_RESOURCES = NO`. Then rebuild the WebInspectorUI project:

```
make -C OpenSource/Source/WebInspectorUI/ release
```

and run your test again.

### On Linux GTK

Add `COMBINE_TEST_RESOURCES=NO` to `--cmakeargs`. In Debug build inspector resources are not combined by default, if you want to run Release binary but disable combining of inspector UI resources add `COMBINE_INSPECTOR_RESOURCES=NO`. Build WebKit:

```
build-webkit --gtk --cmakeargs="-DCOMBINE_INSPECTOR_RESOURCES=NO -DCOMBINE_TEST_RESOURCES=NO"
```

and run your test again.
