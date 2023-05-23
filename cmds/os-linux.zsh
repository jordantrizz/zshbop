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
    local OUTPUT=""
    local INTERFACES=()
    local INTERFACES_OUTPUT=""

    # -- Check if ifconfig commmand exists
    _cexists ifconfig
    if [[ $? -ge "1" ]]; then
        _error "ifconfig command not found, required, run zshbop install-env"
        return 1
    fi

    # -- Get a list of all network interfaces
    INTERFACES=("${(f)$(ip -o link show | awk '{print $2}' | sed 's/://')}")

    # -- Loop through each interface
    for INTERFACE in $INTERFACES; do

        # -- Get MAC address
        INTERFACE_MAC=$(ifconfig $INTERFACE | awk '/ether/{print $2}')

        # -- Get link speed
        INTERFACE_SPEED=$(ethtool $INTERFACE 2> /dev/null | awk '/Speed:/ {print $2}')
        [[ -z $INTERFACE_SPEED ]] && INTERFACE_SPEED="N/A"

        # Get IP address
        INTERFACE_IP=$(ifconfig $INTERFACE | awk '/inet /{print $2}')

        # -- Print interface information
        _debug "$INTERFACE:$INTERFACE_IP - $INTERFACE_MAC $INTERFACE_SPEED"
        INTERFACES_OUTPUT+="$INTERFACE:$INTERFACE_IP - $INTERFACE_MAC $INTERFACE_SPEED || "
    done
    
    echo "$INTERFACES_OUTPUT"
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