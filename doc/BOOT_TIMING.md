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
A test script is provided to verify microsecond precision:
```bash
zsh test-boot-timing.zsh
```

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

## Technical Details
- Uses zsh's `zsh/datetime` module for `EPOCHREALTIME` variable
- All calculations preserve floating-point precision
- Output formatted with `printf "%.6f"` for consistent 6 decimal places
- Maintains backward compatibility with existing log parsers (still uses `[BOOT_TIME]` prefix)
