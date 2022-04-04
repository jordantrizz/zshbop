# --
# dns commands
#
# Example help: help_dns[wp]='Generate phpinfo() file'
#
# --
_debug " -- Loading ${(%):-%N}"

# - Init help array
typeset -gA help_dns

# What help file is this?
help_files[dns]='DNS Commands'

# --
# -- commands that need to be installed
# --
help_dns[dt]='DNS tool that displays information about your domain. https://github.com/42wim/dt type '

# -- dnst
help_dns[dnst]='Run dnstracer on root name servers' 
dnst () {
	server=""
	root_servers=""
	: $RANDOM;
	if [ -x $1 ]; then echo "dnst <domain>";return; fi
	root_servers=(a b c d e f g h i j k l m )
	_debug "Root Servers - $root_servers"
	server=$(print -r -- ${root_servers[$(( $RANDOM % ${#root_servers[@]} + 1 ))]})	
	_debug "Selected server - $server.root-servers.net"
	dnstracer -o -s $server.root-servers.net -4 -r 1 $1
}

# -- mx
help_dns[mx]='Look up MX records.'
mx () {
	dig $1 mx
}


