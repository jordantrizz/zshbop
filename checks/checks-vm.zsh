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
function vm-check () {
    _debug "Checking if in virtual environment"

    [[ $MACHINE_OS == "mac" ]] && { _success "VM: Running on Mac...no need to check"; return 0 }

    # -- check if virt-what exists
    _cexists virt-what
    if [[ $? == "0" ]]; then
        _debug "virt-what installed"
        # -- Check if running as root
        _checkroot
        if [[ $? == "1" ]] { return 0; }
        VM=$(virt-what)
        if [[ -n $VM ]]; then
            _debug "virt-what returned $VM"
            if [[ $VM == "kvm" ]]; then
                if [[ $(pgrep qemu) ]] || [[ $(pgrep qemu-system) ]]; then
                    echo "$(_loading3 VM-virt-what:) Running on KVM, and qemu guest tools is running"
                else
                    _warning "VM-virt-what: Running on KVM, but qemu is not running, install qemu-guest-agent"
                fi
            else
                _alert "VM-virt-what: Running on $VM" 0
            fi
        else
            _loading3 "Not running in a VM"
            _debug "virt-what returned $VM"
        fi
    else
        _warning "Unable to determine if in virtual environment, please install virt-what"
        
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