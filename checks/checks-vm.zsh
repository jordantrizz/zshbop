#!/usr/bin/env zsh
# -----------------------------------------------------------------------------------
# -- checks-vm -- Checks for VM
# -----------------------------------------------------------------------------------
_debug " -- Loading ${(%):-%N}"

# -- vm-checks
help_checks[vm-checks]='Run all checks for VM'
function vm-checks () {
    # Loop through help_checks and run each function
    for func in ${(k)help_checks}; do
        if [[ $string == "vm-check-"* ]]; then
            $func
        fi
    done
}

# ==============================================
# -- check if in virtual environment
# ==============================================
help_checks[vm-check-detect]='Am I in a VM?'
function vm-check-detect () {
    # Initialize VM variable
    local OUTPUT VIRT_WHAT="0" DETECT_METHOD="none" CHECK_CMD
    OUTPUT+="Checking if in virtual environment"

    [[ $MACHINE_OS == "mac" ]] && { _log "Running on Mac...no need to check"; return 0 }
    [[ $MACHINE_OS2 == "wsl" ]] && { _log "Running on WSL...no need to check"; return 0 }

    # -- check if virt-what exists
    _cmd_exists virt-what
    if [[ $? == "0" ]]; then
        OUTPUT+="virt-what installed - "
        # -- Check if running as root
        _checkroot >> /dev/null
        if [[ $? == "1" ]]; then
            OUTPUT+="not root can't run virt-what - "                        
        else
            DETECT_METHOD="virt-what"
        fi
    fi

    # -- Check if systemd-detect-virt exists
    _cmd_exists systemd-detect-virt
    if [[ $? == "0" ]]; then
        OUTPUT+="systemd-detect-virt installed - "
        DETECT_METHOD="systemd"
    fi

    # -- Run detect methods
    if [[ $DETECT_METHOD == "virt-what" ]]; then
        VMTYPE=$(virt-what)
        if [[ -n $VMTYPE ]]; then
            OUTPUT+="virt-what returned $VMTYPE - "
        else
            OUTPUT+="Not running in a VM, virtwhat returned $VMTYPE -"            
        fi
    elif [[ $DETECT_METHOD == "systemd" ]]; then
        VMTYPE=$(systemd-detect-virt)
        if [[ -n $VMTYPE ]]; then
            OUTPUT+="systemd-detect-virt returned $VMTYPE - "
        else
            OUTPUT+="Not running in a VM, systemd-detect-virt returned $VMTYPE -"            
        fi
    else
        OUTPUT+="Using fallback checks - "
        # Fallback checks
        if [[ -e /proc/user_beancounters ]] || grep -q -i -E "(vmware|kvm|xen)" /proc/cpuinfo; then
            CHECK_CMD=$(grep -o -i -E "(vmware|kvm|xen)" /proc/cpuinfo | head -1 | awk '{print $1}')
            OUTPUT+="Probably in a virtual environment (fallback check) since /proc/user_beancounters and /proc/cpuinfo = $CHECK_CMD"
            VMTYPE="$CMD"
        else
            OUTPUT+="Not in a virtual environment (fallback check)."
        fi
    fi    

    # -- If running KVM
     if [[ $VMTYPE == "kvm" ]]; then
        if [[ $(pgrep qemu) ]] || [[ $(pgrep qemu-system) ]]; then
            OUTPUT+="KVM qemu guest tools is running - "
        else
            OUTPUT+="KVM qemu not running install qemu-guest-agent - "
        fi
    fi
    export $VMTYPE
    _loading3 "$OUTPUT"
    
}


# ==============================================
# -- check if in virtual environment secondary method
# ==============================================
help_checks[vm-check-detect-2]='Am I in a VM2?'
function vm-check-detect-2 () {
    _debug "Checking if in virtual environment"
    if [[ -d /sys/devices/virtual ]] || [[ -f /proc/vz ]] || [[ -d /proc/xen ]]; then
        _alert "You are in a virtual machine."
    else
        _alert "You are not in a virtual machine."
    fi
}