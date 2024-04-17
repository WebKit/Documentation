# Debugging With Visual Studio

## Configuring Debugger 

Copy [​WebKit.natvis](https://github.com/WebKit/WebKit/blob/main/Tools/VisualStudio/WebKit.natvis) to the appropriate directory, which contains custom views for WebKit fundamental types.

## Debugging WebKit

There are three ways to debugging WebKit with Visual Studio. Openning the generated WebKit.sln, openning an exe file directly, and attaching running WebKit.

Invoke build-webkit, and open `WebKitBuild\Release\WebKit.sln` using Visual Studio.
If you get errors about not being able to find .props files, run Tools/Scripts/update-webkit, then close and relaunch Cygwin and Visual Studio.

Set MiniBrowser as the solution's StartUp project.
Select the MiniBrowser project in the Solution Explorer, then choose `Project > Set as StartUp Project`. This will cause the project to turn bold in the Solution Explorer.

Launch the debugger
Choose `Debug > Start Debugging`.

In Ninja builds, there is no solution files. In such case, open the exe file directly.

```
devenv -debugexe .\WebKitBuild\Debug\bin64\MiniBrowser.exe
```

## Debugging DumpRenderTree

Set DumpRenderTree as your startup project.
Configure the arguments and environment variables for the test runner.
In the DumpRenderTree project in the Solution Explorer window, right-click and select Properties....

In the Command Arguments section, enter the absolute paths for the tests you want to run, separated by spaces.
In the Environment section, put `PATH=$(ProgramFiles)\Common Files\Apple\Apple Application Support;$(PATH)`
Click OK to close the Project Properties window.

Launch the debugger.
Right-click on the DumpRenderTree project, and choose `Debug > Start New Instance`.

## Miscellaneous Tips

Follow the ​instructions for using the Microsoft and Safari symbol servers so that Visual Studio can show you backtraces that involve closed-source components.

## Using Watch Window

You can open any of the Watch windows using the `Debug > Windows > Watch` submenu.

​MSDN Magazine published a very useful ​article about Watch window pseudo-variables and format specifiers. Those of particular interest to WebKit developers are mentioned explicitly below, but the whole article is worth a read.

Adding $err,hr to the Watch Window will show you what ::GetLastError() would return at this moment, and will show you both the numerical error value and the error string associated with it.
Calling CFShow

When debugging code that uses CF types, you can invoke the ​CFShow function in the Immediate window (Debug > Windows > Immediate or Ctrl+Alt+I) to print a debug description of a CF object to the Output window like so:

```
{,,CoreFoundation}CFShow((void*)0x12345678)
```
Note that you usually won't be able to pass a variable name as the parameter to CFShow, as the Immediate window will get confused and think you're specifying a symbol in CoreFoundation.dll rather than whatever code you're debugging. It's usually easiest just to pass the address of the object directly as above.

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
