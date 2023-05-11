# Dependencies Policy

WebKitGTK's dependencies policy is simple:

* We support each major Debian version until one year after the release of the next major version.
* We support each Ubuntu LTS until one year after the release of the next Ubuntu LTS.

During the support period, we intend for WebKit to remain buildable on these distributions using some system-provided compiler -- not necessarily the default system compiler -- and with the default system libstdc++. The purpose of this policy is to ensure distributions can provide updated versions of WebKit during the support period to ensure users receive security updates.

For more information on compiler requirements, see [GCC Requirement](GCCRequirement.md).

* ​[Debian Releases](https://www.debian.org/releases/)
* [Debian Packages](https://www.debian.org/distrib/packages)
* [Ubuntu Releases](https://wiki.ubuntu.com/Releases)
* [Ubuntu Packages Search](https://packages.ubuntu.com/)

| Operating System               | Release Date | WebKit Support End |
|--------------------------------|--------------|--------------------|
| Debian 10 (Buster)             | 2019-07-06   | 2022-08-14         |
| Ubuntu 20.04 (Focal Fossa)     | 2020-04-23   | 2023-04-21         |
| Debian 11 (Bullseye)	         | 2021-08-14   | 2024-06-10         |
| Ubuntu 22.04 (Jammy Jellyfish) | 2022-04-21   | April 2025         |
| Debian 12 (Bookworm)           | 2023-06-10   |                    |
