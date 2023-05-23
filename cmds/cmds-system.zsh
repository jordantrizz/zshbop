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

# -- highcpu
help_system[highcpu]='Get processes with high CPU usage.'
alias highcpu="ps aux | sort -nrk 3,3 | head -n 5"

# -- disk
help_system[disk]='Get disk information'
alias disk="lsblk"

# -- sysinfo
help_system[yabs]='Run yabs'
alias yabs="yabs.sh"

# -- cpu
help_system[cpu]='CPU Information'
function cpu () {
    # -- FreeBSD
    if [[ $MACHINE_OS == "freebsd" ]]; then
        mhz=$(sysctl -n hw.cpufrequency | awk '{print $1/1000000}')
    elif [[ $MACHINE_OS == "linux" ]]; then
        CPU_MHZ=$(awk '/^cpu MHz/ {print $4}' /proc/cpuinfo | awk '{sum += $1} END {print sum/NR/1000}')

        # -- Check if Mhz is higher than 3Ghz using bc
        _cexists bc
        if [[ $? == "1" ]]; then
            _error "Please install the bc command"
        else
            if (( $(echo "$CPU_MHZ < 3" | bc -l) )); then
                CPU_CHECK=$(_error "CPU Mhz = $CPU_MHZ and is below 3Ghz" 0 )
            elif (( $(echo "$CPU_MHZ < 3.5" | bc -l) )); then
                CPU_CHECK=$(_warning "CPU Mhz = $CPU_MHZ and is between 3Ghz and 3.5Ghz" 0)
            else
                CPU_CHECK="CPU Mhz = $CPU_MHZ and is 3.5Ghz or above"
            fi
        fi

        CPU_SOCKET=$(lscpu | awk '/^Socket/{print $2}')
        CPU_CORES=$(lscpu | awk '/^Core\(s\) per socket/{print $4}')
        CPU_THREADS=$(lscpu | awk '/^CPU\(s\)/{print $2}')
        CPU_MODEL=$(lscpu | awk '/Model name:/ { $1=""; print $0 }' | sed 's/^ name: *//')
        echo "CPU: $CPU_MODEL - ${CPU_SOCKET}S/${CPU_CORES}C/${CPU_THREADS}T @ ${CPU_MHZ} || $CPU_CHECK"
    else
        _error "system-specs not implemented for $MACHINE_OS"
    fi
}

# -- mem
help_system[mem]='Get memory information'
function mem () {
    memory_info=$(free -m | awk 'NR==2 {printf "%s MB used, %s MB free, %s MB cached", $3, $4, $6}')
    echo "Memory: $memory_info"
}

# -- sysinfo
help_system[sysinfo]='Get system information'
sysinfo () {
    _loading "CPU"
    cpu
    _loading "Memory"
    mem
    _loading "Disk"
    disk
   _loading "Short Format"
}

help_system[count-files-directories]='Count files and directories'
function count-files-directories () {
    local target_dir="$1"

    if [[ -d "${target_dir}" ]]; then
        num_files=$(find "${target_dir}" -type f | wc -l)
        num_dirs=$(find "${target_dir}" -type d | wc -l)
        total_size=$(du -sh "${target_dir}" | cut -f1)
        _loading "Getting details on ${target_dir}"

        _loading3 "Number of files: ${num_files}"
        _loading3 "Number of directories: ${num_dirs}"
        _loading3 "Total size: ${total_size}"

        if [[ -d "${target_dir}/wp-content" ]]; then
            _loading "Size breakdown of ${target_dir}/wp-content"
            find "${target_dir}/wp-content" -maxdepth 1 -type d -exec du -sh {} \; | sort -hr
        fi
    else
        echo "Error: ${target_dir} is not a valid directory"
    fi

}