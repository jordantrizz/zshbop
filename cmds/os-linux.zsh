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
		_warning "exa failed, using default ls alias"
	else
		_debug "Using exa"
		alias ls="${EXA_LINUX}"
		alias exa="${EXA_LINUX}"
	fi		
fi

# -- ps
alias ps="ps -auxwwf"

# -- tran - https://github.com/abdfnx/tran/releases
alias tran="tran_linux_amd64"

# -- interfaces
help_linux[interfaces]="List interfaces ip, mac and link"
interfaces_linux () {
	# Get a list of all network interfaces
	interfaces=($(ip -o link show | awk '{print $2}' | tr -d ':'))

	# Loop through each interface
	OUTPUT=$(_banner_grey "Interface IP Mac Speed")
	for interface in $interfaces; do
        _debug "Processing interface: $interface"
        if [[ $interface == *NONE* ]] && { interface=$(echo $interface | sed 's/@NONE//g'); _debug "Found @NONE in \$interface, removing @NONE"; }        
                
	    # Get MAC address
	    mac=$(ip -o link show $interface | awk '{print $17}')

	    # Get link speed
	    speed=$(ethtool $interface 2>>/dev/null | grep 'Speed: ' | awk '{print $2}')
        [[ -z $speed ]] && speed="N/A"

	    # Get IP address
        ip=$(ip -o addr show $interface | awk '{print $3","$4}')
        if [[ "${ip%%\n*}" != "${ip}" ]]; then
            _debug " -- Found multiple IP addresses for $interface"
            while read -r ip; do
                _debug "Interface: $interface IP: $ip MAC: $mac Speed: $speed"
                OUTPUT+="\n$interface $ip $mac $speed"
            done <<< "${ip}"
        elif [[ -z $ip ]]; then
            _debug " -- No IP address found for $interface"
            OUTPUT+="\n$interface N/A $mac $speed"
        else
            # Print interface information
            _debug "Interface: $interface IP: $ip MAC: $mac Speed: $speed"
	        OUTPUT+="\n$interface $ip $mac $speed"
        fi
	done
	echo -e "$OUTPUT" | column -t
}

# -- check_diskspace_linux
check_diskspace_linux () {
    ALERT="98" # alert level
    # :\\ = wsl drive letters
    # /run = not requires
    # wsl = wsl stuffs
    # /init = wsl stuffs
    local DISKSPACE_ERROR=0
    DF_COMMAND=$(df -H 2>/dev/null | grep -vE '^Filesystem|tmpfs|cdrom|:\\|wsl|/run|/init|overlay|none|/dev/loop*|devfs' | awk '{ print $5 " " $1 }' )
    DISKUSAGE=("${(@f)${DF_COMMAND}}")
    for OUT in ${DISKUSAGE[@]}; do
        PERCENTAGE=$(echo "$OUT" | awk '{ print $1}' | cut -d'%' -f1 )
        PARTITION=$(echo "$OUT" | awk '{ print $2 }' )
        FIRSTMSG="Checking $PARTITION with $PERCENTAGE%"

        # - Check percentage and then alert.
        if [[ $PERCENTAGE -ge $ALERT ]]; then
            _notice "$FIRSTMSG.."
            _error "Space issue on ${PARTITION} (${PERCENTAGE}%)"
            DISKSPACE_ERROR=1
        else
            _log "$FIRSTMSG.. - no issue."            
        fi
    done
    [[ $DISKSPACE_ERROR == 1 ]] && _error "Disk space issue found, please check." || _success "No disk space issue found."
}

# -- auto-ls
export AUTO_LS_COMMANDS=('color' git-status)
auto-ls-color () { ls -a --color=auto;echo "\n"; }