# Building Options

An in depth guide of build options for WebKit.

## Building macOS Port

Install Xcode and its command line tools if you haven't done so already:

1. **Install Xcode** Get Xcode from [here](https://developer.apple.com/downloads). To build WebKit for OS X, Xcode 5.1.1 or later is required. To build WebKit for iOS Simulator, Xcode 7 or later is required.
2. **Install the Xcode Command Line Tools** In Terminal, run the command: `xcode-select --install`

Run the following command to build a debug build with debugging symbols and assertions:

```
Tools/Scripts/build-webkit --debug
```

For performance testing, and other purposes, use `--release` instead.

## Using Xcode

You can open `WebKit.xcworkspace` to build and debug WebKit within Xcode.

If you don't use a custom build location in Xcode preferences, you have to update the workspace settings to use `WebKitBuild` directory.  In menu bar, choose File > Workspace Settings, then click the Advanced button, select "Custom", "Relative to Workspace", and enter `WebKitBuild` for both Products and Intermediates.

## Embedded Builds

iOS, tvOS and watchOS are all considered embedded builds. The first time after you install a new Xcode, you will need to run:

```
sudo Tools/Scripts/configure-xcode-for-embedded-development
```

Without this step, you will see the error message: "`target specifies product type ‘com.apple.product-type.tool’, but there’s no such product type for the ‘iphonesimulator’ platform.`" when building target `JSCLLIntOffsetsExtractor` of project `JavaScriptCore`.

Run the following command to build a debug build with debugging symbols and assertions for embedded simulators:

```
Tools/Scripts/build-webkit --debug --<platform>-simulator
```

or embedded devices:
```
Tools/Scripts/build-webkit --debug --<platform>-device
```

where `platform` is `ios`, `tvos` or `watchos`.

## Building the GTK+ Port

For production builds:

```
cmake -DPORT=GTK -DCMAKE_BUILD_TYPE=RelWithDebInfo -GNinja
ninja
sudo ninja install
```

For development builds:

```
Tools/gtk/install-dependencies
Tools/Scripts/update-webkitgtk-libs
Tools/Scripts/build-webkit --gtk --debug
```

For more information on building WebKitGTK+, see the [wiki page](https://trac.webkit.org/wiki/BuildingGtk).

## Building the WPE Port

For production builds:

```
cmake -DPORT=WPE -DCMAKE_BUILD_TYPE=RelWithDebInfo -GNinja
ninja
sudo ninja install
```

For development builds:

```
Tools/wpe/install-dependencies
Tools/Scripts/update-webkitwpe-libs
Tools/Scripts/build-webkit --wpe --debug
```

## Building Windows Port

For building WebKit on Windows, see the [WebKit on Windows page](https://trac.webkit.org/wiki/BuildingCairoOnWindows).

## Running WebKit

### With Safari and Other macOS Applications

Run the following command to launch Safari with your local build of WebKit:

```
Tools/Scripts/run-safari --debug
```

The `run-safari` script sets the `DYLD_FRAMEWORK_PATH` environment variable to point to your build products, and then launches `/Applications/Safari.app`. `DYLD_FRAMEWORK_PATH` tells the system loader to prefer your build products over the frameworks installed in `/System/Library/Frameworks`.

To run other applications with your local build of WebKit, run the following command:

```
Tools/Scripts/run-webkit-app <application-path>
```

### iOS Simulator

Run the following command to launch iOS simulator with your local build of WebKit:

```
run-safari --debug --ios-simulator
```

In both cases, if you have built release builds instead, use `--release` instead of `--debug`.

### Linux Ports

If you have a development build, you can use the run-minibrowser script, e.g.:

```
run-minibrowser --debug --wpe
```

Pass one of `--gtk`, `--jsc-only`, or `--wpe` to indicate the port to use.

## Fixing mysterious build or runtime errors after Xcode upgrades

If you see mysterious build failures or if you’ve switched to a new version of
macOS or Xcode, delete the `WebKitBuild` directory.
`make clean` may not delete all the relevant files,
and building after doing that without deleting the `WebKitBuild` directory may result in mysterious build or dyld errors.

## Building with Address Sanitizer to investigate memory corruption bugs

To build [Address Sanitizer](https://en.wikipedia.org/wiki/AddressSanitizer) or ASan builds to analyze security bugs,
run `Tools/Scripts/set-webkit-configuration --asan --release`.
This will enable ASan build. If want to attach a debugger, you can also specify `--debug` instead of `--release`.
Once you don’t need to build or run ASan anymore, you can specify `--no-asan` in place of `--asan` to disable ASan.
Note that this configuration is saved by creating a file called Asan in the WebKitBuild directory,
so if you are trying to do a clean Asan build by deleting the build directory you need to rerun this command.

## Building with compile_commands.json

### macOS

```
make r EXPORT_COMPILE_COMMANDS=YES
generate-compile-commands WebKitBuild/Release
```

I would recommend running this command each time you pull the latest code.
If you add or remove files during development, recompile with `make r EXPORT_COMPILE_COMMANDS=YES` and rerun `generate-compile-commands WebKitBuild/Release`.



### Linux and Windows

```
cmake -DCMAKE_EXPORT_COMPILE_COMMANDS=1
```

