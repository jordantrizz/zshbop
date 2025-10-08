# Execution Time Tracking with Microsecond Precision

## Overview
zshbop includes a flexible execution time tracking system with microsecond precision (6 decimal places). This system can track both boot-time initialization and runtime function execution, making it easy to identify performance bottlenecks throughout the codebase.

## Key Features
- **Microsecond precision** - Uses `$EPOCHREALTIME` for 6 decimal place accuracy
- **Reusable functions** - Generic timing functions work anywhere in zshbop
- **Nested timing** - Track parent operations and their sub-steps
- **Minimal code** - Simple one-line wrappers eliminate boilerplate
- **Debug integration** - Real-time output when `ZSH_DEBUG=1`
- **Persistent logging** - All times logged to `~/.zshbop.log`

## Core Functions

### _time_step
The simplest way to track execution time for any operation:

```zsh
_time_step "description" "context" command args...
```

**Example:**
```zsh
# Track sourcing a file
_time_step "os-common.zsh" "init_os" source $ZSHBOP_ROOT/cmds/os-common.zsh

# Track a function call
_time_step "init_wsl" "init_os" init_wsl
```

### _track_execution
Lower-level function for manual timing:

```zsh
local start_time=$EPOCHREALTIME
# ... do work ...
_track_execution "label" "context" "$start_time"
```

### _start_execution_timer / _start_boot_timer
For component-level timing (used with `init_log`):

```zsh
_start_execution_timer "my_component"
# ... component work ...
init_log  # Automatically tracks elapsed time
```

## Usage Examples

### Simple One-Line Timing
```zsh
function my_function() {
    _time_step "load_config" "my_function" source /path/to/config.zsh
    _time_step "process_data" "my_function" process_large_dataset
}
```

### init_os Example (Clean Refactored Code)
```zsh
function init_os () {
    _log "Loading OS specific configuration"
    
    # Simple one-line calls - no boilerplate!
    _time_step "os-common.zsh" "init_os" source $ZSHBOP_ROOT/cmds/os-common.zsh
    
    if [[ $MACHINE_OS == "mac" ]] then
        _time_step "os-mac.zsh" "init_os" source $ZSHBOP_ROOT/cmds/os-mac.zsh
    elif [[ $MACHINE_OS = "linux" ]] then
        _time_step "os-linux.zsh" "init_os" source $ZSHBOP_ROOT/cmds/os-linux.zsh
    fi
    init_log
}
```

## Log Output Format

### Execution Time Entries
```
[EXEC_TIME]   init_os: os-common.zsh took 0.002705s
[EXEC_TIME]   init_os: os-linux.zsh took 0.000986s
[EXEC_TIME] init_os took 0.004455s
```

### Boot Time Summary
```
[BOOT_TIME] ========================================
[BOOT_TIME] zshbop Boot Time Summary
[BOOT_TIME] ========================================
[BOOT_TIME] Total boot time: 3.456789s
[BOOT_TIME] Component breakdown:
[BOOT_TIME]   init_core: 0.234567s
[BOOT_TIME]   init_os: 0.004455s
[BOOT_TIME]   ...
[BOOT_TIME] ========================================
```

## Where Times Are Logged

1. **~/.zshbop.log** - All execution times always logged here
2. **Real-time debug output** - When `ZSH_DEBUG=1`, timing messages displayed on screen

## Viewing Execution Times

### View all execution times:
```bash
grep "EXEC_TIME" ~/.zshbop.log | tail -50
```

### View boot summary:
```bash
grep -A 20 "Boot Time Summary" ~/.zshbop.log | tail -1
```

### Enable real-time debug output:
```bash
touch $ZSHBOP_ROOT/.debug
# Then restart your shell or run: source ~/.zshrc
```

## Testing

```bash
zsh test-init-os-timing.zsh
```

This verifies:
- Execution timing entries are created correctly
- Microsecond precision is maintained (6 decimal places)
- Timing works correctly even when operations short-circuit
- The `_time_step` function properly wraps commands

## Performance Testing

Track performance changes over time:

```bash
# Baseline
grep "Total boot time" ~/.zshbop.log | tail -5

# Make changes...

# Compare
grep "Total boot time" ~/.zshbop.log | tail -5
```

Differences of even 0.01s (10 milliseconds) are detectable.

## Adding Timing to Your Code

### For Init Components
Use the existing boot timer pattern:

```zsh
function init_my_component() {
    # Your code here
    init_log  # Automatically tracks if _start_boot_timer was called
}

# In init_zshbop:
_start_boot_timer "init_my_component"; init_my_component
```

### For Any Function
Use `_time_step` for individual operations:

```zsh
function my_function() {
    _log "Starting my function"
    
    _time_step "step1" "my_function" do_step_1
    _time_step "step2" "my_function" do_step_2
    
    # Or manually:
    local start=$EPOCHREALTIME
    complex_operation
    _track_execution "complex_operation" "my_function" "$start"
}
```

## Technical Details

- Uses zsh's `zsh/datetime` module for `EPOCHREALTIME` variable
- All calculations preserve floating-point precision
- Output formatted with `printf "%.6f"` for consistent 6 decimal places
- Backward compatible with existing boot time tracking
- `[EXEC_TIME]` prefix for nested/runtime tracking
- `[BOOT_TIME]` prefix for boot summary and component-level tracking
- `_time_step` returns the exit code of the wrapped command

## Migration from Old Timing Code

**Old approach (repetitive):**
```zsh
local start=$EPOCHREALTIME
source /path/to/file.zsh
local elapsed=$(printf "%.6f" $((EPOCHREALTIME - start)))
_debug "Loaded file in ${elapsed}s"
echo "[BOOT_TIME]   context: file loaded in ${elapsed}s" >> "$ZB_LOG"
```

**New approach (one line):**
```zsh
_time_step "file.zsh" "context" source /path/to/file.zsh
```

This eliminates:
- Local variable declarations
- Manual time calculations
- Repetitive printf formatting
- Duplicate debug and log statements
