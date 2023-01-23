# Mac PATH
# - Mac Ports in /opt/local/bin
export PATH=$PATH:/opt/local/bin:/opt/local/sbin/
export PATH=$PATH:/usr/local/sbin
# - Visual Studio Code
export PATH="$PATH:/Applications/Visual Studio Code.app/Contents/Resources/app/bin"

# -- auto-ls zsh plugin - needs to be defined in order
DEFAULT_LS="ls -Gal"
alias ls="$DEFAULT_LS"

# -- Variables

# -- aliases
alias ps="/bin/ps aux"
alias flush-dns="sudo dscacheutil -flushcache && sudo killall -HUP mDNSResponder"
alias eject-all="osascript -e 'tell application "Finder" to eject (every disk whose ejectable is true)'"

# -- ls/exa
_cexists exa
if [[ $? -ge "1" ]]; then
	_debug "exa failed, using default ls alias"
    alias ls="${DEFAULT_LS}"
else
    _debug "exa success, using exa for ls alias"
    alias ls="exa -al"
fi

# -- autols
auto-ls-ls () {
	\ls -a
	echo ""
}

# -- check_diskspace
check_diskspace_mac () {
	check_diskspace_linux
}

# -- interfaces
interfaces_mac () {
    # Get a list of all network interfaces
    interfaces=($(ifconfig | awk '/: flags/{print $1}' | grep -v 'utun0'))

    # Loop through each interface
    #OUTPUT=$(_banner_grey "Interface IP Mac Speed")
    OUTPUT="Interface IP Mac Speed"
    for interface in $interfaces; do
        # Get IP address
        interface=${interface//:/}
        ip=$(ifconfig $interface | grep 'inet ' | awk '{print $2}')

        # Get MAC address
        mac=$(ifconfig $interface | awk '/ether/{print $2}')

        # Get link speed
        speed=$(ifconfig $interface | awk '/media: /{print $2}')

        # Print interface information
        if [[ ! $ip == "" ]]; then
            OUTPUT+="\n$interface $ip $mac $speed"
            OUTPUT=${OUTPUT%[$'  ']} # Remove trailing whitespace 

        fi
    done 
    #echo -E "$OUTPUT"
    echo -e "$OUTPUT" | column -t
}