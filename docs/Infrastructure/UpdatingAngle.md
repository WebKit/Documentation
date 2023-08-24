# Update ANGLE

## Fixing ANGLE Bugs

Before you commit a WebKit patch that modifies ANGLE, please run `Tools/Scripts/update-angle --regenerate-changes`.
This will update `Source/ThirdParty/ANGLE/changes.diff` so that people can see the diff from upstream at a glance.

When fixing bugs in ANGLE, please create a new bug on [ANGLE's bug tracker](https://bugs.chromium.org/p/angleproject/issues/list) and attach the patch applied to WebKit
so that changes can eventually be merged upstream instead of maintained locally.

## Merging ANGLE from Upstream

To pull in a new revision of ANGLE, run the script `Tools/Scripts/update-angle` and follow its instructions. 
This script will attempt to update to a new version of ANGLE without losing WebKit's local changes by performing a git rebase. 
It also helps to update the CMake build files and `ANGLE.plist`.