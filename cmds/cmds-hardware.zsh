# --
# hardware
# --
_debug " -- Loading ${(%):-%N}"
help_files[hardware]="Hardware specific commands" # Help file description
typeset -gA help_hardware # Init help array.

# =============================================================================
# -- bios-info
# ===============================================
help_hardware[bios-info]="Get BIOS information"
function bios-info() {
    _loading "Trying to get BIOS information using dmidecode"
    if [[ -f /usr/sbin/dmidecode ]]; then
        _loading2 "Getting BIOS information"
        sudo dmidecode -t bios
    else
        _error "dmidecode not found"
        return 1
    fi

    _loading "Trying to get BIOS information using smbios-sys-info"
    if [[ -f /usr/sbin/smbios-sys-info ]]; then
        _loading2 "Getting BIOS information"
        sudo smbios-sys-info
    else
        _error "smbios-sys-info not found"
        _require_package libsmbios-bin
        return 1
    fi
}

# ===============================================
# -- hw-list-disks
# ===============================================
help_hardware[hw-list-disks]="List all disks"
function hw-list-disks() {
    _hw-list-disk-usage () {
        echo "Usage: hw-list-disks [-h] [-t hdparm|lsblk|smartctl]"
        echo " -h, --help      Show this help"
        echo " -t, --type      Specify the command to use to list disks"
        echo ""                     hdparm: Use hdparm to list disks
        echo ""                     lsblk: Use lsblk to list disks
        echo ""                     smartctl: Use smartctl to list disks
        echo ""
        echo "If no argument is provided, one of the above will be used"
    }
    
    _hw-list-disk-detect () {     
        if _cmd_exists smartctl; then
            _debugf "Using smartctl"
            MODE="smartctl"   
        elif _cmd_exists hdparm; then
            _debugf "Using hdparm"
            MODE="hdparm"
        elif _cmd_exists lsblk; then
            _debugf "Using lsblk"
            MODE="lsblk"
        else
            _error "No suitable command found to list disks"
            return 1
        fi
    }

    zparseopts -D -E h:=ARG_HELP hdparm:=ARG_HDPARM t:=ARG_TOOL
    _debugf "ARG_TOOL: $ARG_TOOL"

    if [[ -n $opts[help] ]]; then
        _hw-list-disk-usage
        return 0
    fi

    # If no option is provided, try to detect
    if [[ -z $ARG_TOOL ]]; then
        _debugf "No option provided, trying to detect"
        _hw-list-disk-detect
    else
        MODE=${ARG_TOOL[2]}
    fi

    # Get a list of all disk drive hardware
    DEVICES=($(lsblk -n -d -o NAME | grep -v "^loop" | grep -v "^sr" | grep -v "^ram" | grep -v "^zram" | grep -v "^zd"))
    _debugf "DEVICES: $DEVICES"

    if [[ $MODE == "hdparm" ]]; then
        _loading "Listing all disks (hdparm)"
        # Grab device names, model number and serial
        for disk in ${DEVICES[@]}; do
            if [[ -b /dev/$disk ]]; then
                _debugf "Device: $disk"
                HDPARM_OUTPUT=$(sudo hdparm -I /dev/$disk)
                echo "Device: /dev/$disk"
                echo $HDPARM_OUTPUT | grep -E "Model" 
                echo $HDPARM_OUTPUT | grep -E "Serial"
                echo $HDPARM_OUTPUT | grep -E "Firmware"
                echo $HDPARM_OUTPUT | grep -E "Transport:"
            else
                _debugf "Device: $disk is not a block device"
            fi
        done
    elif [[ $MODE == "lsblk" ]]; then
        _loading "Listing all disks (lsblk)"
        lsblk -o NAME,SIZE,TYPE,MODEL,SERIAL
    elif [[ $MODE == "smartctl" ]]; then
        _loading "Listing all disks (smartctl)"
        for disk in ${DEVICES[@]}; do
            if [[ -b /dev/$disk ]]; then
                echo "Device: /dev/$disk"
                SMARTCTL_OUTPUT=$(sudo smartctl -i /dev/$disk)
                # Print 4 spaces infront of each line
                echo $SMARTCTL_OUTPUT | grep -E "Model" | sed 's/^/    /'
                echo $SMARTCTL_OUTPUT | grep -E "Serial" | sed 's/^/    /'
                echo $SMARTCTL_OUTPUT | grep -E "Firmware" | sed 's/^/    /'
                echo $SMARTCTL_OUTPUT | grep -E "User Capacity:" | sed 's/^/    /'
                echo $SMARTCTL_OUTPUT | grep -E "Rotation Rate:" | sed 's/^/    /'
                echo $SMARTCTL_OUTPUT | grep -E "TRIM Command:" | sed 's/^/    /'
                echo $SMARTCTL_OUTPUT | grep -E "Size/Capacity:" | sed 's/^/    /'
            else
                _debugf "Device: $disk is not a block device"
            fi
        done
    fi
}
