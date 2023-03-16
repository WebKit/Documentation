# WebKitGTK and WPE WebKit Security Updates


## Clarification about WebKit ports, releases and security updates

WebKit is an umbrella open source project where different `ports` collaborate on a common codebase.
In this sense, the WebKit project itself doesn't have regular releases or does security advisories.

Each port is responsible for doing their own releases and security advisories.

For example:

* Apple maintains the WebKit ports for MacOS and iOS
* Sony maintains the WebKit port for PlayStation
* [Igalia](https://www.igalia.com) maintains the two currently active ports of WebKit for Linux: WebKitGTK and WPE WebKit.

So the documentation below **only** applies to the [WebKitGTK](https://webkitgtk.org) and [WPE WebKit](https://wpewebkit.org) ports.

## Overview of the WebKitGTK and WPE WebKit release process

WebKitGTK and WPE WebKit follow a 6-month development cycle and the releases for both ports are usually synced.

This is an overview of what the number of the release versions mean:

* Version numbers follow the `major.minor.patch` numbering scheme.
* Changes to the `major` version signify considerable architectural or `API` changes and rarely changes
* The `minor` version number changes throughout the development cycle and is possible to identify if a release is stable or not by looking at this number
    * An **even** `minor` version number means the release is stable and ready for production.
    * An **odd** `minor` version number means the release is a development (beta) release for testing or for pre-view of new features.
* The `patch` number is incremented for each bug-fix release and doesn't mean anything other than an incremental number.

There are two feature stable releases done every year (`minor` number is increased to an even number), typically in March and September.
Within feature stable releases, there may be any number of bug-fix releases (`patch` number is increased).

For more details about the release process and versioning schema please check:

* [WPE WebKit release schedule](https://wpewebkit.org/release/schedule/)
* [WebKitGTK release schedule](https://trac.webkit.org/wiki/WebKitGTK/StableRelease)


## WebKitGTK and WPE WebKit security updates

Developers actively backport security fixes from the WebKit `main` development branch into the last stable release.

Any stable release may contain security fixes. The concept of "stable release" is any release where the `minor` number is an **even number**.
Developers periodically release security advisories detailing which security issues have been found and which releases were affected.
Developers issue this security advisories as soon as they are aware of the problem and after doing a new stable release fixing the problem.

Developers don't backport security fixes for older stable releases. **Security updates are only done for the last stable release: that is, the last release with a `minor` even number**.
The `patch` number can be an odd or even number, in the case of the `patch` number it doesn't mean anything other than an incremental number.

For more information about the **security advisories** check:

* [WebKitGTK Security Advisories](https://webkitgtk.org/security.html)
* [WPE WebKit Security Advisories](https://wpewebkit.org/security)

## Recommended practices

These are the recommended practices for users that would like to incorporate security and privacy updates from WebKit into their app in a timely manner:

* **Use always the last stable version** of WebKitGTK or WPE WebKit.
    * Even if a specific stable release doesn't mention that it contains a security fix it is still a very good idea to update.
    * Stable releases may fix dangerous crashes or issues that may be not tagged as a security issue at the moment of the release.
    * Updating to the latest stable versions of WebKitGTK and WPE WebKit is always recommended: it is the best way of ensuring of running a safe version of WebKit.

* **Subscribe to the mailing lists** to get notifications about new releases and security advisories
    * Security advisories are sent to the port mailing list, so it is recommended to subscribe to it:
        * [WebKitGTK mailing list](https://lists.webkit.org/mailman/listinfo/webkit-gtk)
        * [WPE WebKit mailing list](https://lists.webkit.org/mailman/listinfo/webkit-wpe)

* **Verify the tarballs** of the releases
    * The release tarballs include checksums and are also signed with `PGP` (or `GPG`) signatures.
    *  After downloading the release it is recommended to check the checksums or verify the `PGP` signature.
    *  If possible, verifying the `PGP` signature is the best way to ensure your download was not compromised.
    *  Check:
        *  [Verifying WebKitGTK releases](https://webkitgtk.org/verifying.html)
        *  [Verifying WPE WebKit releases](https://wpewebkit.org/release/verify)


## Considerations when applying the security updates

Some considerations to take into acocunt when applying the security update:

* The WebKitGTK and WPE WebKit `API` aims to be compatible between `minor` versions, so if the application was using an older `minor` version of WebKitGTK or WPE WebKit it should also run with the newer version of WebKitGTK or WPE WebKit without issues (recompiling the application may not be needed if it uses dynamic linking).
* The major version rarely changes, but if it does then it may be need to check if the application code still builds and works fine with the new major version. In that case there should be a guide explaining how to port the code of the application.
