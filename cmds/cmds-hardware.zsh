# --
# hardware
# --
_debug " -- Loading ${(%):-%N}"
help_files[hardware]="Hardware specific commands" # Help file description
typeset -gA help_hardware # Init help array.

# -- bios-info
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
