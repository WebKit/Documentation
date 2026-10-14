# Dependencies Policy

The dependencies policy of WebKitGTK and WPE WebKit consists of two rules:

* We support each major Debian version until one year after the release of the next major version.
* We support each Ubuntu LTS until one year after the release of the next Ubuntu LTS.

During the support period, we intend for WebKit to remain buildable on these distributions using some system-provided compiler -- not necessarily the default system compiler -- and with the default system libstdc++. The purpose of this policy is to ensure distributions can provide updated versions of WebKit during the support period to ensure users receive security updates.

For more information on compiler requirements, see [GCC Requirement](GCCRequirement.md).

Release dates and package versions of each distribution can be found here:

* [Debian Releases](https://www.debian.org/releases/)
* [Debian Packages](https://www.debian.org/distrib/packages)
* [Ubuntu Releases](https://wiki.ubuntu.com/Releases)
* [Ubuntu Packages Search](https://packages.ubuntu.com/)

| Operating System                 | Release Date | WebKit Support End |
|----------------------------------|--------------|--------------------|
| Ubuntu 20.04 (Focal Fossa)       | 2020-04-23   | 2023-04-21         |
| Debian 11 (Bullseye)             | 2021-08-14   | 2024-06-10         |
| Ubuntu 22.04 (Jammy Jellyfish)   | 2022-04-21   | 2025-04-25         |
| Debian 12 (Bookworm)             | 2023-06-10   | 2026-08-09         |
| Ubuntu 24.04 (Noble Numbat)      | 2024-04-25   | 2027-04-23         |
| Debian 13 (Trixie)               | 2025-08-09   | TBD                |
| Ubuntu 26.04 (Resolute Raccoon)  | 2026-04-23   | TBD                |
