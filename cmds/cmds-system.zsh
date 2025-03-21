# =============================================================================
# -- System Commands
# =============================================================================
_debug " -- Loading ${(%):-%N}"
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

# ----------------------------------------
# -- cpu - Get CPU information and features
# -- args: $CPU_FEATURES (default: 1) $QUIET (default: 0)
# ----------------------------------------
help_system[cpu]='CPU Information'
function cpu () {
    local CPU_FEATURES=${1:=1} CPU_QUEIT=${2:=0}    

    [[ $CPU_QUEIT == 0 ]] && _loading "Checking CPU and CPU Features" 
    [[ $CPU_FEATURES == "" ]] && CPU_FEATURES="1"

    # -- FreeBSD
    if [[ $MACHINE_OS == "freebsd" ]]; then
        mhz=$(sysctl -n hw.cpufrequency | awk '{print $1/1000000}')
    elif [[ $MACHINE_OS == "linux" ]]; then
        CPU_MHZ=$(awk '/^cpu MHz/ {print $4}' /proc/cpuinfo | awk '{sum += $1} END {print sum/NR/1000}')

        # -- Check if Mhz is higher than 3Ghz using bc
        _cmd_exists bc
        if [[ $? == "1" ]]; then
            _error "Please install the bc command"
        else
            if (( $(echo "$CPU_MHZ < 3" | bc -l) )); then
                CPU_CHECK=$(_error "CPU Mhz = $CPU_MHZ and is below 3Ghz" 0 )
            elif (( $(echo "$CPU_MHZ < 3.5" | bc -l) )); then
                CPU_CHECK=$(_warning "CPU Mhz = $CPU_MHZ and is between 3Ghz and 3.5Ghz" 0)
            else
                CPU_CHECK=$(_success "CPU Mhz = $CPU_MHZ and is 3.5Ghz or above")
            fi
        fi

        CPU_SOCKET=$(lscpu | awk '/^Socket/{print $2}')
        CPU_CORES=$(lscpu | awk '/^Core\(s\) per socket/{print $4}')
        CPU_THREADS=$(lscpu | awk '/^CPU\(s\)/{print $2}')
        CPU_MODEL=$(lscpu | awk '/Model name:/ { $1=""; print $0 }' | sed 's/^ name: *//')
        echo "CPU: $CPU_MODEL - ${CPU_SOCKET}S/${CPU_CORES}C/${CPU_THREADS}T @ ${CPU_MHZ} || $CPU_CHECK"
    else
        _error "system-specs not implemented for $MACHINE_OS" 0
        return 1
    fi
    if [[ $CPU_FEATURES == "1" ]]; then
        cpu-features $CPU_QUEIT
    fi
}

