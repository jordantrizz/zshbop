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
if [[ $? -ge "0" ]]; then
    _debug "exa success, using exa for ls alias"
    alias ls="exa -al"
else
	_debug "exa failed, using default ls alias"
    alias ls="${DEFAULT_LS}"
fi


# - auto-ls
# Be sure to call it auto-ls-<name of your function>
export AUTO_LS_COMMANDS=('color' git-status)
auto-ls-color () { \ls -aG;echo "\n"; }

# -- check_diskspace
check_diskspace_mac () {
	check_diskspace_linux
}

# -- interfaces
function interfaces_mac () {
    local OUTPUT
    # Get a list of all network interfaces
    interfaces=($(networksetup -listallhardwareports | awk '/Device:/{print $2}'))

    # Loop through each interface
    for interface in $interfaces; do
        # Get IP address
        interface=${interface//:/}
        ip=$(ifconfig $interface | grep 'inet ' | awk '{print $2}')

        # Get MAC address
        mac=$(ifconfig $interface | awk '/ether/{print $2}')

        # Get link speed
        speed=$(ifconfig $interface | awk '/media: /{print $2}')
        networksetup -getairportnetwork "$interface" >>/dev/null
        if [[ $? == "0" ]]; then
            # Wi-Fi interface
            INT_TYPE="wifi"
            connection_speed=$(/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport -I | awk '/maxRate:/ {print $2}')
        else
            # Hardwired interface
            INT_TYPE="ethernet"
            connection_speed=$(ifconfig "$interface" | awk '/media: / {print $2}')
        fi


        # Print interface information
        if [[ ! $ip == "" ]]; then
            OUTPUT+="$interface:$ip"
            if [[ ! $mac == "" ]]; then
                OUTPUT+=" - $mac"
            fi
            if [[ ! $speed == "" ]]; then
                OUTPUT+=" - $INT_TYPE/$speed/$connection_speed"
            fi
        fi
    done 
    echo "$OUTPUT"
    #echo -e "$OUTPUT" | column -t
}

# -- Show macos memory pressure
function show_swap_mac() {
    physical_memory=$(sysctl hw.memsize | awk '{print $2/1024/1024}')
    used_memory=$(echo "scale=2; ${physical_memory} - $(memory_pressure | grep "Pages free" | awk '{print $3/1024}') - $(memory_pressure | grep "Pages active" | awk '{print $3/1024}') - $(memory_pressure | grep "Pages inactive" | awk '{print $3/1024}') - $(memory_pressure | grep "Pages speculative" | awk '{print $3/1024}') - $(memory_pressure | grep "Pages wired down" | awk '{print $4/1024}')" | bc)
    cached_files=$(vm_stat | awk '/^Pages free:/ {free=$3} /^Pages speculative:/ {spec=$3} /^Pages inactive:/ {inactive=$3} /^Pages wired down:/ {wired=$4} END {printf "%.1f MB\n", (free+spec+inactive+wired)*4096/1048576}')
    swap_used=$(sysctl vm.swapusage | awk '/vm.swapusage:/ {print $7}')
    echo -n "Mem: ${physical_memory} | Used: ${used_memory} | Cached: ${cached_files} | Swap: ${swap_used}"
    _notice "You can also run sysctl vm.swapusage or memory_pressure"
}

# -- check mac diskspace
check_diskspace_mac () {
    # TODO create this function
    local usage=$(df -h / | awk 'NR==2{print $5}' | sed 's/%//')
    local used=$(df -h / | awk 'NR==2{print $3}')
    local free=$(df -h / | awk 'NR==2{print $4}')

    echo "Disk usage: $used used, $free free"

    if [ "$usage" -gt 90 ]; then
    echo "Warning: Disk usage is above 90%!"
    fi
}
