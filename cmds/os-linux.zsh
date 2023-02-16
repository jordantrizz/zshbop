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

# -- check_diskspace_linux
check_diskspace_linux () {
    ALERT="98" # alert level
    # :\\ = wsl drive letters
    # /run = not requires
    # wsl = wsl stuffs
    # /init = wsl stuffs
    DF_COMMAND=$(df -H 2>/dev/null | grep -vE '^Filesystem|tmpfs|cdrom|:\\|wsl|/run|/init|overlay|none|/dev/loop*|devfs' | awk '{ print $5 " " $1 }' )
    #IFS=$'\n' read -rd '' DISKUSAGE <<< "$DF_COMMAND"
    DISKUSAGE=("${(@f)${DF_COMMAND}}")
    for OUT in ${DISKUSAGE[@]}; do
        PERCENTAGE=$(echo "$OUT" | awk '{ print $1}' | cut -d'%' -f1 )
        PARTITION=$(echo "$OUT" | awk '{ print $2 }' )
        FIRSTMSG="Checking $PARTITION with $PERCENTAGE%"

        # - Check percentage and then alert.
        if [[ $PERCENTAGE -ge $ALERT ]]; then
            _notice "$FIRSTMSG.."
            _error "Space issue on ${PARTITION} (${PERCENTAGE}%)"
        else
            _notice "$FIRSTMSG.. - no issue."
        fi
    done
}

# -- system_check - check usualy system stuff
system_check () {
    # -- start
    _debug_function
    _banner_yellow "System check on $MACHINE_OS"

    # -- network interfaces
    _loading "Network interfaces"
    interfaces

    # -- check swappiness
    _loading2 "Checking swappiness"
    if [[ -f /proc/sys/vm/swappiness ]]; then
        _notice "/proc/sys/vm/swappiness: $(cat /proc/sys/vm/swappiness)"
    else
        _error "Can't find swap"
    fi

    # -- check disk space
    _loading2 "Checking disk space"
    check_diskspace

    # -- check block devices
    _loading2 "Checking block devices"
    check_blockdevices
}