# --
# Core commands
#
# Example help: help_wordpress[wp]='Generate phpinfo() file'
#
# --
_debug " -- Loading ${(%):-%N}"

# What help file is this?
help_files[system]='System commands'

# - Init help array
typeset -gA help_system

# -- cpu
help_system[cpu]='Get CPU cores and threads.'
cpu () {
    eval "lscpu | grep -E '^Thread|^Core|^Socket|^CPU\(|Model name|CPU MHz:|Hypervisor vendor:'"
}

# -- highcpu
help_system[highcpu]='Get processes with high CPU usage.'
alias highcpu="ps aux | sort -nrk 3,3 | head -n 5"

# -- mem
help_system[mem]='Get memory information'
alias mem="free -m"

# -- disk
help_system[disk]='Get disk information'
alias disk="lsblk"

# -- sysinfo
help_system[sysinfo]='Get system information'
sysinfo () {
    _banner_green "CPU"
    cpu
    _banner_green "Memory"
    mem
    _banner_green "Disk"
    disk
    _banner_green "Short Format"
}

# -- sysinfo
help_system[yabs]='Run yabs'
alias yabs="yabs.sh"