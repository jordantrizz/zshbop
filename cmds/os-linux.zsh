# =============================================================================
# -- Linux specific commands
# =============================================================================

# -- ls/exa
unset LC_CHECK NULL
EXA_LINUX="exa-linux_x86_64"
_cmd_exists ${EXA_LINUX}
if [[ $? == "0" ]]; then
    NULL=$(exa-linux_x86_64 2>&1 >> /dev/null)
	LC_CHECK="$?"
    _debug "exa run - out: $NULL \$?:$LC_CHECK"
	if [[ $LC_CHECK -ge "1" ]]; then
		_warning "exa failed, using default ls alias"
	else
		_debug "Using exa"
		alias ls="${EXA_LINUX} -agl"
		alias exa="${EXA_LINUX} -agl"
	fi
fi

# ===============================================
# -- linux aliases
# ===============================================
alias ps="ps -auxwwf"
# -- tran - https://github.com/abdfnx/tran/releases
alias tran="tran_linux_amd64"

# ===============================================
# -- _interfaces_linux
# ===============================================
help_linux[interfaces]="List interfaces ip, mac and link"
function _interfaces_linux () {
    local OUTPUT=""
    local INTERFACES=()
    local INTERFACES_OUTPUT=""

    # -- Check if ifconfig commmand exists
    _cmd_exists ifconfig
    if [[ $? -ge "1" ]]; then
        _error "ifconfig command not found, required, run zshbop install-env"
        return 1
    fi

    # -- Get a list of all network interfaces
    _debug "Getting list of interfaces using ip -o link show and \$EXCLUDE_INTERFACES: $EXCLUDE_INTERFACES"
    EXCLUDE_INTERFACES="^lo|^veth|^br-|^fwpr|^fwln|^fwbr|^tap|^sit" # -- Exclude loopback, veth and br interfaces
    INTERFACES=("${(f)$(ip -o link show | awk '{print $2}' | sed 's/://' | grep -vE "${EXCLUDE_INTERFACES}")}")
    OUTBOUND_INTERFACE=$(ip -o route get to 8.8.8.8 | awk {' print $5 '})

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
        if [[ $INTERFACE == $OUTBOUND_INTERFACE ]]; then
            PRIMARY_INTERFACES_OUTPUT="\e[1;32m$INTERFACE:$INTERFACE_IP - $INTERFACE_MAC $INTERFACE_SPEED\e[0m"
        else
            INTERFACES_OUTPUT+="\t$INTERFACE:$INTERFACE_IP - $INTERFACE_MAC $INTERFACE_SPEED \n"
        fi
    done
    echo "$PRIMARY_INTERFACES_OUTPUT"
    echo "$INTERFACES_OUTPUT"
}

# -- check_diskspace_linux
help_linux[linux-checkdiskspace]="Check disk space"
function linux-checkdiskspace () {
    ALERT="98" # alert level
    # :\\ = wsl drive letters
    # /run = not requires
    # wsl = wsl stuffs
    # /init = wsl stuffs
    local DISKSPACE_ERROR=0
    DF_COMMAND=$(df -H 2>/dev/null | grep -vE '^Filesystem|tmpfs|cdrom|:\\|wsl|/run|/init|overlay|none|/dev/loop*|devfs|snapfuse' | awk '{ print $5 " " $1 }' )
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
