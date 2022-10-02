# Bug Tracking

## Overview

WebKit uses [Bugzilla](https://www.bugzilla.org) as our primary bug tracking tool, which is hosted at [bugs.webkit.org](https://bugs.webkit.org/).
We use Bugzilla to file bugs, and then we perform code review using [GitHub](https://github.com/webkit/webkit).

### Filing a Bug

To [file a new WebKit bug](https://bugs.webkit.org/enter_bug.cgi) please review the steps below.

#### Create a Bugzilla Account
You’ll need to [create a Bugzilla account](https://bugs.webkit.org/createaccount.cgi) to be able to report bugs and comment on them.

#### Check Your WebKit Version
Please ensure you are using latest version of WebKit before filing to verify your issue has not already been resolved. You can download the latest WebKit build from our build archives [here](https://webkit.org/build-archives).

#### Search Bugzilla
Please [search through Bugzilla](https://bugs.webkit.org/query.cgi?format=specific&product=WebKit) first to check if your issue has already been filed. This step is very important! If you find that someone has filed your bug already, please add your comments on the existing bug report.

#### File the Bug!
If a bug does not already exist you can file a bug [here](https://webkit.org/new-bug). The [Writing a Good Bug Report](https://webkit.org/bug-report-guidelines) document gives some tips about the most useful information to include in bug reports. The better your bug report, the higher the chance that your bug will be addressed (and possibly fixed) quickly!

#### Next Steps
Once your bug is filed, you’ll receive email when it’s updated at each stage in the [bug life cycle](https://webkit.org/bug-life-cycle). After the bug is considered fixed, you may be asked to download [the latest WebKit Build Archive](https://webkit.org/build-archives) and confirm that the fix works for you.

> Note: Safari specific bugs should be reported to Apple [here](https://feedbackassistant.apple.com).

### Editing Bugs

To edit an existing bug on Bugzilla you may need [editbug-bits](https://webkit.org/bugzilla-bits/).

### Reporting Security Bugs

Security bugs have their own components in [bugs.webkit.org](https://bugs.webkit.org/).
We’re also working on a new policy to delay publishing tests for security fixes until after the fixes have been widely deployed.

_***Please keep all discussions of security bugs and patches in the Security component of Bugzilla.***_
