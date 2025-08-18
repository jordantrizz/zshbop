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

# ========================================
# -- mem-details - Get detailed memory hardware information
# ========================================
help_system[mem-details]='Get detailed memory hardware information including capabilities and bank details'
function mem-details () {
    _loading "Getting detailed memory hardware information"
    
    if [[ $MACHINE_OS == "linux" ]]; then
        # Check if lshw and jq are available (preferred for detailed info)
        if command -v lshw > /dev/null 2>&1 && command -v jq > /dev/null 2>&1; then
            MEM_JSON=$(sudo lshw -json -class memory 2>/dev/null)
            if [[ -n "$MEM_JSON" ]]; then
                # Find the main memory entry (System Memory)
                SYSTEM_MEMORY=$(echo "$MEM_JSON" | jq -r '.[] | select(.description == "System Memory")')
                if [[ -n "$SYSTEM_MEMORY" && "$SYSTEM_MEMORY" != "null" ]]; then
                    # Extract capabilities from System Memory
                    MEM_CAPABILITIES=$(echo "$SYSTEM_MEMORY" | jq -r '.capabilities | keys | join(", ")' 2>/dev/null)
                    echo "Memory Capabilities: ${MEM_CAPABILITIES:-Unknown}"
                    echo ""
                fi
                
                # Extract bank information
                echo "Memory Banks:"
                echo "$MEM_JSON" | jq -r '.[] | select(.id | startswith("bank:")) | 
                "  Bank \(.physid): \(.description)
    Product: \(.product // "N/A")
    Vendor: \(.vendor // "N/A") 
    Serial: \(.serial // "N/A")
    Size: \(if .size then (.size / (1024*1024*1024) | floor | tostring) + "GB" else "N/A" end)
    Clock: \(if .clock then (.clock / 1000000 | floor | tostring) + "MHz" else "N/A" end)
    Slot: \(.slot // "N/A")"' 2>/dev/null
            else
                _warning "lshw JSON memory information not accessible (may require sudo)" 0
            fi
        elif command -v lshw > /dev/null 2>&1; then
            # Check if XML output is available
            MEM_XML=$(sudo lshw -xml -class memory 2>/dev/null)
            if [[ -n "$MEM_XML" ]]; then
                # Parse XML for capabilities
                MEM_CAPABILITIES=$(echo "$MEM_XML" | grep -A50 'description>System Memory<' | grep -o '<capability [^>]*' | sed 's/<capability id="//' | sed 's/".*//' | tr '\n' ', ' | sed 's/,$//')
                echo "Memory Capabilities: ${MEM_CAPABILITIES:-Unknown}"
                echo ""
                
                # Parse XML for bank information
                echo "Memory Banks:"
                echo "$MEM_XML" | awk '
                /<node id="bank:[0-9]+"/ {
                    if (match($0, /bank:([0-9]+)/, arr)) {
                        bank_id = arr[1]
                        bank_section = 1
                        bank_output = "  Bank " bank_id ":"
                    }
                }
                bank_section && /<description>/ {
                    if (match($0, /<description>([^<]+)<\/description>/, arr)) {
                        bank_output = bank_output "\n    Description: " arr[1]
                    }
                }
                bank_section && /<product>/ {
                    if (match($0, /<product>([^<]+)<\/product>/, arr)) {
                        bank_output = bank_output "\n    Product: " arr[1]
                    }
                }
                bank_section && /<vendor>/ {
                    if (match($0, /<vendor>([^<]+)<\/vendor>/, arr)) {
                        bank_output = bank_output "\n    Vendor: " arr[1]
                    }
                }
                bank_section && /<serial>/ {
                    if (match($0, /<serial>([^<]+)<\/serial>/, arr)) {
                        bank_output = bank_output "\n    Serial: " arr[1]
                    }
                }
                bank_section && /<size units="bytes">/ {
                    if (match($0, /<size units="bytes">([0-9]+)<\/size>/, arr)) {
                        if (arr[1] > 0) {
                            size_gb = int(arr[1] / 1024 / 1024 / 1024)
                            bank_output = bank_output "\n    Size: " size_gb "GB"
                        } else {
                            bank_output = bank_output "\n    Size: N/A"
                        }
                    }
                }
                bank_section && /<clock>/ {
                    if (match($0, /<clock>([0-9]+)<\/clock>/, arr)) {
                        if (arr[1] > 0) {
                            clock_mhz = int(arr[1] / 1000000)
                            bank_output = bank_output "\n    Clock: " clock_mhz "MHz"
                        } else {
                            bank_output = bank_output "\n    Clock: N/A"
                        }
                    }
                }
                bank_section && /<slot>/ {
                    if (match($0, /<slot>([^<]+)<\/slot>/, arr)) {
                        bank_output = bank_output "\n    Slot: " arr[1]
                    }
                }
                bank_section && /<\/node>/ {
                    if (bank_output) {
                        print bank_output
                        bank_output = ""
                    }
                    bank_section = 0
                }
                END {
                    if (bank_section && bank_output) {
                        print bank_output
                    }
                }
                '
            else
                # Fallback to text parsing
                MEM_LSHW=$(sudo lshw -class memory 2>/dev/null)
                if [[ -n "$MEM_LSHW" ]]; then
                    MEM_CAPABILITIES=$(echo "$MEM_LSHW" | grep -A20 "System Memory" | grep "capabilities:" | awk -F: '{print $2}' | sed 's/^ *//' | head -1)
                    echo "Memory Capabilities: ${MEM_CAPABILITIES:-Unknown}"
                    echo ""
                    echo "Memory Banks:"
                    
                    # Parse text output for bank information
                    echo "$MEM_LSHW" | awk '
                    /\*-bank/ {
                        if (bank_section) {
                            # Print previous bank info if exists
                            if (bank_output) print bank_output
                            bank_output = ""
                        }
                        bank_section = 1
                        bank_id = $0
                        gsub(/.*bank:/, "", bank_id)
                        gsub(/[^0-9]/, "", bank_id)
                        if (bank_id == "") bank_id = "0"
                        bank_output = "  Bank " bank_id ":"
                    }
                    bank_section && /description:/ {
                        gsub(/.*description: */, "")
                        bank_output = bank_output "\n    Description: " $0
                    }
                    bank_section && /product:/ {
                        gsub(/.*product: */, "")
                        bank_output = bank_output "\n    Product: " $0
                    }
                    bank_section && /vendor:/ {
                        gsub(/.*vendor: */, "")
                        bank_output = bank_output "\n    Vendor: " $0
                    }
                    bank_section && /serial:/ {
                        gsub(/.*serial: */, "")
                        bank_output = bank_output "\n    Serial: " $0
                    }
                    bank_section && /size:/ {
                        gsub(/.*size: */, "")
                        bank_output = bank_output "\n    Size: " $0
                    }
                    bank_section && /clock:/ {
                        gsub(/.*clock: */, "")
                        bank_output = bank_output "\n    Clock: " $0
                    }
                    bank_section && /slot:/ {
                        gsub(/.*slot: */, "")
                        bank_output = bank_output "\n    Slot: " $0
                    }
                    /^\*-/ && !/\*-bank/ {
                        if (bank_section && bank_output) {
                            print bank_output
                            bank_output = ""
                        }
                        bank_section = 0
                    }
                    END {
                        if (bank_section && bank_output) {
                            print bank_output
                        }
                    }
                    '
                else
                    _warning "lshw memory information not accessible (may require sudo)" 0
                fi
            fi
        elif command -v dmidecode > /dev/null 2>&1; then
            # Fallback to dmidecode
            _loading "Using dmidecode for memory details"
            MEM_INFO=$(sudo dmidecode -t memory 2>/dev/null)
            if [[ -n "$MEM_INFO" ]]; then
                echo "Memory Information (via dmidecode):"
                echo "$MEM_INFO" | awk '
                /Memory Device/ {
                    device_section = 1
                    device_count++
                    print "  Memory Device " device_count ":"
                }
                device_section && /Size:/ && !/No Module/ {
                    gsub(/.*Size: */, "")
                    print "    Size: " $0
                }
                device_section && /Locator:/ && !/Bank/ {
                    gsub(/.*Locator: */, "")
                    print "    Slot: " $0
                }
                device_section && /Type:/ && !/Type Detail/ {
                    gsub(/.*Type: */, "")
                    print "    Type: " $0
                }
                device_section && /Speed:/ {
                    gsub(/.*Speed: */, "")
                    print "    Speed: " $0
                }
                device_section && /Manufacturer:/ {
                    gsub(/.*Manufacturer: */, "")
                    print "    Vendor: " $0
                }
                device_section && /Part Number:/ {
                    gsub(/.*Part Number: */, "")
                    print "    Product: " $0
                }
                device_section && /Serial Number:/ {
                    gsub(/.*Serial Number: */, "")
                    print "    Serial: " $0
                }
                /^$/ {
                    device_section = 0
                }
                '
            else
                _warning "DMI memory information not accessible (may require sudo)" 0
            fi
        else
            _notice "Install lshw (with jq for best formatting) or dmidecode to get memory hardware details" 0
        fi
    elif [[ $MACHINE_OS == "freebsd" ]]; then
        _loading "Using sysctl for FreeBSD memory details"
        sysctl -a | grep -E "(hw.physmem|hw.realmem|hw.usermem|hw.memsize)"
        echo ""
        echo "Additional memory information:"
        dmesg | grep -i memory | head -10
    elif [[ $MACHINE_OS == "mac" ]]; then
        _loading "Using system_profiler for macOS memory details"
        MEM_INFO=$(system_profiler SPMemoryDataType 2>/dev/null)
        if [[ -n "$MEM_INFO" ]]; then
            echo "Memory Information:"
            echo "$MEM_INFO" | awk '
            /BANK/ {
                bank_section = 1
                print "  " $0 ":"
            }
            bank_section && /Size:/ {
                print "    " $0
            }
            bank_section && /Type:/ {
                print "    " $0
            }
            bank_section && /Speed:/ {
                print "    " $0
            }
            bank_section && /Status:/ {
                print "    " $0
            }
            bank_section && /Manufacturer:/ {
                print "    Vendor: " substr($0, index($0, ":") + 2)
            }
            bank_section && /Part Number:/ {
                print "    Product: " substr($0, index($0, ":") + 2)
            }
            bank_section && /Serial Number:/ {
                print "    Serial: " substr($0, index($0, ":") + 2)
            }
            /^$/ && bank_section {
                bank_section = 0
                print ""
            }
            '
        else
            _notice "Run 'system_profiler SPMemoryDataType' for detailed memory info" 0
        fi
    else
        _error "mem-details not implemented for $MACHINE_OS"
        return 1
    fi
    
    _success "Memory hardware details retrieved successfully"
}

# ===========================================
# -- count-files-directories - Count files and directories in a specified directory
# ===========================================
help_system[count-files-directories]='Count files and directories'
function count-files-directories () {
    local target_dir="$1"

    if [[ -z "$target_dir" ]]; then
        echo "Usage: count-files-directories <directory>"
        echo "Counts the number of files and directories in the specified directory."
        echo "Example: count-files-directories /var/www/html"
        return 1
    fi

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

# ===========================================
# -- disk-details - Get detailed disk hardware information
# ===========================================
help_system[disk-details]='Get detailed disk hardware information including type, serial number, size and brand'
function disk-details () {
    _loading "Getting detailed disk hardware information"
    
    if [[ $MACHINE_OS == "linux" ]]; then
        # Check if lshw and jq are available (preferred for detailed info)
        if command -v lshw > /dev/null 2>&1 && command -v jq > /dev/null 2>&1; then
            DISK_JSON=$(sudo lshw -json -class disk 2>/dev/null)
            if [[ -n "$DISK_JSON" ]]; then
                echo "Disk Information (via lshw):"
                echo "$DISK_JSON" | jq -r '.[] | select(.class == "disk") | 
                "Device: \(.logicalname // "N/A")
  Description: \(.description // "N/A")
  Product: \(.product // "N/A") 
  Vendor: \(.vendor // "N/A")
  Serial: \(.serial // "N/A")
  Size: \(if .size then (.size / (1024*1024*1024) | floor | tostring) + "GB" else "N/A" end)
  Capabilities: \(if .capabilities then (.capabilities | keys | join(", ")) else "N/A" end)
  Physical ID: \(.physid // "N/A")
"' 2>/dev/null
            else
                _warning "lshw JSON disk information not accessible (may require sudo)" 0
            fi
        elif command -v lshw > /dev/null 2>&1; then
            # Fallback to text parsing
            DISK_LSHW=$(sudo lshw -class disk 2>/dev/null)
            if [[ -n "$DISK_LSHW" ]]; then
                echo "Disk Information (via lshw text):"
                echo "$DISK_LSHW" | awk '
                /\*-disk/ {
                    if (disk_section) {
                        if (disk_output) print disk_output "\n"
                        disk_output = ""
                    }
                    disk_section = 1
                    disk_output = "Device:"
                }
                disk_section && /logical name:/ {
                    gsub(/.*logical name: */, "")
                    disk_output = disk_output " " $0 "\n  Description:"
                }
                disk_section && /description:/ {
                    gsub(/.*description: */, "")
                    disk_output = disk_output " " $0
                }
                disk_section && /product:/ {
                    gsub(/.*product: */, "")
                    disk_output = disk_output "\n  Product: " $0
                }
                disk_section && /vendor:/ {
                    gsub(/.*vendor: */, "")
                    disk_output = disk_output "\n  Vendor: " $0
                }
                disk_section && /serial:/ {
                    gsub(/.*serial: */, "")
                    disk_output = disk_output "\n  Serial: " $0
                }
                disk_section && /size:/ {
                    gsub(/.*size: */, "")
                    disk_output = disk_output "\n  Size: " $0
                }
                disk_section && /capabilities:/ {
                    gsub(/.*capabilities: */, "")
                    disk_output = disk_output "\n  Capabilities: " $0
                }
                /^\*-/ && !/\*-disk/ {
                    if (disk_section && disk_output) {
                        print disk_output "\n"
                        disk_output = ""
                    }
                    disk_section = 0
                }
                END {
                    if (disk_section && disk_output) {
                        print disk_output
                    }
                }
                '
            else
                _warning "lshw disk information not accessible (may require sudo)" 0
            fi
        fi

        # Additional information using lsblk and smartctl if available
        echo ""
        _loading "Block device information"
        if command -v lsblk > /dev/null 2>&1; then
            echo "Block Devices:"
            lsblk -o NAME,SIZE,TYPE,MOUNTPOINT,FSTYPE,MODEL,SERIAL 2>/dev/null || lsblk -o NAME,SIZE,TYPE,MOUNTPOINT,FSTYPE 2>/dev/null
        fi

        echo ""
        _loading "SMART disk information"
        if command -v smartctl > /dev/null 2>&1; then
            # Get list of disk devices
            DISK_DEVICES=$(lsblk -d -n -o NAME 2>/dev/null | grep -E '^(sd[a-z]|nvme[0-9]|hd[a-z])' | head -10)
            if [[ -n "$DISK_DEVICES" ]]; then
                echo "SMART Information:"
                while read -r device; do
                    if [[ -n "$device" ]]; then
                        echo "  Device: /dev/$device"
                        SMART_INFO=$(sudo smartctl -i /dev/$device 2>/dev/null)
                        if [[ $? -eq 0 && -n "$SMART_INFO" ]]; then
                            echo "$SMART_INFO" | awk '
                            /Device Model:/ { print "    Model: " substr($0, index($0, ":") + 2) }
                            /Serial Number:/ { print "    Serial: " substr($0, index($0, ":") + 2) }
                            /User Capacity:/ { print "    Capacity: " substr($0, index($0, ":") + 2) }
                            /Rotation Rate:/ { print "    Type: " (substr($0, index($0, ":") + 2) ~ /Solid State/ ? "SSD" : "HDD") }
                            /Form Factor:/ { print "    Form Factor: " substr($0, index($0, ":") + 2) }
                            /Firmware Version:/ { print "    Firmware: " substr($0, index($0, ":") + 2) }
                            '
                        else
                            echo "    SMART data not available"
                        fi
                        echo ""
                    fi
                done <<< "$DISK_DEVICES"
            fi
        else
            _notice "Install smartmontools for SMART disk information" 0
        fi

    elif [[ $MACHINE_OS == "freebsd" ]]; then
        _loading "Using FreeBSD disk commands"
        echo "Disk Information:"
        
        # Get disk info using camcontrol
        if command -v camcontrol > /dev/null 2>&1; then
            echo "CAM devices:"
            camcontrol devlist 2>/dev/null
            echo ""
        fi
        
        # Get mounted filesystems
        echo "Mounted filesystems:"
        df -h | awk 'NR==1 || /^\/dev\//'
        
        # Get disk info using geom
        if command -v geom > /dev/null 2>&1; then
            echo ""
            echo "GEOM disk information:"
            geom disk list 2>/dev/null | awk '
            /^Geom name:/ { disk = $3; print "Device: " disk }
            /Mediasize:/ { print "  Size: " $2 " bytes (" $3 " " $4 ")" }
            /descr:/ { print "  Description: " substr($0, index($0, ":") + 2) }
            /ident:/ { print "  Serial: " substr($0, index($0, ":") + 2) }
            /^$/ { if (disk) print "" }
            '
        fi

    elif [[ $MACHINE_OS == "mac" ]]; then
        _loading "Using macOS disk commands"
        echo "Disk Information:"
        
        # Use system_profiler for detailed info
        if command -v system_profiler > /dev/null 2>&1; then
            DISK_INFO=$(system_profiler SPStorageDataType 2>/dev/null)
            if [[ -n "$DISK_INFO" ]]; then
                echo "$DISK_INFO" | awk '
                /^[[:space:]]*[^[:space:]].*:$/ && !/Storage/ {
                    disk_name = $0
                    gsub(/:$/, "", disk_name)
                    gsub(/^[[:space:]]*/, "", disk_name)
                    print "Device: " disk_name
                    disk_section = 1
                }
                disk_section && /Capacity:/ {
                    print "  Size: " substr($0, index($0, ":") + 2)
                }
                disk_section && /Available:/ {
                    print "  Available: " substr($0, index($0, ":") + 2)
                }
                disk_section && /File System:/ {
                    print "  File System: " substr($0, index($0, ":") + 2)
                }
                disk_section && /Connection Type:/ {
                    print "  Connection: " substr($0, index($0, ":") + 2)
                }
                /^$/ && disk_section {
                    disk_section = 0
                    print ""
                }
                '
            fi
        fi
        
        # Use diskutil for additional info
        echo ""
        echo "Additional disk information:"
        if command -v diskutil > /dev/null 2>&1; then
            diskutil list physical 2>/dev/null || diskutil list 2>/dev/null
        fi

    else
        _error "disk-details not implemented for $MACHINE_OS"
        return 1
    fi
    
    _success "Disk hardware details retrieved successfully"
}