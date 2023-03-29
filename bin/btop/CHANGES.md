## Changelog v1.2.13

* Makefile: VERBOSE=true flag for Makefile to display all compiler commands and fixed so already set CXXFLAGS and LDFLAGS are displayed.
* Makefile: Added autodetection for gcc12 to make compiling on macos Ventura easier.
* Changed: Reverted back to sysconf(_SC_NPROCESSORS_ONLN) for Cpu core count ant let the new dynamic update fix if cores are turned on later
* Fixed: Ignore disks that fails in statvfs64() to avoid slowdowns and possible crashes.
* Fixed: Moved up get_cpuHz() in the execution order to get better cpu clock reading.
* Added: proc tree view: if there's more than 40 width left, try to print full cmd, by @Superty
* Fixed: Show the first IP of the interface in NET box instead of the last, by @correabuscar
* Changed: Replace getnameinfo with inet_ntop [on Linux], by @correabuscar
* Fixed: Not picking up last username from /etc/passwd
* Fixed: Process nice value underflowing, issue #461
* Changed: Replace getnameinfo with inet_ntop [on FreeBSD], by @correabuscar
* Changed: Replace getnameinfo with inet_ntop [on macos], by @correabuscar

**For additional binaries see the [Continuous Builds](https://github.com/aristocratos/btop/actions).**

**Linux binaries for each architecture are statically linked with musl and works on kernel 2.6.39 and newer.**

**Macos binaries are statically linked with libgcc and libstdc++ but only guaranteed to work on the OSX version mentioned in the name.**

**Notice! Use x86_64 for 64-bit x86 systems, i486 and i686 are 32-bit!**
