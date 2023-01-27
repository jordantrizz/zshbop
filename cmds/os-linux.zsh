# Aliases

# -- ls/exa
unset LC_CHECK NULL
EXA_LINUX="exa-linux_x86_64"
_cexists ${EXA_LINUX}
if [[ $? == "0" ]]; then
    NULL=$(exa-linux_x86_64 2>&1 >> /dev/null)
	LC_CHECK="$?"
    _debug "exa run - out: $NULL \$?:$LC_CHECK"
	if [[ $LC_CHECK -ge "1" ]]; then
		_loading "exa failed, using default ls alias"
	else
		_loading2 "Using exa"
		alias ls="${EXA_LINUX} ${DEFAULT_EXA}"
		alias exa="${EXA_LINUX}"
	fi		
fi

# -- ps
alias ps="ps -auxwwf"

# -- tran - https://github.com/abdfnx/tran/releases
alias tran="tran_linux_amd64"

# -- macchina
alias macchine="macchina-linux-x86_64"
alias os="macchine"

# -- interfaces
help_linux[interfaces]="List interfaces ip, mac and link"
interfaces_linux () {
	# Get a list of all network interfaces
	interfaces=($(ip -o link show | awk '{print $2}' | tr -d ':'))

	# Loop through each interface
	OUTPUT=$(_banner_grey "Interface IP Mac Speed")
	for interface in $interfaces; do
	    # Get IP address
	    ip=$(ip -o addr show $interface | awk '{print $4}')
	
	    # Get MAC address
	    mac=$(ip -o link show $interface | awk '{print $6}')

	    # Get link speed
	    speed=$(ethtool $interface 2>>/dev/null | grep 'Speed: ' | awk '{print $2}')

	    # Print interface information
	    OUTPUT+="\n$interface $ip $mac $speed"
	done
	echo -e "$OUTPUT" | column -t
}
