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

# -- check-cpu-mhz
help_system[check-cpu-mhz]='Check if running high frequency'
function check-cpu-mhz() {
    if [[ $(uname -s) == "FreeBSD" ]]; then
        mhz=$(sysctl -n hw.cpufrequency | awk '{print $1/1000000}')
    else
        mhz=$(awk '/^cpu MHz/ {print $4}' /proc/cpuinfo | awk '{sum += $1} END {print sum/NR/1000}')
    fi
    if [[ ! bc ]]; then
        _error "Please install the bc command"
    else
        if (( $(echo "$mhz < 3" | bc -l) )); then
            _error "CPU Mhz = $mhz and is below 3Ghz"
        elif (( $(echo "$mhz < 3.5" | bc -l) )); then
            _warning "CPU Mhz = $mhz and is between 3Ghz and 3.5Ghz"
        else
            _success "CPU Mhz = $mhz and is 3.5Ghz or above"
        fi
    fi

    local model=$(lscpu | awk '/Model name:/ { $1=""; print $0 }' | sed 's/^ *//')
    echo " - Processor Model: $model"
}

help_system[system-specs]='Print system specs'
function system-specs () {
    _loading "System specs on $MACHINE_OS"

    if [[ $MACHINE_OS == "linux" ]]; then
        echo " - Sockets: $(lscpu | awk '/^Socket/{print $2}') Cores: $(lscpu | awk '/^Core\(s\) per socket/{print $4}')  Threads: $(lscpu | awk '/^CPU\(s\)/{print $2}')"
        echo " - System Memory $(free -g | awk '/^Mem:/{print $2}')GB"
        echo "$(check-cpu-mhz)"	
    else
        _error "check_specs not implemented for $MACHINE_OS"
    fi
    
    _loading2 "Network interfaces"
    interfaces
    
	_loading2 "Swappiness"
    swappiness

	_loading2 "Checking disk space on $MACHINE_OS"
	check_diskspace show

    # -- check block devices
    _loading2 "Checking block devices"
	check_blockdevices show
}

help_system[count-files-directories]='Count files and directories'
function count-files-directories () {
    local target_dir="$1"

    if [[ -d "${target_dir}" ]]; then
        num_files=$(find "${target_dir}" -type f | wc -l)
        num_dirs=$(find "${target_dir}" -type d | wc -l)

        echo "Number of files in ${target_dir}: ${num_files}"
        echo "Number of directories in ${target_dir}: ${num_dirs}"
    else
        echo "Error: ${target_dir} is not a valid directory"
    fi
}