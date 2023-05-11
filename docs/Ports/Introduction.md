# What Are WebKit Ports?

WebKit has been ported to various platforms and operating systems. The platform-specific code for each port is maintained by different teams that collaborate on the cross-platform code. The code for upstream ports is maintained directly in the [WebKit GitHub repository](https://github.com/WebKit/webkit). The following upstream ports are available:

 * Apple maintains the WebKit ports for macOS, iOS, and other Apple operating systems.
 * [Igalia](https://www.igalia.com) maintains two WebKit ports for Linux, [WebKitGTK](https://webkitgtk.org) and [WPE WebKit](https://wpewebkit.org).
 * Sony maintains the WebKit port for PlayStation.
 * The Windows port facilitates development and testing of WebKit using Windows.
 * The JSCOnly port facilitates development and testing of JavaScriptCore without the rest of WebKit.

There are also several downstream ports of WebKit, which are maintained entirely separately. Because they are not developed upstream, downstream ports are based on different versions of WebKit. Some downstream ports may be [old and insecure](https://blogs.gnome.org/mcatanzaro/2022/11/04/stop-using-qtwebkit/).

There are no cross-platform releases of WebKit. Each WebKit port is responsible for creating their own separate releases, if desired. The same applies for security advisories. Currently the ports maintained by Apple and Igalia have regular releases and security advisories, while other upstream ports do not.
