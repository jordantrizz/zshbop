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
    _debug "Checking if in virtual environment"

    [[ $MACHINE_OS == "mac" ]] && { _success "VM: Running on Mac...no need to check"; return 0 }

    # Initialize VM variable
    local VM_TYPE="" OUTPUT VIRT_WHAT="0"

    # -- check if virt-what exists
    _cexists virt-what
    if [[ $? == "0" ]]; then
        OUTPUT+="virt-what installed - "
        # -- Check if running as root
        _checkroot >> /dev/null
        if [[ $? == "1" ]]; then
            OUTPUT+="not root can't run virt-what - "
            VIRT_WHAT="0"
        else
            VM_TYPE=$(virt-what)
            if [[ -n $VM ]]; then
                OUTPUT+="virt-what returned $VM_TYPE - "
                if [[ $VM_TYPE == "kvm" ]]; then
                    if [[ $(pgrep qemu) ]] || [[ $(pgrep qemu-system) ]]; then
                        OUTPUT+="KVM qemu guest tools is running - "
                    else
                        OUTPUT+="KVM qemu not running install qemu-guest-agent - "
                    fi
                else
                    OUTPUT+=" - $VM_TYPE"
                fi
            else
                OUTPUT+="Not running in a VM"
                _debug "virt-what returned $VM_TYPE"
            fi            
        fi
    fi
    
    # -- Fall back to virt-what
    if [[ $VIRT_WHAT == "0" ]]; then    
        # Fallback checks
        if [[ -e /proc/user_beancounters ]] || grep -q -i -E "(vmware|kvm|xen)" /proc/cpuinfo; then
            VM=$(grep -o -i -E "(vmware|kvm|xen)" /proc/cpuinfo | head -1 | awk '{print $1}')
            echo "Probably in a virtual environment (fallback check) since /proc/user_beancounters and /proc/cpuinfo = $VM"
        elif [[ $OS2 == "wsl" ]]; then
            echo "In WSL, which is a virtual environment (fallback check)."
            VM_TYPE="wsl"
        else
            echo "Not in a virtual environment (fallback check)."
        fi
    fi
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