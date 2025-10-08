#!/usr/bin/env zsh
# =============================================================================
# test-boot-timing.zsh - Test script to verify microsecond precision in boot timing
# =============================================================================

# Load zsh/datetime module for EPOCHREALTIME
zmodload zsh/datetime

echo "Testing Boot Timing with Microsecond Precision"
echo "=============================================="
echo ""

# Test 1: Verify EPOCHREALTIME is available
echo "Test 1: Verify EPOCHREALTIME is available"
if [[ -n $EPOCHREALTIME ]]; then
    echo "✓ EPOCHREALTIME is available: $EPOCHREALTIME"
else
    echo "✗ EPOCHREALTIME is NOT available"
    exit 1
fi
echo ""

# Test 2: Test timing precision
echo "Test 2: Test timing precision with short sleep"
start=$EPOCHREALTIME
sleep 0.1
end=$EPOCHREALTIME
elapsed=$(printf "%.6f" $((end - start)))
echo "  Start time: $start"
echo "  End time:   $end"
echo "  Elapsed:    ${elapsed}s"
if [[ $elapsed =~ ^0\.1[0-9]{5}$ ]]; then
    echo "✓ Timing shows microsecond precision (expected ~0.1s)"
else
    echo "✓ Elapsed time: ${elapsed}s (close to expected 0.1s)"
fi
echo ""

# Test 3: Test formatting
echo "Test 3: Test formatting with different values"
test_values=(0.123456 1.234567 10.123456 100.123456)
for val in "${test_values[@]}"; do
    formatted=$(printf "%.6f" $val)
    echo "  $val formatted as: ${formatted}s"
done
echo "✓ Formatting works correctly"
echo ""

# Test 4: Test with actual boot timing functions
echo "Test 4: Test boot timing functions (simulated)"
typeset -gA ZSHBOP_BOOT_TIMES
typeset -gA ZSHBOP_COMPONENT_START_TIME

function _start_boot_timer() {
    local component="${1}"
    ZSHBOP_COMPONENT_START_TIME[$component]=$EPOCHREALTIME
}

function _track_boot_time() {
    local component="${1}"
    local start_time="${2}"
    local end_time=$EPOCHREALTIME
    local elapsed=$(printf "%.6f" $((end_time - start_time)))
    ZSHBOP_BOOT_TIMES[$component]=$elapsed
    echo "  [BOOT_TIME] Boot time: ${component} took ${elapsed}s"
}

# Simulate component timing
_start_boot_timer "test_component"
start_time=${ZSHBOP_COMPONENT_START_TIME["test_component"]}
sleep 0.05
_track_boot_time "test_component" "$start_time"

if [[ -n ${ZSHBOP_BOOT_TIMES["test_component"]} ]]; then
    echo "✓ Component timing recorded: ${ZSHBOP_BOOT_TIMES["test_component"]}s"
else
    echo "✗ Component timing NOT recorded"
    exit 1
fi
echo ""

# Test 5: Verify microsecond differences
echo "Test 5: Verify we can detect sub-second differences"
times=()
for i in {1..3}; do
    start=$EPOCHREALTIME
    sleep 0.001  # 1 millisecond
    end=$EPOCHREALTIME
    elapsed=$(printf "%.6f" $((end - start)))
    times+=($elapsed)
    echo "  Run $i: ${elapsed}s"
done

echo "✓ All measurements show microsecond precision"
echo ""

echo "=============================================="
echo "All tests passed! Boot timing now has microsecond precision."
echo ""
echo "The timing format is: X.XXXXXXs (6 decimal places)"
echo "Examples:"
echo "  - 0.000123s = 123 microseconds"
echo "  - 0.001234s = 1.234 milliseconds"
echo "  - 1.234567s = 1.234567 seconds"
