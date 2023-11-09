# Tips for Maintainers

Maintaining a WebKit port is a lot of work. Here are some suggestions that may help.

## Watching the Project

Bug watching is one of the most important tasks for any software project. All WebKitGTK and WPE WebKit developers should watch the `bugs-noreply@webkitgtk.org` user in [Bugzilla email preferences](https://bugs.webkit.org/userprefs.cgi?tab=email). This address is automatically CCed on all bugs created in the WebKitGTK or WPE WebKit product. If reporting a bug against other components, you should manually CC this address. This way, you can watch what other developers are doing. Watching bugs can be very time-consuming, so it often makes sense to skim bugs that are of peripheral interest to you, but if you're not watching the shared address at all then it will be impossible to be aware of important bugs and issues of the day and you will not be an effective developer.

It's also useful to view saved searches from time to time. From the [saved searches](https://bugs.webkit.org/userprefs.cgi?tab=saved-searches) preferences in Bugzilla, you can subscribe to searches shared by others, or create your own. Most developers would benefit from subscribing to the GTK/WPE Bugs search, for example, and reviewing it from time to time. Other useful searches there exist for subcategories of bugs, including accessibility bugs, font bugs, multimedia bugs, and networking bugs. Subscribing to searches here will not affect the email you receive; it will just create a link to the search in your Bugzilla footer, where you can manually review the search results from time to time.

## Zero Warnings

If there are compiler warnings during the build process, it can be very difficult for developers to notice when programming mistakes introduce new warnings. Ensuring the build remains clean of spammy warnings is therefore very important to avoid missing real warnings that could indicate serious bugs. Because warnings differ based on compiler used, compiler version, build type (debug vs. release), and build options, only you can be responsible for fixing warnings that occur with your particular build configuration. You have three options to fix the warnings: (a) by changing the code so as to no longer trigger the warning (preferred); (b) by suppressing the warning using the `IGNORE_WARNINGS_BEGIN()` and `IGNORE_WARNINGS_END()` macros defined in Source/WTF/wtf/Compiler.h, or one of the related macros defined there (the next-best option); or (c) adding compiler flags to disable the warnings to a relevant CMakeLists.txt (as a last resort). For example, the Source/WebKit subproject is built using -Wno-unused-parameter, specified in Source/WebKit/CMakeLists.txt.

If you see a new warning appear, please take the time to fix it. The developer who introduced the warning is probably building with a different compiler or build configuration than you are, and other developers will surely appreciate your taking the time to keep the build clean.

When a new version of a compiler is released, there will usually be many new warnings. It may take a day or two of effort to make the build warning-free again. This is effort well-spent to ensure the quality of WebKit.

Warnings are fatal by default in developer mode since [255961@main](https://commits.webkit.org/255961@main). To disable this, use `build-webkit --no-fatal-warnings` or pass `-DDEVELOPER_MODE_FATAL_WARNINGS=OFF` to CMake. Warnings should never be fatal for non-developer builds because this would be extremely annoying to users.

## Zero Unreviewed Pull Requests

You are ultimately responsible for finding reviewers to ensure your pull requests are reviewed, whether by pinging reviewers on Bugzilla, IRC, or email. Nobody else can do this for you. You should examine [your open pull requests on GitHub](https://github.com/WebKit/WebKit/pulls/@me) from time to time and ensure you aren't accumulating a backlog of unreviewed pull requests. The ideal size of your request queue is zero pull requests older than a few days.

## Zero Regressions?

WebKit has a zero regressions policy, meaning any committer can revert any commit if it's found to introduce a regression. That said, apply common sense. If buildbots are broken, that's an emergency and it makes sense to revert the offending commit now and then think about how to fix the problem later. If WebKitGTK no longer works at all or has suffered some other severe regression, then again, revert the offending commit now and ask questions later. But usually the issue is more minor, and it would make more sense to talk to the developer who introduced the issue before reverting it, or to not revert it at all. Developers usually don't enjoy seeing work reverted, and you won't make friends by reverting commits unnecessarily. It's not unusual for a commit to fix a major issue while also introducing a less-serious issue; it wouldn't make sense to revert a commit in blind adherence to zero regressions if that would reduce the quality of WebKit overall. Generally, cross-platform commits should be reverted only if the regression is severe. Platform-specific WPE/GTK commits can be reverted more aggressively.

## Security

Security is very important for a web engine. As a rule, any issue in which web content can crash WebKit is a security issue. In fact, almost every crash or assertion failure is a security issue. The only crashes which are not security issues are crashes that cannot be triggered by web content, but such crashes are few and far between in WebKit. Fortunately, not all crashes are equally-severe. E.g. a null pointer dereference or a release assert is merely a denial of service issue, whereas a use-after-free or buffer overflow is a code execution vulnerability.

There is a [saved search](https://bugs.webkit.org/userprefs.cgi?tab=saved-searches) in Bugzilla to display open bugs in the Security component, which will be visible to you if you are a member of the WebKit Security Team. However, because almost all crashes are security issues, most security issues are actually reported publicly instead of against the Security component.

Also, beware that `[ Crash ]` expectations are public in our TestExpectations. Crashing layout tests are thus an easy blueprint for attackers to start crafting exploits against WebKit. **The acceptable number of crashing layout tests is zero.**

### CVE Requests

Because WebKit developers regularly fix a high volume of crash reports, it would be impractical to request a CVE each time a security issue is resolved. Instead, CVEs are generally only issued for vulnerabilities discovered by third-party security researchers. This is a cynical approach to security advisory, but to request a CVE for every vulnerability would be implausible. Still, we have occasionally requested CVEs for unusually-noteworthy issues. Previous examples have included TLS certificate verification issues, message validation issues in WebKit's IPC framework, or proxy bypass issues where WebKit fails to respect the user's configured proxy settings. To request a CVE for issues that do not affect Apple ports, use [MITRE's web form](https://cveform.mitre.org/) and ignore all the instructions telling you not to use the form and to use other CNAs instead. If you try to get a CVE from another CNA instead of using MITRE's request form, you're just going to waste your time. In particular, do not use the DWF CNA.

### Advisories

The time to issue a new security advisory is right after Apple has issued a Safari security advisory. If you are responsible for security advisories, then you need to follow the [security-announce@lists.apple.com](https://lists.apple.com/mailman/options/security-announce/) mailing list to know when it's time for this, in addition to becoming a member of the [WebKit Security Team](https://webkit.org/security-policy/). There is a script to generate advisories [in the webkitgtk.org GitHub repo](https://github.com/WebKitGTK/webkitgtk.org/blob/master/generate-security-advisory).

## Stable Branches

WebKitGTK and WPE WebKit share stable branches, maintained in GitHub with names beginning with `webkitglib/`. Maintaining a stable branch is a lot of work, and deciding which commits to backport is not always easy. Our goal is to backport fixes for bugs without accidentally backporting commits that introduce new bugs, but this is sometimes easier said than done. In general, backporting more commits increases the risk of regressions, so it requires care. In addition to backporting commits proposed for backport on the [stable branch wiki page](https://github.com/WebKit/WebKit/wiki/GLib-Stable-Branches), we've successfully used two different strategies to identify other commits that should be backported.

### Carlos's Strategy

The first strategy, Carlos's strategy, is to simply review all commits to main since the last stable release and backport everything that looks important. This is the most comprehensive strategy to identify as many bugfix commits for backporting as possible, but it's very time-consuming and it's easy to miss important commits even if you are extremely careful and skillful. It can also be difficult to know for sure whether a particular commit is suitable for backporting without a high level of expertise in highly-specialized areas of the codebase. Michael thinks this strategy works better at the beginning of a new release cycle, especially before the .0 or .1 releases.

### Michael's Strategy

Later on in the lifetime of a stable branch, consider switching to Michael's strategy, which focuses on reviewing the commits that are most likely to be important candidates for backporting. Those are (a) commits that were backported to a Safari stable branch, (b) commits associated with resolved security bugs, and of course (c) platform-specific commits.

Safari backports are a good place to start because these commits have been identified as good candidates for backporting by Apple developers. Each webkitglib branch has a corresponding Safari stable branch. The corresponding stable branch is one branched shortly before or shortly after a webkitglib branch. For example, for webkit-2.22 the corresponding Safari branch was safari-606-branch. For webkit-2.24, the corresponding Safari branch was safari-607-branch. It's worth examining every commit on the corresponding Safari branch to consider whether it would be a good backport for the webkitglib branch. Most commits backported to Safari stable branches are also good candidates for webkitglib branches, except commits that are Mac-specific or address features that are not yet enabled in the webkitglib branch. For example, WebKitGTK 2.24 does not yet support service workers, WebRTC, EME, or PSON, so fixes for these features should be ignored.

Platform-specific commits generally have prefixes like `[GTK]`, `[WPE]`, `[SOUP]`, `[FreeType]`, `[GStreamer]`, and `[GLib]`. These are often important for backporting. Don't rely on developers to request backport when their commit is important; that often doesn't happen.

### Other Backporting Tips

If a commit from main does not backport cleanly to the webkitglib stable branch, it's possible the corresponding Safari branch commit may backport cleanly, or more easily.

Otherwise, if a commit is not backporting cleanly, consider whether it would be advisable to backport other commits from main in order to allow a clean backport. For example, if a bugfix commit depends on a refactoring commit, you should consider backporting the refactoring commit as well. But do so carefully. You have to consider the risk that the refactor will introduce a new bug in the stable branch, versus the risk that you would introduce a bug yourself in trying to backport a commit with conflicts.

Whenever a commit doesn't backport cleanly, you should be looking at the revision history of the affected file using trac, or consider doing a blame of the file, to see what has happened to make the backport unclean.

JavaScriptCore security fixes often involve very large diffs. Backporting these manually when there are conflicts is often quite risky. Instead, be aggressive in backporting whatever other commits are necessary from main in order to make the security fix backport more cleanly.

**Always** search for the revision number in the git log of the commit you are backporting to see if it is mentioned in other commits. If the revision number is mentioned in subsequent commits, it's probably because the revision introduced a regression. If you forget to check, Murphy's Law guarantees you will backport a commit introducing a known regression.
