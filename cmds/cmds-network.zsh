# --
# template commands
#
# Example help: help_template[test]='Generate phpinfo() file'
#
# --
_debug " -- Loading ${(%):-%N}"

# What help file is this?
help_files[network]='Network tools and built-in scripts.'

# - Init help array
typeset -gA help_network

_debug " -- Loading ${(%):-%N}"

# -- paths
help_network[interfaces]='Print out network interfaces'
interfaces () {
	if [[ $MACHINE_OS == "mac" ]]; then
		interfaces_mac
	else
		interfaces_linux
	fi
}

# -- listen
help_network[listen]="Show all tcp/tcp6 ports listening"
listen () {
	netstat -anp | grep 'LISTEN' | egrep 'tcp|tcp6'
}

# -- whatismyip
help_network[whatismyip]="Get current machines internet facing IP Addres"
whatismyip () {
	dig @resolver1.opendns.com A myip.opendns.com +short -4
	dig @resolver1.opendns.com AAAA myip.opendns.com +short -6
}