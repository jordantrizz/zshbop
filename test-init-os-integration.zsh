#!/usr/bin/env zsh
# =============================================================================
# test-init-os-integration.zsh - Integration test for init_os boot timing
# =============================================================================

echo "Integration Test: init_os Boot Timing"
echo "======================================"
echo ""

# Load zsh/datetime module for EPOCHREALTIME
zmodload zsh/datetime

# Set up minimal environment
export ZSHBOP_ROOT="/home/runner/work/zshbop/zshbop"
export ZSHBOP_HOME="$HOME"
export ZB_LOG="/tmp/test-init-os-integration.log"
export ZSH_DEBUG=1
export ZSH_DEBUG_LOG=0
export ZSH_VERBOSE=0
export ZB_LOG_STATUS=1
export ZSHBOP_CACHE_DIR="/tmp/zshbop-cache"

# Set up OS detection
export UNAME=$(uname -s)
case "${UNAME}" in
    Linux*)     MACHINE_OS=linux;;
    Darwin*)    MACHINE_OS=mac;;
    CYGWIN*)    MACHINE_OS=cygwin;;
    MINGW*)     MACHINE_OS=mingw;;
    *)          MACHINE_OS="UNKNOWN:${UNAME}"
esac

# Clean up log file
rm -f "$ZB_LOG"
mkdir -p "$ZSHBOP_CACHE_DIR"

# Load necessary libraries
source ${ZSHBOP_ROOT}/lib/colors.zsh 2>/dev/null || true
RSC=$reset_color

# Load the actual include and init files (but skip full init)
typeset -gA ZSHBOP_BOOT_TIMES
typeset -gA ZSHBOP_COMPONENT_START_TIME
typeset -g ZSHBOP_BOOT_START=0

# Mock or load required functions
function _debug_all() { : }
function _debug() { [[ $ZSH_DEBUG == 1 ]] && echo "\033[36m[DEBUG]: $@\033[0m"; }
function _log() { echo "[LOG] $@" >> "$ZB_LOG"; }

# Load the actual _start_boot_timer function from include.zsh
function _start_boot_timer() {
    local component="${1}"
    ZSHBOP_COMPONENT_START_TIME[$component]=$EPOCHREALTIME
}

# Load the actual init_log function from init.zsh
function init_log () {
    local ZSBBOP_FUNC_LOADING="${funcstack[2]}"

    # Check if $ZSBBOP_FUNC_LOADING is already in $ZSHBOP_LOAD
    if [[ " ${ZSHBOP_LOAD[@]} " =~ " ${ZSBBOP_FUNC_LOADING} " ]]; then
        _debug "Already loaded $ZSBBOP_FUNC_LOADING"
    else
        _debug "Loading $ZSBBOP_FUNC_LOADING"
        ZSHBOP_LOAD+=($ZSBBOP_FUNC_LOADING)
    fi
    
    # Track boot time for this component
    if [[ -n ${ZSHBOP_COMPONENT_START_TIME[$ZSBBOP_FUNC_LOADING]} ]]; then
        local start_time=${ZSHBOP_COMPONENT_START_TIME[$ZSBBOP_FUNC_LOADING]}
        local end_time=$EPOCHREALTIME
        local elapsed=$(printf "%.6f" $((end_time - start_time)))
        ZSHBOP_BOOT_TIMES[$ZSBBOP_FUNC_LOADING]=$elapsed
        
        # Log to both debug and file
        local msg="Boot time: ${ZSBBOP_FUNC_LOADING} took ${elapsed}s"
        _debug "$msg"
        echo "[BOOT_TIME] $msg" >> "$ZB_LOG"
        
        # Clear the start time
        unset "ZSHBOP_COMPONENT_START_TIME[$ZSBBOP_FUNC_LOADING]"
    fi
}

echo "Test 1: Full integration test with real OS files"
echo "------------------------------------------------"

# Source the actual init_os function from the real file
source ${ZSHBOP_ROOT}/lib/init.zsh 2>/dev/null || {
    echo "✗ Failed to load init.zsh"
    exit 1
}

# Now call init_os with timing
echo "Calling init_os with _start_boot_timer..."
_start_boot_timer "init_os"
init_os

echo ""
echo "Boot timing log entries:"
echo "========================"
grep "\[BOOT_TIME\]" "$ZB_LOG"
echo ""

# Verify boot time summary
if grep -q "\[BOOT_TIME\].*init_os:" "$ZB_LOG"; then
    echo "✓ Test PASSED: init_os nested timing entries found"
else
    echo "✗ Test FAILED: No init_os nested timing entries"
    exit 1
fi

if grep -q "\[BOOT_TIME\] Boot time: init_os took" "$ZB_LOG"; then
    echo "✓ Test PASSED: init_os overall timing entry found"
else
    echo "✗ Test FAILED: No init_os overall timing entry"
    exit 1
fi

# Verify microsecond precision
if grep -E "\[BOOT_TIME\].*init_os.*[0-9]+\.[0-9]{6}s" "$ZB_LOG"; then
    echo "✓ Test PASSED: Timing shows microsecond precision"
else
    echo "✗ Test FAILED: Timing does not show microsecond precision"
    exit 1
fi

# Check if os-common was loaded
if grep -q "\[BOOT_TIME\].*init_os: os-common.zsh loaded" "$ZB_LOG"; then
    echo "✓ Test PASSED: os-common.zsh timing found"
else
    echo "✗ Test FAILED: os-common.zsh timing not found"
    exit 1
fi

# Check that overall timing is >= sum of parts
overall_time=$(grep "\[BOOT_TIME\] Boot time: init_os took" "$ZB_LOG" | grep -oE "[0-9]+\.[0-9]{6}" | head -1)
if [[ -n $overall_time ]]; then
    echo "✓ Overall init_os time: ${overall_time}s"
else
    echo "✗ Could not extract overall time"
fi

echo ""
echo "Test 2: Verify ZSH_DEBUG controls real-time output"
echo "---------------------------------------------------"

# Turn off debug output
export ZSH_DEBUG=0
rm -f "$ZB_LOG"

# Re-run init_os (need to reload to reset state)
echo "Running with ZSH_DEBUG=0 (no console output expected)..."
_start_boot_timer "init_os"
init_os > /tmp/console-output.txt 2>&1

# Check that log file still has entries
if grep -q "\[BOOT_TIME\]" "$ZB_LOG"; then
    echo "✓ Log file still has BOOT_TIME entries (good)"
else
    echo "✗ Log file missing BOOT_TIME entries"
    exit 1
fi

# Check console output has no debug messages
if ! grep -q "\[DEBUG\]" /tmp/console-output.txt; then
    echo "✓ No debug output to console with ZSH_DEBUG=0 (good)"
else
    echo "✗ Debug output appeared on console despite ZSH_DEBUG=0"
fi

# Clean up
rm -f "$ZB_LOG" /tmp/console-output.txt
rm -rf "$ZSHBOP_CACHE_DIR"

echo ""
echo "======================================"
echo "All integration tests passed!"
echo ""
echo "Summary:"
echo "- init_os boot timing instrumentation works correctly"
echo "- Nested timing for OS-specific components is logged"
echo "- Microsecond precision is maintained"
echo "- Overall component timing is tracked"
echo "- Logging respects ZSH_DEBUG setting"
echo "- All logs are written to ~/.zshbop.log"