# -- Check if CPU support
function cpu-features() {
    local OUTPUT="" CPU_QUEIT=${1:=0}     
    # -- Warn running in WSL
    if [[ $MACHINE_OS2 == "wsl" ]]; then
        OUTPUT+="WSL - "
    fi

    # -- Check if in VM
    if [[ $MACHINE_OS2 == "vm" ]]; then
        OUTPUT+="VM - "
    fi

    # -- Check if lscpu is installed
    _cmd_exists lscpu
    if [[ $? == "1" ]]; then
        _error "lscpu not installed"
        return 1
    fi

    # List of important CPU instructions and features
    local FEATURES=("sse" "avx" "fma" "aes" "vt-x" "amd-v" "mmx" "avx2" "sse2")
    local FEATURE_ERROR=("avx" "aes" "amd-v" "vt-x")
    
    # TODO Add in specific CPU features based on Intel or AMD
    local AMD_FEATURE=("svm")
    local INTEL_FEATURE=("vmx")

    # Use lscpu if available, otherwise fall back to /proc/cpuinfo
    local LSCPU="$(command -v lscpu > /dev/null && lscpu || cat /proc/cpuinfo)"
    local PROCCPU="$(cat /proc/cpuinfo)"

    if [[ $CPU_QUEIT == 0 ]]; then        
        # -- Get CPU vendor_id, cpu family, model, model name, cpu mgz, cache size
        local CPU_VENDOR_ID=$(echo "$LSCPU" | awk '/^Vendor ID:/ {print $3}')
        local CPU_FAMILY=$(echo "$LSCPU" | awk '/^CPU family:/ {print $3}')
        local CPU_MODEL=$(echo "$LSCPU" | awk '/^Model:/ {print $2}')
        local CPU_MODEL_NAME=$(echo "$LSCPU" | awk '/^Model name:/ { $1=""; print $0 }' | sed 's/^ name: *//')
        local CPU_MHZ="LSCPU @ $(echo "$LSCPU" | awk '/^CPU MHz:/ {print $3}')"
        if [[ -z $CPU_MHZ  ]]; then
            local CPU_MHZ="CP @ $(echo "$PROCCPU" | awk '/^cpu MHz/ {print $4}')"
        fi
        local CPU_CACHE_SIZE=$(echo "$LSCPU" | awk '/^L3 cache:/ {print $3}')
        local CPU_HYPERVISOR=$(echo "$LSCPU" | awk '/^Hypervisor vendor:/ {print $3}')
        if [[ $CPU_HYPERVISOR == "" ]]; then
            CPU_HYPERVISOR="Can't detect Hypervisor"
        fi  

        # -- Check if CPU is Intel or AMD
        if [[ $CPU_VENDOR_ID == "GenuineIntel" ]]; then
            CPU_VENDOR="Intel"
        elif [[ $CPU_VENDOR_ID == "AuthenticAMD" ]]; then
            CPU_VENDOR="AMD"
        else
            CPU_VENDOR="Unknown"
        fi

        # -- Print out a summary
        OUTPUT+="Hypervisor: $CPU_HYPERVISOR\n" 
        OUTPUT+="$CPU_VENDOR/$CPU_MODEL_NAME/$CPU_MHZ Mhz/CACHE: $CPU_CACHE_SIZE\n"
        OUTPUT+="CPU Family/Model: $CPU_FAMILY/$CPU_MODEL\n"
    fi

    OUTPUT+="CPU Features:"

    # -- Check for CPU features and print out available or not available
    for feature in "${FEATURES[@]}"; do                
        if echo "$LSCPU" | grep -iq "$feature"; then
            OUTPUT+=$(_success "$feature available")
        else                    
            if _inarray $feature 0 "${FEATURE_ERROR[@]}"; then
                OUTPUT+=$(_error "$feature not available ")
            else
                OUTPUT+=$(_warning "$feature not available ")
            fi
        fi
    done

    # -- Format output 
    echo "$OUTPUT"

    # TODO check if CPU supports AES-NI
    # TODO check if CPU supports turbo boost AMD/INTEL
}


# ========================================
# -- mem
# ========================================
help_system[mem]='Get memory information'
function mem () {    
    if [[ $MACHINE_OS == "linux" ]]; then
        # -- Memory
        SWAP_USED=$(free -m | awk 'NR==3 {print $3}')
        MEM=$(free -m | awk 'NR==2 {printf "Total: %s MB, Used:%s MB, Free: %s MB, Cached: %s MB",$2, $3, $4, $6}')

        # -- Swappiness
        [[ -f /proc/sys/vm/swappiness ]] && SWAP="/proc/sys/vm/swappiness: $(cat /proc/sys/vm/swappiness)" || _error "Can't find swap" 0

        # -- Print out Memory and Swap
        echo "Memory: $MEM | Swap: $SWAP_USED | Swapiness: $SWAP"
    elif [[ $MACHINE_OS == "mac" ]]; then
        MEM=$(sysctl hw.memsize | awk '{print $2/1024/1024}')
        MEM_USED=$(echo "scale=2; ${MEM} - $(memory_pressure | grep "Pages free" | awk '{print $3/1024}') - $(memory_pressure | grep "Pages active" | awk '{print $3/1024}') - $(memory_pressure | grep "Pages inactive" | awk '{print $3/1024}') - $(memory_pressure | grep "Pages speculative" | awk '{print $3/1024}') - $(memory_pressure | grep "Pages wired down" | awk '{print $4/1024}')" | bc)
        MEM_CACHED=$(vm_stat | awk '/^Pages free:/ {free=$3} /^Pages speculative:/ {spec=$3} /^Pages inactive:/ {inactive=$3} /^Pages wired down:/ {wired=$4} END {printf "%.1f MB\n", (free+spec+inactive+wired)*4096/1048576}')
        SWAP=$(sysctl vm.swapusage | awk '/vm.swapusage:/ {print $7}')
        echo -n "Mem: ${MEM} | Used: ${MEM_USED} | Cached: ${MEM_CACHED} | Swap: ${SWAP}"
        _notice "You can also run sysctl vm.swapusage or memory_pressure"
    else
        _error "system-specs not implemented for $MACHINE_OS" 0
        return 1
    fi
}

# -- sysinfo
help_system[sysinfo]='Get system information'
sysinfo () {
    cpu
    mem
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