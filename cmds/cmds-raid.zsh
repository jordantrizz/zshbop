# --
# Raid helper commands
# --
_debug " -- Loading ${(%):-%N}"
help_files[raid]='Raid commands'
typeset -gA help_raid

# -- software-raid-check
help_raid[software-raid-check]='Check the status of software RAID devices'
function software-raid-check () {
    local OUTPUT=""
    DEBUG_MODE=false

    # Parse command line arguments
    while getopts ":d" opt; do
    case $opt in
        d)
        DEBUG_MODE=true
        ;;
        \?)
        echo "Invalid option: -$OPTARG" >&2
        exit 1
        ;;
    esac
    done

    # Check if mdadm is installed
    if ! command -v mdadm > /dev/null; then
        _error "mdadm is not installed."
        return 1
    fi

    # Get a list of RAID devices
    raids=($(cat /proc/mdstat | grep '^md' | awk '{print $1}'))

    # If there are no RAIDs, report back
    if [[ ${#raids} -eq 0 ]]; then
        _warning "No software RAID devices found."
        return 0
    fi

    # Iterate over each RAID and check its status
    all_good=true
    for raid in $raids; do
        raid_status_line=$(mdadm --detail /dev/$raid | grep 'State :' | awk '{ for(i=3; i<=NF; i++) printf $i " " }')
        raid_states=(${(s/,/)raid_status_line})

        if $DEBUG_MODE; then
            mdadm --detail /dev/$raid
        fi

        OUTPUT+="$raid = "

        for state in $raid_states; do
            if [[ $state == *degraded* ]]; then
                all_good=false
                OUTPUT+="$state"
                break
            else
                OUTPUT+="$state"
            fi
        done
        OUTPUT+=" | "
    done    

    if $all_good; then
        _success "All RAID devices are good - $OUTPUT"
    else
        echo ""
        _error "One or more RAID devices reported bad status - $OUTPUT"
    fi
}
