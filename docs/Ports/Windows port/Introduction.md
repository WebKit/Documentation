# Windows port

WebKit had two Windows ports, Apple Windows port and WinCairo port.
WinCairo port is called Windows port after the Apple Windows port was deprecated.
It is using [cairo](https://www.cairographics.org/) for the graphics backend, [libcurl](https://curl.se/libcurl/) for the network backend.
It supports only 64 bit Windows.

## Installing Development Tools

You need CMake, Perl, Python, Ruby, gperf, the latest Windows SDK, and Visual Studio 2022 to build Windows port.
You can use [Chocolatey](https://chocolatey.org/) to install the tools.

[ActivePerl chocolatey package](https://community.chocolatey.org/packages/ActivePerl) has a problem and no package maintainer now.
XAMPP includes Perl, and running layout tests needs XAMPP. Install XAMPP instead.

```
choco install -y xampp-81 python ruby git cmake gperf
```

It supports both CMake Ninja generator and CMake Visual Studio generator.
Ninja is optional.

```
choco install -y ninja
```

Windows Git enables `autocrlf` by default. But, some layout tests files have to be checked out as LF line end style. See [Bug 240158](https://bugs.webkit.org/show_bug.cgi?id=240158).

```
 git config --global core.autocrlf input
```

### Using winget

If you prefer [winget](https://learn.microsoft.com/en-us/windows/package-manager/winget/) to Chocolatey, you can use it.
Here is the one-liner to install all tools:

```
"Git.Git Kitware.CMake Ninja-build.Ninja Python.Python.3.11 RubyInstallerTeam.Ruby.3.1 ApacheFriends.Xampp.8.2 GnuWin32.Gperf" -split " " |% { winget install --scope=machine --id $_ }
```

If `--scope=machine` isn't specified, Python is installed under your user profile directory.


## WebKit command prompt

To compile, run programs and run tests, you need to set some environment variables.
For ease of development, it's recommended to create a batch file to set environment variables and open PowerShell.
Create a batch file with the following content with adjusting it to your PC.
And put it in the top WebKit source directory.
And double-click it to open PowerShell.

```
@echo off
cd %~dp0

path C:\xampp\apache\bin;%path%
path C:\xampp\perl\bin;%path%
path %ProgramFiles%\CMake\bin;%path%
path %ProgramFiles(x86)%\Microsoft Visual Studio\Installer;%path%
for /F "usebackq delims=" %%I in (`vswhere.exe -latest -property installationPath`) do set VSPATH=%%I

rem set WEBKIT_LIBRARIES=%~dp0WebKitLibraries\win
path %~dp0WebKitLibraries\win\bin64;%path%
set WEBKIT_TESTFONTS=%~dp0Tools\WebKitTestRunner\fonts
set DUMPRENDERTREE_TEMP=%TEMP%

rem set http_proxy=http://your-proxy:8080
rem set https_proxy=%http_proxy%

rem set JSC_dumpOptions=1
rem set JSC_useJIT=0
rem set JSC_useDFGJIT=0
rem set JSC_useRegExpJIT=0
rem set JSC_useDOMJIT=0

rem set WEBKIT_SHOW_FPS=1

call "%VSPATH%\VC\Auxiliary\Build\vcvars64.bat"
cd %~dp0
start powershell
```

You can replace `powershell` with `cmd` or `wt` (Windows Terminal) if you like.


## Building

In the WinKit command prompt, invoke `build-webkit` to start building.

```
perl Tools/Scripts/build-webkit --release
```

Ensure you don't have GCC in your PATH, otherwise CMake is going to use GCC and builds will fail.

You will get required libraries [WebKitRequirements](https://github.com/WebKitForWindows/WebKitRequirements) downloaded automatically when you perform a `build-webkit`.
It checks the latest WebKitRequirements every time.
I'd like to recommend to use `--skip-library-update` for incremental build to speed up for the next time.

```
python Tools\Scripts\update-webkit-wincairo-libs.py
perl Tools\Scripts\build-webkit --release --skip-library-update
```

The build succeeded if you got `WebKit is now built` message. Run your `MiniBrowser`.

```
WebKitBuild/Release/bin64/MiniBrowser.exe
```

You can run programs under a debugger with [this instruction](../../Build & Debug/DebuggingWithVS.html).

### Building from within Visual Studio

In the WinKit command prompt,

```
perl Tools/Scripts/build-webkit --release --no-ninja --generate-project-only
```

Open the generated solution file by invoking devenv command from a WebKit command prompt.

```
devenv WebKitBuild\Release\WebKit.sln
```

Build "MiniBrowser" project.


## Running the tests

Install XAMPP as described above.

Install required Python and Ruby modules.

```
pip install pywin32
gem install webrick
```

If Apache service is running, stop it.

```
net stop apache2.4
```

Some extensions need to be registered as CGI. Modify the following commands for your Perl and Python paths, and run them as administrator.

```
reg add HKEY_CLASSES_ROOT\.pl\Shell\ExecCGI\Command /ve /d "c:\xampp\perl\bin\perl.exe -T"
reg add HKEY_CLASSES_ROOT\.cgi\Shell\ExecCGI\Command /ve /d "c:\xampp\perl\bin\perl.exe -T"
reg add HKEY_CLASSES_ROOT\.py\Shell\ExecCGI\Command /ve /d "c:\Python311\python.exe -X utf8"
```

You need openssl.exe in your PATH to run wpt server.
XAMPP contains openssl.exe in C:\xampp\apache\bin directory. Append the directory to your PATH.

Open the WinKit command prompt as administrator because http tests need to run Apache service.

Invoke `run-webkit-tests`.

```
python Tools/Scripts/run-webkit-tests --release
```

If you are using Japanese Windows, some layout tests fail due to form control size differences.
`GetStockObject(DEFAULT_GUI_FONT)` returns `MS UI Gothic` on it.
Remove `GUIFont.Facename` of `HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\GRE_Initialize`.
And, replace `MS UI Gothic` with `Microsoft Sans Serif` in `HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\FontSubstitutes\MS Shell Dlg`.

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

 * Go to [WinCairo-64-bit-WKL-Release-Build Buildbot builder page](https://build.webkit.org/#/builders/27).
 * Click any "Build #" which is green.
 * Click "> stdio" of "transfer-to-s3".
 * You can find "S3 URL" in the console log.
 * Download the zip.
 * Download the corresponding release of [WebKitRequirements](https://github.com/WebKitForWindows/WebKitRequirements/releases).
 * Unpack them, copy all DLL of WebKitRequirements to the directory of MiniBrowser.exe
 * Install the latest [vc_redist.x64.exe](https://docs.microsoft.com/en-us/cpp/windows/latest-supported-vc-redist) of Microsoft Visual C++ Redistributable for Visual Studio

### The specified module could not be found

If you simply double-click MiniBrowser.exe to execute, you'd get the following error message.

```
---------------------------
MiniBrowser can't open.
---------------------------
::LoadLibraryW failed:
path=C:\path\to\bin64\MiniBrowserLib.dll
The specified module could not be found.

---------------------------
OK
---------------------------
```

Due to the useless error message, this is a Windows port FAQ.
The error message actually means MiniBrowserLib.dll can't load required DLL of WebKitRequirements.
You have to set the env var WEBKIT_LIBRARIES. Or, copy all DLL of WebKitRequirements to the directory of MiniBrowser.exe as explained in the above section.


## Compiling with Clang

[clang-cl has a problem for /MP support.](https://reviews.llvm.org/D52193)
It's recommended to use Ninja with clang-cl.
Install clang-cl and Ninja.

```
choco install -y llvm ninja
```

Open Visual Studio Command Prompt, and invoke the following commands.

```
set CC=clang-cl
set CXX=clang-cl
perl Tools\Scripts\build-webkit --release --ninja
```

clang-cl builds are experimental, see [Bug 171618](https://bugs.webkit.org/show_bug.cgi?id=171618) for the current status.
