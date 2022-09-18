# Debugging With GDB/LLDB

Debugging with GDB and LLDB

## Overview

Debugging WebKit can be done through command line debuggers like GDB or LLDB.

## Setting up your Environment

### LLDB

WebKit provides debug helpers under `Tools/lldb/lldb_webkit.py`.
For automatic loading into LLDB on launch, add the line below to `~/.lldbinit`.

```
command script import {Path to WebKit}/Tools/lldb/lldb_webkit.py
```

### GDB

`Tools/gdb/webkit.py` extends GDB with WebKit-specific knowledge.
For automatic loading into GDB on launch, add the lines below to `~/.gdbinit`.

```
python
import sys
sys.path.insert(0, "{Path to WebKit}/Tools/gdb/")
import webkit
```

## Debug Launch Scripts

WebKit comes with several helper scripts to make launching a debug session quicker.

| Script | Description |
| ------ | ----------- |
| debug-minibrowser | Debug the Minibrowser application |
| debug-safari      | Debug the Safari browser          |
| debug-test-runner | Debug WebKitTestRunner            |

## Manually Debugging WebKit

The helper scripts above provide an easy way to start debugging, but a user can choose to manually launch WebKit
using GDB or LLDB directly.

### LLDB

```
export DYLD_FRAMEWORK_PATH=WebKitBuild/Debug
lldb -f WebKitBuild/Debug/DumpRenderTree -- test_file.html
```

### GDB

```
export DYLD_FRAMEWORK_PATH=WebKitBuild/Debug
gdb --args WebKitBuild/Debug/DumpRenderTree test_file.html
```
