# Security Updates

Before reading this document, please also [learn about WebKit ports](../Introduction.md) and [WebKitGTK and WPE WebKit releases and versioning](ReleasesAndVersioning.md).

## WebKitGTK and WPE WebKit Security Updates

Developers actively backport security fixes from the WebKit main development branch into the latest stable release.

Any stable release may contain security fixes. The concept of "stable release" is any release where the minor number is an even number. Developers periodically release security advisories detailing which security issues have been found and which releases were affected. Developers issue these security advisories shortly after creating a new stable release fixing the problem.

Developers don't generally backport security fixes for older stable releases. **Security updates are only available for the latest stable release branch**, i.e. the latest branch with an even minor version number.

For more information about the security advisories, see:

* [WebKitGTK Security Advisories](https://webkitgtk.org/security.html)
* [WPE WebKit Security Advisories](https://wpewebkit.org/security)

## Recommended Practices

These are the recommended practices for users that would like to incorporate security and privacy updates from WebKit into their app in a timely manner:

* Use the latest stable version of WebKitGTK or WPE WebKit.
    * Even if a specific stable release doesn't mention that it contains a security fix, it is still a very good idea to update.
    * Stable releases may fix dangerous crashes or issues that may be not tagged as a security issue at the moment of the release.
    * Updating to the latest stable versions of WebKitGTK and WPE WebKit is always recommended: it is the best way of ensuring you are running a safe version of WebKit.

* Subscribe to the mailing lists to get notifications about new releases and security advisories.
    * Security advisories are sent to the port mailing list, so it is recommended to subscribe to it:
        * [WebKitGTK mailing list](https://lists.webkit.org/mailman/listinfo/webkit-gtk)
        * [WPE WebKit mailing list](https://lists.webkit.org/mailman/listinfo/webkit-wpe)

* Verify the tarballs of the releases.
    * The release tarballs include checksums and are also signed with PGP signatures.
    * After downloading the release, it is recommended to check the checksums or verify the PGP signature. Verifying the PGP signature is the best way to ensure your download was not compromised.
    * See:
        *  [Verifying WebKitGTK releases](https://webkitgtk.org/verifying.html)
        *  [Verifying WPE WebKit releases](https://wpewebkit.org/release/verify)


## Considerations When Applying Security Updates

Some considerations to take into account when applying security updates:

* The WebKitGTK and WPE WebKit API aims to be compatible between minor versions, so if the application was using an older minor version of WebKitGTK or WPE WebKit, it should also run with the newer version of WebKitGTK or WPE WebKit without issues. (Recompiling the application is not needed.)
* The major version rarely changes, but if it does then you may need to check if the application code still builds and works fine with the new major version. In that case there should be a guide explaining how to port the code of the application.
