# Boot Timing with Microsecond Precision

## Overview
Starting with this update, zshbop records boot times with microsecond precision (6 decimal places) instead of whole seconds. This allows for better performance tracking and regression detection for sub-second changes.

## What Changed
Previously, boot times were recorded using `$SECONDS`, which only provides whole-second precision:
```
[BOOT_TIME] Boot time: init_core took 1s
[BOOT_TIME] Total boot time: 5s
```

Now, boot times use `$EPOCHREALTIME` for microsecond precision:
```
[BOOT_TIME] Boot time: init_core took 0.234567s
[BOOT_TIME] Total boot time: 3.456789s
```

## Reading the New Format
The timing format is: `X.XXXXXXs` (6 decimal places)

Examples:
- `0.000123s` = 123 microseconds
- `0.001234s` = 1.234 milliseconds  
- `1.234567s` = 1.234567 seconds
- `10.123456s` = 10.123456 seconds

## Where Boot Times Are Logged
Boot timing information is logged in two places:

1. **~/.zshbop.log** - All boot times are always logged here with the `[BOOT_TIME]` prefix
2. **Real-time debug output** - When `ZSH_DEBUG=1`, timing messages are also displayed on screen

## Viewing Boot Times

### View all boot times in the log:
```bash
grep "BOOT_TIME" ~/.zshbop.log | tail -50
```

### View just the summary:
```bash
grep -A 20 "Boot Time Summary" ~/.zshbop.log | tail -1
```

### Enable real-time debug output:
```bash
touch $ZSHBOP_ROOT/.debug
# Then restart your shell or run: source ~/.zshrc
```

## Testing
Test scripts are provided to verify microsecond precision and component timing:

### General Boot Timing Test
```bash
zsh test-boot-timing.zsh
```

### init_os Timing Test
```bash
zsh test-init-os-timing.zsh
```

This test verifies that:
- Boot timing entries are created for all OS-specific loading steps
- Microsecond precision is maintained (6 decimal places)
- Timing works correctly even when detection short-circuits
- Nested timing for complex configurations (like WSL) is tracked properly

## Performance Testing
To test for regressions:

1. Record baseline boot times:
   ```bash
   grep "Total boot time" ~/.zshbop.log | tail -5
   ```

2. Make changes to your configuration

3. Compare new boot times:
   ```bash
   grep "Total boot time" ~/.zshbop.log | tail -5
   ```

4. Differences of even 0.01s (10 milliseconds) are now detectable

## Component-Specific Timing

### init_os Detailed Timing
The `init_os` function now includes detailed timing for each OS-specific loading step:

```
[BOOT_TIME]   init_os: os-common.zsh loaded in 0.012345s
[BOOT_TIME]   init_os: os-linux.zsh loaded in 0.023456s
[BOOT_TIME] Boot time: init_os took 0.035801s
```

For WSL configurations, you'll see nested timing:
```
[BOOT_TIME]   init_os: os-common.zsh loaded in 0.012345s
[BOOT_TIME]   init_os: os-linux.zsh (WSL) loaded in 0.023456s
[BOOT_TIME]   init_os: os-wsl.zsh loaded in 0.015678s
[BOOT_TIME]   init_os: init_wsl completed in 0.003456s
[BOOT_TIME]   init_os: WSL configuration total time 0.042590s
[BOOT_TIME] Boot time: init_os took 0.054935s
```

This nested timing helps identify slow OS-specific scripts or configuration steps.

## Technical Details
- Uses zsh's `zsh/datetime` module for `EPOCHREALTIME` variable
- All calculations preserve floating-point precision
- Output formatted with `printf "%.6f"` for consistent 6 decimal places
- Maintains backward compatibility with existing log parsers (still uses `[BOOT_TIME]` prefix)
- Component-level timing tracked via `_start_boot_timer` and `init_log`
- Nested sub-component timing logged directly to maintain visibility into slow steps
