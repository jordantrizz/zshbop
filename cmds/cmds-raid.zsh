# --
# Raid helper commands
# --
_debug " -- Loading ${(%):-%N}"
help_files[raid]='Raid commands'
typeset -gA help_raid

# -- software-raid-check
help_raid[software-raid-check]='Check the status of software RAID devices'
function software-raid-check () {
    local -a opts_help opts_debug opts_motd raids log_files
    local output debug_mode motd_mode all_good raid raid_status_line log_output log_file
    debug_mode=false
    motd_mode=false
    all_good=true
    output=""

    zparseopts -D -E -- h=opts_help -help=opts_help d=opts_debug -debug=opts_debug -motd=opts_motd

    if [[ -n $opts_help ]]; then
        echo "Usage: software-raid-check [-h|--help] [-d|--debug] [--motd]"
        echo "  --motd  Run status-only output suitable for MOTD"
        return 0
    fi

    if [[ -n $opts_debug ]]; then
        debug_mode=true
    fi

    if [[ -n $opts_motd ]]; then
        motd_mode=true
    fi

    # Check if mdadm is installed
    if ! command -v mdadm > /dev/null; then
        _error "mdadm is not installed."
        return 1
    fi

    # Get a list of RAID devices
    raids=($(awk '/^md/ {print $1}' /proc/mdstat 2>/dev/null))

    # If there are no RAIDs, report back
    if [[ ${#raids} -eq 0 ]]; then
        _warning "No software RAID devices found."
        return 0
    fi

    # Iterate over each RAID and check its status
    for raid in $raids; do
        raid_status_line=$(mdadm --detail /dev/$raid 2>/dev/null | awk -F ' : ' '/State :/ {print $2}')

        if [[ -z "$raid_status_line" ]]; then
            raid_status_line="unknown"
            all_good=false
        fi

        if $debug_mode; then
            mdadm --detail /dev/$raid
        fi

        if [[ "${raid_status_line:l}" == *degraded* || "${raid_status_line:l}" == *recover* || "${raid_status_line:l}" == *fault* || "${raid_status_line:l}" == *inactive* ]]; then
            all_good=false
        fi

        output+="$raid = $raid_status_line | "
    done

    if $all_good; then
        _success "All RAID devices are good - $output"
    else
        echo ""
        _error "One or more RAID devices reported bad status - $output"
    fi

    if $motd_mode; then
        return 0
    fi

    echo ""
    _loading "Software RAID log review (last 48 hours)"

    if (( $+commands[journalctl] )); then
        log_output=$(journalctl --since "48 hours ago" --no-pager 2>/dev/null | grep -Ei 'mdadm|md[0-9]+|raid|resync|reshape|degraded|recovery' | tail -n 200)
        if [[ -n "$log_output" ]]; then
            _loading3 "journalctl events"
            echo "$log_output"
        else
            _success "No RAID-related journalctl events in the last 48 hours."
        fi
    else
        _warning "journalctl not found; using fallback log sources."
    fi

    if (( $+commands[dmesg] )); then
        log_output=$(dmesg --ctime 2>/dev/null | grep -Ei 'mdadm|md[0-9]+|raid|resync|reshape|degraded|recovery' | tail -n 120)
        if [[ -n "$log_output" ]]; then
            _loading3 "dmesg RAID events"
            echo "$log_output"
        fi
    fi

    log_files=(/var/log/syslog /var/log/messages /var/log/kern.log)
    for log_file in $log_files; do
        if [[ -r "$log_file" ]]; then
            log_output=$(grep -Ei 'mdadm|md[0-9]+|raid|resync|reshape|degraded|recovery' "$log_file" 2>/dev/null | tail -n 80)
            if [[ -n "$log_output" ]]; then
                _loading3 "$log_file RAID events"
                echo "$log_output"
            fi
        fi
    done
}
