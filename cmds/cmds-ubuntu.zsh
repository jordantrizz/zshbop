# --
# Ubuntu commands
#
# Example help: help_wordpress[wp]='Generate phpinfo() file'
#
# --
_debug " -- Loading ${(%):-%N}"

# What help file is this?
help_files[ubuntu]='Ubuntu OS related commands'

# - Init help array
typeset -gA help_ubuntu

# -- ubuntu-netselect
help_ubuntu[ubuntu-netselect]='Install netselect to find the fastest ubuntu mirror.'
ubuntu-netselect () {
	_cexists netselect
	if [[ $? == "0" ]]; then
		echo "netselect installed, type 'sudo netselect'"
	elif [[ $? == "1" ]]; then
		_checkroot
	        mkdir ~/tmp
	        wget http://ftp.us.debian.org/debian/pool/main/n/netselect/netselect_0.3.ds1-28+b1_amd64.deb -P ~/tmp
	        sudo dpkg -i ~/tmp/netselect_0.3.ds1-28+b1_amd64.deb
	fi
}
alias netselect='sudo netselect -v -s10 -t20 `wget -q -O- https://launchpad.net/ubuntu/+archivemirrors | grep -P -B8 "statusUP|statusSIX" | grep -o -P "(f|ht)tp://[^\"]*"`'