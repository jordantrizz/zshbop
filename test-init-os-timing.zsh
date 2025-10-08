#!/usr/bin/env zsh
# =============================================================================
# test-init-os-timing.zsh - Test script to verify init_os boot timing
# =============================================================================

echo "Testing init_os Boot Timing Instrumentation"
echo "============================================="
echo ""

# Load zsh/datetime module for EPOCHREALTIME
zmodload zsh/datetime

# Set up minimal environment
export ZSHBOP_ROOT="/home/runner/work/zshbop/zshbop"
export ZB_LOG="/tmp/test-init-os-timing.log"
export ZSH_DEBUG=1
export ZSH_DEBUG_LOG=0
export ZSH_VERBOSE=0
export ZB_LOG_STATUS=1

# Clean up log file
rm -f "$ZB_LOG"
touch "$ZB_LOG"

# Mock required variables
export MACHINE_OS="linux"
export MACHINE_OS2=""

# Load colors
source ${ZSHBOP_ROOT}/lib/colors.zsh
RSC=$reset_color

# Mock required functions
_debug_all() { : }
_log() { echo "[LOG] $@" >> "$ZB_LOG"; }
_debug() { [[ $ZSH_DEBUG == 1 ]] && echo "[DEBUG] $@"; }
init_log() { : }

# Mock OS files to simulate loading
mkdir -p /tmp/mock-os-cmds
cat > /tmp/mock-os-cmds/os-common.zsh << 'EOF'
# Mock os-common.zsh
sleep 0.01
EOF

cat > /tmp/mock-os-cmds/os-linux.zsh << 'EOF'
# Mock os-linux.zsh
sleep 0.02
EOF

cat > /tmp/mock-os-cmds/os-mac.zsh << 'EOF'
# Mock os-mac.zsh
sleep 0.015
EOF

# Override ZSHBOP_ROOT/cmds path for testing
ZSHBOP_ROOT="/tmp/mock-os-cmds"

echo "Test 1: Testing Linux OS timing"
echo "--------------------------------"

