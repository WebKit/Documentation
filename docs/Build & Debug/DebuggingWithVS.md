# Debugging With Visual Studio

## Configuring Debugger 

Copy [​WebKit.natvis](https://github.com/WebKit/WebKit/blob/main/Tools/VisualStudio/WebKit.natvis) to the appropriate directory, which contains custom views for WebKit fundamental types.

## Debugging WebKit

There are three ways to debugging WebKit with Visual Studio. Opening the generated WebKit.sln, opening an exe file directly, and attaching running WebKit.

[Invoke build-webkit with `--no-ninja --generate-project-only` options](../Ports/WindowsPort.html#building-from-within-visual-studio), and open by `devenv WebKitBuild\Release\WebKit.sln` or `devenv WebKitBuild\Debug\WebKit.sln` on [WebKit command prompt](../Ports/WindowsPort.html#webkit-command-prompt).

Set MiniBrowser as the solution's StartUp project.
Select the MiniBrowser project in the Solution Explorer, then choose `Project > Set as StartUp Project`. This will cause the project to turn bold in the Solution Explorer.

Launch the debugger
Choose `Debug > Start Debugging`.

In Ninja builds, there is no solution files. In such case, open the exe file directly.

```
devenv -debugexe .\WebKitBuild\Debug\bin64\MiniBrowser.exe
```

## Miscellaneous Tips

Follow the ​instructions for using [the Microsoft symbol server](https://learn.microsoft.com/en-us/windows-hardware/drivers/debugger/microsoft-public-symbols) so that Visual Studio can show you backtraces that involve closed-source components.

Adding $err,hr to [the Watch Window](https://learn.microsoft.com/en-us/visualstudio/debugger/watch-and-quickwatch-windows?view=vs-2022) will show you what ::GetLastError() would return at this moment, and will show you both the numerical error value and the error string associated with it.

## Debugging Multiple Processes

You can attach a single debugger to more than one process. To do this, launch or attach to the first process, then use Tools > Attach to Process… or Ctrl+Alt+P to attach to the second process. Your breakpoints will apply to both processes.

There is a Visual Studio Extension to attach child processes automatically. [​Introducing the Child Process Debugging Power Tool](https://devblogs.microsoft.com/devops/introducing-the-child-process-debugging-power-tool/)

There are two ways to see which process the debugger is currently operating on, and to switch the current process: the Processes window and the Debug Location toolbar. 
You can open the Processes window using `Debug > Windows > Processes` or `Ctrl+Shift+Alt+P`. You can show the Debug Location toolbar using View > Toolbars > Debug Location.

Visual Studio will always pause all processes (i.e., you can't pause just one process). Similarly, Visual Studio will always step all processes when using the Step In/Over/Out commands.

## Inspecting WebKit2 API types

You can inspect WebKit2 API types in Visual Studio by casting them to their underlying WebKit2 implementation type. For example, say you have a WKMutableDictionaryRef that points to address 0x12345678 and want to see what it contains. You can view its contents using the following watch expression (in either the Watch Window or Quick Watch Window):

```
{,,WebKit}(WebKit::MutableDictionary*)0x12345678
```
The same technique will work for other WebKit2 API types as long as you substitute the appropriate type for MutableDictionary above.
