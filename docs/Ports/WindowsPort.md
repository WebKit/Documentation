# Windows port

It is using [cairo](https://www.cairographics.org/) for the graphics backend, [libcurl](https://curl.se/libcurl/) for the network backend.
It supports only 64 bit Windows.

## Cloning Webkit
Ensure that you are NOT cloning under an ancestor directory that is a git repository. This may confuse `build-webkit` script and result in failure.<br>
A shallow clone of the WebKit repository at a detached hash may work if you are just building and not intending to develop WebKit. Official Apple release tags are unlikely to work.

## Installing Development Tools

Install [the latest Visual Studio with "Desktop development with C++" workload](https://learn.microsoft.com/en-us/cpp/build/vscpp-step-0-installation).

If have included *C++ Clang Tools for Windows* for the workload, it's Llvm will take precedence and the build may fail. For this scenario, explicitilty provide the full path to an alternative Windows Llvm's `clang-cl.exe` in the Webkit Command Prompt script.

[Activate Developer Mode](https://learn.microsoft.com/en-us/windows/apps/get-started/enable-your-device-for-development#activate-developer-mode).
`build-webkit` script creates a symlink to a generated compile_commands.json.

Install CMake, Perl, Python, Ruby, gperf \([GnuWin32 Gperf](https://gnuwin32.sourceforge.net/packages/gperf.htm)\), LLVM, and Ninja.
- Python 3.12 has [a problem for WebKit at the moment](https://webkit.org/b/261113). Use Python 3.11.
- Cmake 4+ has [a dowstream problem for vcpkg woff2 at the moment](https://github.com/WebKit/Documentation/issues/129). Use Cmake 3.31.8.

You can use [Chocolatey](https://community.chocolatey.org/) to install the tools.
[ActivePerl chocolatey package](https://community.chocolatey.org/packages/ActivePerl) has a problem and no package maintainer now.
XAMPP includes Perl, and running layout tests needs XAMPP. Install XAMPP instead.

```
choco install -y xampp-81 python311 ruby git gperf llvm ninja
choco install -y cmake --version=3.31.8
```

Install pywin32 Python module for run-webkit-tests and git-webkit.

```
python -m pip install pywin32
```

Windows Git enables `autocrlf` by default. But, some layout tests files have to be checked out as LF line end style. See [Bug 240158](https://bugs.webkit.org/show_bug.cgi?id=240158).

```
git config --global core.autocrlf input
```

### Using WinGet

If you prefer [WinGet](https://learn.microsoft.com/en-us/windows/package-manager/winget/) to Chocolatey, you can use it.
Invoke the following command in an elevated PowerShell or cmd prompt.

```
winget install --scope=machine --id Git.Git Kitware.CMake Ninja-build.Ninja Python.Python.3.11 RubyInstallerTeam.Ruby.3.2 ApacheFriends.Xampp.8.2 LLVM.LLVM
winget install --id GnuWin32.Gperf
```

If `--scope=machine` isn't specified, Python is installed under your user profile directory.

WinGet may not append the path into your PC.
If some errors occered, please check your path settings, including LLVM and GnuWin32(Gperf).

## WebKit command prompt

To compile, run programs and run tests, you need to set some environment variables.
For ease of development, it's recommended to create a batch file to set environment variables and open PowerShell.
Create a batch file with the following content with adjusting it to your PC.
And put it in the top WebKit source directory.
And double-click it to open PowerShell, we call this opened shell as "WebKit command prompt" hereafter.

```
@echo off
cd %~dp0

path C:\xampp\apache\bin;%path%
path C:\xampp\perl\bin;%path%
path %ProgramFiles%\CMake\bin;%path%
path %ProgramFiles(x86)%\Microsoft Visual Studio\Installer;%path%
for /F "usebackq delims=" %%I in (`vswhere.exe -latest -property installationPath`) do set VSPATH=%%I

rem set WEBKIT_LIBRARIES=%~dp0WebKitLibraries\win
path %~dp0WebKitLibraries\win\bin;%path%
set WEBKIT_TESTFONTS=%~dp0Tools\WebKitTestRunner\fonts
set DUMPRENDERTREE_TEMP=%TEMP%

set CC=clang-cl
set CXX=clang-cl
rem set CC=<path-to-llvm>\clang-cl.exe
rem set CXX=<path-to-llvm>\clang-cl.exe

rem set http_proxy=http://your-proxy:8080
rem set https_proxy=%http_proxy%

rem You can pass necessary JSC options https://github.com/WebKit/WebKit/blob/main/Source/JavaScriptCore/runtime/OptionsList.h#L83-L607.
rem set JSC_dumpOptions=1
rem set JSC_useJIT=0
rem set JSC_useDFGJIT=0
rem set JSC_useRegExpJIT=0
rem set JSC_useDOMJIT=0

rem You can show check TextureMapper FPS via WEBKIT_SHOW_FPS.
rem set WEBKIT_SHOW_FPS=1

rem You can use ccache with pre-compiled headers @see https://ccache.dev/manual/latest.html#_precompiled_headers
rem set CCACHE_SLOPPINESS=pch_defines,time_macros,include_file_mtime,include_file_ctime

call "%VSPATH%\VC\Auxiliary\Build\vcvars64.bat"
cd %~dp0
start powershell
```

You can replace `powershell` with `cmd` or `wt` (Windows Terminal) if you like.


## Building

In the WebKit command prompt, invoke `build-webkit` to start building.

```
perl Tools/Scripts/build-webkit --release
```

You will get required libraries [WebKitRequirements](https://github.com/WebKitForWindows/WebKitRequirements) downloaded automatically when you perform a `build-webkit`.
It checks the latest WebKitRequirements every time.
I'd like to recommend to use `--skip-library-update` for incremental build to speed up for the next time.

```
python Tools\Scripts\update-webkit-win-libs.py
perl Tools\Scripts\build-webkit --release --skip-library-update
```

The build succeeded if you got `WebKit is now built` message. Run your `MiniBrowser`.

```
WebKitBuild/Release/bin64/MiniBrowser.exe
```

You can run programs under a debugger with [this instruction](../Build & Debug/DebuggingWithVS.md).

### Building from within Visual Studio

You can use CMake Visual Studio generator instead of Ninja generator.
Install [the LLVM extension](https://learn.microsoft.com/en-us/cpp/build/clang-support-msbuild) of MSBuild.
It bundles a Clang compiler.
But, if the bundled compiler is too old, you might need to [set a custom LLVM location and toolset](https://learn.microsoft.com/en-us/cpp/build/clang-support-msbuild?view=msvc-170#custom_llvm_location).
Instead of creating a Directory.build.props file, you can [set LLVMInstallDir and LLVMToolsVersion environment variables](https://marketplace.visualstudio.com/items?itemName=MarekAniola.mangh-llvm2019).

In the WebKit command prompt,

```
perl Tools/Scripts/build-webkit --release --no-ninja --generate-project-only
```

Open the generated solution file by invoking devenv command from a WebKit command prompt.

```
devenv WebKitBuild\Release\WebKit.sln
```

Build "MiniBrowser" project.


## Running the tests

WebKit test runner run-webkit-tests is using a command line debugger [NTSD](https://learn.microsoft.com/en-us/windows-hardware/drivers/debugger/debugging-using-cdb-and-ntsd) to get crash logs.
However, Windows SDK installer doesn't install it by default.

1. Right-click the Windows start menu
2. Select "Apps and Features" menu item
3. Click "Windows Software Development Kit" from the apps list
4. Click "Modify" button
5. Select "Change" and push "Next" button
6. Select "Debugging Tools for Windows" and proceed the installation

Install XAMPP as described above.

Install required Python and Ruby modules.

```
python -m pip install pywin32
gem install webrick
```

If Apache service is running, stop it.

```
net stop apache2.4
```

Some extensions need to be registered as CGI. Modify the following commands for your Perl and Python paths, and run them as administrator.

An example using **Chocolatey**
```
reg add HKEY_CLASSES_ROOT\.pl\Shell\ExecCGI\Command /ve /d "c:\xampp\perl\bin\perl.exe -T"
reg add HKEY_CLASSES_ROOT\.cgi\Shell\ExecCGI\Command /ve /d "c:\xampp\perl\bin\perl.exe -T"
reg add HKEY_CLASSES_ROOT\.py\Shell\ExecCGI\Command /ve /d "c:\Python311\python.exe -X utf8"
```

An example using **WinGet**
```
reg add HKEY_CLASSES_ROOT\.pl\Shell\ExecCGI\Command /ve /d "c:\xampp\perl\bin\perl.exe -T"
reg add HKEY_CLASSES_ROOT\.cgi\Shell\ExecCGI\Command /ve /d "c:\xampp\perl\bin\perl.exe -T"
reg add HKEY_CLASSES_ROOT\.py\Shell\ExecCGI\Command /ve /d "\`"C:\Program Files\Python311\python.exe\`" -X utf8"
```

You need openssl.exe in your PATH to run wpt server.
XAMPP contains openssl.exe in C:\xampp\apache\bin directory. Append the directory to your PATH.

Open the WebKit command prompt as administrator because http tests need to run Apache service.

Invoke `run-webkit-tests`.

```
python Tools/Scripts/run-webkit-tests --release
```

If you are using Japanese Windows, some layout tests fail due to form control size differences.
`GetStockObject(DEFAULT_GUI_FONT)` returns `MS UI Gothic` on it.
Remove `GUIFont.Facename` of `HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\GRE_Initialize`.
And, replace `MS UI Gothic` with `Microsoft Sans Serif` in `HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\FontSubstitutes\MS Shell Dlg`.
Also, change system locale to English, because Python script crashes non-English system locale. See [Bug 273060](https://bugs.webkit.org/show_bug.cgi?id=273060).

If http tests fail as flaky failures due to the socket count limit, increase the user port range. See [Bug 224523](https://bugs.webkit.org/show_bug.cgi?id=224523)
```
netsh int ipv4 set dynamicport tcp start=1025 num=64511
```

### Running the tests in Docker

You can use Docker to run LayoutTests by mounting the host directory.

```
docker run -it --rm --cpu-count=8 --memory=16g -v %cd%:c:\repo -w c:\repo webkitdev/msbuild
```

## Downloading build artifacts from Buildbot

 * Go to [Windows-64-bit-Release-Build Buildbot builder page](https://build.webkit.org/#/builders/1192).
 * Click any "Build #" which is green.
 * Click the "Archive" link under "compile-webkit" to download the zip
 * Download the corresponding release of [WebKitRequirements](https://github.com/WebKitForWindows/WebKitRequirements/releases).
 * Unpack them, copy all DLL of WebKitRequirements to the directory of MiniBrowser.exe
 * Install the latest [vc_redist.x64.exe](https://docs.microsoft.com/en-us/cpp/windows/latest-supported-vc-redist) of Microsoft Visual C++ Redistributable for Visual Studio
