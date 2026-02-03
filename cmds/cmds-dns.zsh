# =============================================================================
# dns commands
# =============================================================================
_debug " -- Loading ${(%):-%N}"
typeset -gA help_dns
help_files[dns]='DNS Commands'

# --
# -- commands that need to be installed
# --
help_dns[dt]='DNS tool that displays information about your domain. https://github.com/42wim/dt type '

# ===============================================
# -- dnst
# ===============================================
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

# ===============================================
# -- mx
# ===============================================
help_dns[mx]='Look up MX records.'
mx () {
	dig $1 mx
}

# ===============================================
# -- dig wrapper
# ===============================================
help_dns[digw]="Dig wrapper to turn urls into domains"
digw () {
	if [[ -z $@ ]]; then
		dig
	else
		_loading "digw - $URL"
		URL=$@
		DOMAIN=$(echo "$URL" | sed -e 's|^[^/]*//||' -e 's|/.*$||')
		_loading2 "Domain --> $DOMAIN"
		dig $DOMAIN
	fi
}

# ===============================================
# -- ptr
# ===============================================
help_dns[ptr]='Look up PTR records.'
ptr () {
	if [[ -z $1 ]]; then
		_error "ptr <ip>"
		return 1
	fi
	
	# -- check if the ip is valid
	if ! _validate_ip $1; then
		_error "Invalid IP"
		return 1
	fi

	_loading "Running - dig -x $1"
	dig -x $1
}
