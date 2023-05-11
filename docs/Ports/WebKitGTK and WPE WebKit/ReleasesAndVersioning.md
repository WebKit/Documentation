# Releases and Versioning

WebKitGTK and WPE WebKit follow a 6-month development cycle and the releases for both ports are usually synced.

Here is an overview of what the version numbers mean:

* Version numbers follow the major.minor.patch numbering scheme.
* Changes to the major version are very rare and signify considerable architectural changes.
* The minor version number changes throughout the development cycle and it is possible to identify if a release is stable or not by looking at this number
    * An even minor version number means the release is stable and ready for production.
    * An odd minor version number means the release is a development (beta) release for testing or preview of new features.
* The patch number is incremented for each bugfix release and is just an incremental number.

There are two stable features releases every year (where the minor number is increased to an even number and the patch number is zero), typically in March and September. There may be any number of bugfix releases (where the patch number is increased).

[Read more about the WPE WebKit release process and versioning scheme](https://wpewebkit.org/release/schedule/).