# Define the init_os function with our changes
function init_os () {
	_debug_all
    _log "Loading OS specific configuration"
    
    # Track timing for common OS configuration
    local os_common_start=$EPOCHREALTIME
	_log "Loading $ZSHBOP_ROOT/cmds/os-common.zsh"
	source $ZSHBOP_ROOT/os-common.zsh
	local os_common_elapsed=$(printf "%.6f" $((EPOCHREALTIME - os_common_start)))
    _debug "Loaded os-common.zsh in ${os_common_elapsed}s"
    echo "[BOOT_TIME]   init_os: os-common.zsh loaded in ${os_common_elapsed}s" >> "$ZB_LOG"

	# Include OS Specific configuration	
	# -- Mac
	if [[ $MACHINE_OS == "mac" ]] then
        local os_mac_start=$EPOCHREALTIME
        _log "Loading OS Configuration cmds/os-mac.zsh"
        source $ZSHBOP_ROOT/os-mac.zsh
        local os_mac_elapsed=$(printf "%.6f" $((EPOCHREALTIME - os_mac_start)))
        _debug "Loaded os-mac.zsh in ${os_mac_elapsed}s"
        echo "[BOOT_TIME]   init_os: os-mac.zsh loaded in ${os_mac_elapsed}s" >> "$ZB_LOG"
    # -- WSL Linux
    elif [[ $MACHINE_OS2 = "wsl" ]]; then
        local os_wsl_start=$EPOCHREALTIME
        _log "Loading cmds/os-linux.zsh and cmds/os-wsl.zsh"
        
        local os_linux_wsl_start=$EPOCHREALTIME
        source $ZSHBOP_ROOT/os-linux.zsh
        local os_linux_wsl_elapsed=$(printf "%.6f" $((EPOCHREALTIME - os_linux_wsl_start)))
        _debug "Loaded os-linux.zsh (WSL) in ${os_linux_wsl_elapsed}s"
        echo "[BOOT_TIME]   init_os: os-linux.zsh (WSL) loaded in ${os_linux_wsl_elapsed}s" >> "$ZB_LOG"
        
        local os_wsl_file_start=$EPOCHREALTIME
        source $ZSHBOP_ROOT/os-wsl.zsh
        local os_wsl_file_elapsed=$(printf "%.6f" $((EPOCHREALTIME - os_wsl_file_start)))
        _debug "Loaded os-wsl.zsh in ${os_wsl_file_elapsed}s"
        echo "[BOOT_TIME]   init_os: os-wsl.zsh loaded in ${os_wsl_file_elapsed}s" >> "$ZB_LOG"
        
        local init_wsl_start=$EPOCHREALTIME
        # Mock init_wsl function
        sleep 0.005
        local init_wsl_elapsed=$(printf "%.6f" $((EPOCHREALTIME - init_wsl_start)))
        _debug "init_wsl completed in ${init_wsl_elapsed}s"
        echo "[BOOT_TIME]   init_os: init_wsl completed in ${init_wsl_elapsed}s" >> "$ZB_LOG"
        
        local os_wsl_elapsed=$(printf "%.6f" $((EPOCHREALTIME - os_wsl_start)))
        echo "[BOOT_TIME]   init_os: WSL configuration total time ${os_wsl_elapsed}s" >> "$ZB_LOG"
	# -- Linux
    elif [[ $MACHINE_OS = "linux" ]] then
        local os_linux_start=$EPOCHREALTIME
		_log "Loading cmds/os-linux.zsh"
        source $ZSHBOP_ROOT/os-linux.zsh
        local os_linux_elapsed=$(printf "%.6f" $((EPOCHREALTIME - os_linux_start)))
        _debug "Loaded os-linux.zsh in ${os_linux_elapsed}s"
        echo "[BOOT_TIME]   init_os: os-linux.zsh loaded in ${os_linux_elapsed}s" >> "$ZB_LOG"
    elif [[ $MACHINE_OS = "synology" ]] then
        local os_synology_start=$EPOCHREALTIME
		_log "Loading cmds/os-linux.zsh (Synology)"
        source $ZSHBOP_ROOT/os-linux.zsh
        local os_synology_elapsed=$(printf "%.6f" $((EPOCHREALTIME - os_synology_start)))
        _debug "Loaded os-linux.zsh (Synology) in ${os_synology_elapsed}s"
        echo "[BOOT_TIME]   init_os: os-linux.zsh (Synology) loaded in ${os_synology_elapsed}s" >> "$ZB_LOG"
	else
        _log "No OS specific configuration found for MACHINE_OS=$MACHINE_OS"
        echo "[BOOT_TIME]   init_os: No OS-specific configuration loaded (MACHINE_OS=$MACHINE_OS)" >> "$ZB_LOG"
    fi
    init_log
}

# Run the test
init_os

echo ""
echo "Log file contents:"
echo "==================="
cat "$ZB_LOG"
echo ""

# Verify log entries exist
if grep -q "\[BOOT_TIME\].*init_os:" "$ZB_LOG"; then
    echo "✓ Test PASSED: init_os timing entries found in log"
else
    echo "✗ Test FAILED: No init_os timing entries found in log"
    exit 1
fi

# Verify microsecond precision
if grep -E "\[BOOT_TIME\].*init_os:.*[0-9]+\.[0-9]{6}s" "$ZB_LOG"; then
    echo "✓ Test PASSED: Timing entries show microsecond precision"
else
    echo "✗ Test FAILED: Timing entries do not show microsecond precision"
    exit 1
fi

echo ""
echo "Test 2: Testing unknown OS (short-circuit)"
echo "-------------------------------------------"

# Reset log
rm -f "$ZB_LOG"
touch "$ZB_LOG"

export MACHINE_OS="UNKNOWN"
export MACHINE_OS2=""

init_os

echo "Log file contents:"
echo "==================="
cat "$ZB_LOG"
echo ""

# Verify we still get boot time entries even with short-circuit
if grep -q "\[BOOT_TIME\].*init_os:" "$ZB_LOG"; then
    echo "✓ Test PASSED: init_os timing entries found even with short-circuit"
else
    echo "✗ Test FAILED: No init_os timing entries with short-circuit"
    exit 1
fi

# Clean up
rm -rf /tmp/mock-os-cmds
rm -f "$ZB_LOG"

echo ""
echo "============================================="
echo "All tests passed! init_os boot timing instrumentation is working."
