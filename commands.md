# jordantrizz/ZSH - Commands

<a href="https://www.buymeacoffee.com/jordantrask" target="_blank"><img src="https://cdn.buymeacoffee.com/buttons/default-orange.png" alt="Buy Me A Coffee" style="height: 51px !important;width: 217px !important;" ></a>

<!--ts-->
   * [jordantrizz/ZSH - Commands](#jordantrizzzsh---commands)
   * [Core](#core)
   * [General](#general)
   * [Coding](#coding)
   * [Web](#web)
   * [Ubuntu/Debian Specific](#ubuntudebian-specific)
   * [Exim](#exim)
   * [WSL](#wsl)

<!-- Added by: jtrask, at: Fri Dec 18 08:46:17 EST 2020 -->

<!--te-->

Type `commands` or `aliases` to get a list of commands and aliases. Doesn't work yet.
# Core
Alias | Description|
 --- | --- |
update | Update this repository an pull down any updates from sub-modules.
setup_environment | Installed the necessary packages.
pk | Print out all public keys in ".ssh" folder

# General 
Alias | Description|
 --- | --- |
fdcount | Count of files and directories in current directory.
update | Update this repository an pull down any updates from sub-modules.
setup_environment | Installed the necessary packages.
whatismyip | Checks opendns and tells you what your external IP address is.
listen | What's listening on what port.
vh | Using curl to test virtual hosts before migration

# Coding
Command | Description|
 --- | --- |
toc | Runs patched gh-md-toc with --nobackup-insert on current directories README.md

# Web
Command | Description|
 --- | --- |
ttfb | Time To First Byte, uses curl. |
error_log | Recursively look for error_log files and tail. |
rm_error_log | Recursively look for error_log and prompt to delete. |
phpinfo | Generate a phpinfo.php file with phpinfo(); |
dhparam | Generate Diffie-Hellman key exchange. |
msds | MySQL Dump Search

# Ubuntu/Debian Specific
Command | Description|
 --- | --- |
apt-select | Get fastest Ubuntu/Debian mirror.
setup-cloud | Updates hostname, address cloud.cfg hostname peserve and fixes resolv.conf bug. Made in bash.

# Exim
Command | Description |
 --- | --- |
eximcq | Clears Exim queue of messages.

# WSL
Command | Description |
 --- | --- |
wsl-screen | Fixes screen error "Cannot make directory '/var/run/screen': Permission denied" when rebooting your system
