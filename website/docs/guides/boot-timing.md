---
title: Boot timing
description: The execution time tracking system in zshbop — microsecond precision, the _time_step wrapper, log format, and how to add timing to a function.
---

zshbop measures its own startup and any function call with microsecond precision (six decimal
places). Use it to find what makes a shell slow before changing anything.

## How it works

- Precision comes from zsh's `zsh/datetime` module and `$EPOCHREALTIME`.
- `_time_step` wraps a command: it runs it, times it, and returns the command's own exit code.
- Every measurement is appended to `~/.zshbop.log`.
- With debug on (`.debug` file, see [Debugging](./debugging.md)) the same lines also print on screen.

## Functions

`_time_step` is the one to reach for:

```zsh
_time_step "description" "context" command args...
```

```zsh
# Track sourcing a file
_time_step "os-common.zsh" "init_os" source $ZSHBOP_ROOT/cmds/os-common.zsh

# Track a function call
_time_step "init_wsl" "init_os" init_wsl
```

For work you cannot wrap in one command, time it by hand with `_track_execution`:

```zsh
local start_time=$EPOCHREALTIME
# ... do work ...
_track_execution "label" "context" "$start_time"
```

Component-level timing (the boot summary) uses `_start_boot_timer` and `init_log`:

```zsh
_start_boot_timer "init_my_component"; init_my_component

function init_my_component() {
    # work
    init_log   # records elapsed time when a boot timer was started
}
```

## Log format

Runtime and component measurements carry the `[EXEC_TIME]` prefix:

```text
[EXEC_TIME]   init_os: os-common.zsh took 0.002705s
[EXEC_TIME]   init_os: os-linux.zsh took 0.000986s
[EXEC_TIME] init_os took 0.004455s
```

The boot summary carries `[BOOT_TIME]`:

```text
[BOOT_TIME] ========================================
[BOOT_TIME] zshbop Boot Time Summary
[BOOT_TIME] ========================================
[BOOT_TIME] Total boot time: 3.456789s
[BOOT_TIME] Component breakdown:
[BOOT_TIME]   init_core: 0.234567s
[BOOT_TIME]   init_os: 0.004455s
[BOOT_TIME] ========================================
```

## Reading the numbers

```bash
# The last 50 measurements
grep "EXEC_TIME" ~/.zshbop.log | tail -50

# The most recent boot summary
grep -A 20 "Boot Time Summary" ~/.zshbop.log | tail -1

# Watch a change: take a baseline, change something, compare
grep "Total boot time" ~/.zshbop.log | tail -5
```

Differences of 10 milliseconds are visible, which is the point: a plugin that costs a fifth of a
second is worth knowing about.

## Testing the timer

```bash
zsh test-init-os-timing.zsh
```

The test verifies that entries are written, that precision stays at six decimal places, that
short-circuiting operations still time correctly, and that `_time_step` wraps commands and returns
their status.

## Technical notes

- The output is formatted with `printf "%.6f"` so every figure has the same width.
- `[EXEC_TIME]` marks nested and runtime timing; `[BOOT_TIME]` marks the boot summary and components.
- `_time_step` propagates the wrapped command's exit code, so wrapping something does not change how
  a caller detects failure.
