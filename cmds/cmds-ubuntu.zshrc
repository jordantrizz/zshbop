# --
# Ubuntu commands
#
# Example help: help_wordpress[wp]='Generate phpinfo() file'
#
# --
_debug " -- Loading ${(%):-%N}"

# - Init help array
typeset -gA help_ubuntu

# -- ubuntu-netselect
help_ubuntu[ubuntu-netselect]='Install netselect to find the fastest ubuntu mirror.'
ubuntu-netselect () {
        mkdir ~/tmp
        wget http://ftp.us.debian.org/debian/pool/main/n/netselect/netselect_0.3.ds1-28+b1_amd64.deb -P ~/tmp
        sudo dpkg -i ~/tmpnetselect_0.3.ds1-28+b1_amd64.deb
}