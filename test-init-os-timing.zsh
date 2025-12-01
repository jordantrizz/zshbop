#!/usr/bin/env zsh
# =============================================================================
# test-init-os-timing.zsh - Test script to verify init_os execution timing
# =============================================================================

echo "Testing init_os Execution Time Tracking"
echo "========================================"
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
source ${ZSHBOP_ROOT}/lib/colors.zsh 2>/dev/null || true
RSC=$reset_color

# Load the execution time tracking functions
typeset -gA ZSHBOP_EXEC_TIMES
typeset -gA ZSHBOP_EXEC_START_TIME

source ${ZSHBOP_ROOT}/lib/include.zsh 2>/dev/null || {
    # Fallback if full load fails - define minimal functions
    function _debug() { [[ $ZSH_DEBUG == 1 ]] && echo "[DEBUG] $@"; }
    function _log() { echo "[LOG] $@" >> "$ZB_LOG"; }
    function _debug_all() { : }
    function init_log() { : }
    
    function _track_execution() {
        local label="${1}"
        local context="${2:-}"
        local start_time="${3}"
        local end_time=$EPOCHREALTIME
        local elapsed=$(printf "%.6f" $((end_time - start_time)))
        
        local key="${context:+${context}:}${label}"
        ZSHBOP_EXEC_TIMES[$key]=$elapsed
        
        local msg
        if [[ -n $context ]]; then
            msg="Execution time: ${context}: ${label} took ${elapsed}s"
            local log_msg="[EXEC_TIME]   ${context}: ${label} took ${elapsed}s"
        else
            msg="Execution time: ${label} took ${elapsed}s"
            local log_msg="[EXEC_TIME] ${label} took ${elapsed}s"
        fi
        
        _debug "$msg"
        echo "$log_msg" >> "$ZB_LOG"
    }
    
    function _time_step() {
        local description="${1}"
        local context="${2}"
        shift 2
        
        local start_time=$EPOCHREALTIME
        "$@"
        local exit_code=$?
        _track_execution "$description" "$context" "$start_time"
        return $exit_code
    }
}

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

# Override path for testing
ZSHBOP_ROOT_ORIG="$ZSHBOP_ROOT"
ZSHBOP_ROOT="/tmp/mock-os-cmds"

echo "Test 1: Testing Linux OS timing with new _time_step function"
echo "-------------------------------------------------------------"

# Define init_os using the new approach
function init_os () {
    _debug_all
    _log "Loading OS specific configuration"
    
    _time_step "os-common.zsh" "init_os" source $ZSHBOP_ROOT/os-common.zsh
    
    if [[ $MACHINE_OS = "linux" ]] then
        _log "Loading cmds/os-linux.zsh"
        _time_step "os-linux.zsh" "init_os" source $ZSHBOP_ROOT/os-linux.zsh
    fi
    init_log
}

# Run test
init_os

echo ""
echo "Log file contents:"
echo "==================="
cat "$ZB_LOG"
echo ""

# Verify execution time entries exist
if grep -q "\[EXEC_TIME\].*init_os:" "$ZB_LOG"; then
    echo "✓ Test PASSED: init_os execution timing entries found in log"
else
    echo "✗ Test FAILED: No init_os execution timing entries found in log"
    exit 1
fi

# Verify microsecond precision
if grep -E "\[EXEC_TIME\].*init_os:.*[0-9]+\.[0-9]{6}s" "$ZB_LOG"; then
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

# Verify we still get execution time entries even with short-circuit
if grep -q "\[EXEC_TIME\].*init_os:" "$ZB_LOG"; then
    echo "✓ Test PASSED: init_os timing entries found even with short-circuit"
else
    echo "✗ Test FAILED: No init_os timing entries with short-circuit"
    exit 1
fi

# Clean up
rm -rf /tmp/mock-os-cmds
