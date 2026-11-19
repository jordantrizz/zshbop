---
title: Debugging
description: How to turn on zshbop debugging, read help-array and load messages, generate an antidote report, and diagnose mise/uvx.
---

## Function-level debugging

`zbdebug` prints the `_debugf` messages of the functions it runs. Inside a function, `_debugf` writes
the argument plus the call stack:

```zsh
zbdebug os-binary
** [DEBUG]: No binary specified
```

That line comes from `_debugf "No binary specified"` inside `os-binary`; the function keeps running
normally.

## Debug mode

Debug output is controlled by two marker files in the zshbop root, not by an environment variable:

| File | Effect |
|------|--------|
| `$ZSHBOP_ROOT/.debug` | `ZSH_DEBUG=1` — debug messages on screen |
| `$ZSHBOP_ROOT/.debug_log` | `ZSH_DEBUG_LOG=1` — debug messages to the log |

```bash
touch "$ZSHBOP_ROOT/.debug"
# restart the shell, or:
zbr
zbdebug          # shows the current debug state
```

Remove the file (or reload after removing it) to turn debugging off again.

## Startup report

Initialization collects errors and warnings instead of scattering them across the screen:

```bash
zb report      # or: report
```

## Antidote debug report

`antidote-debug` writes a full runtime report for antidote, auto-ls, widget bindings, and shell init
state.

```bash
antidote-debug                                  # $ZSHBOP_ROOT/debug/antidote-debug-YYYYmmdd-HHMMSS.log
antidote-debug -o /tmp/antidote-debug.log       # custom path
antidote-debug -h                               # help
```

## mise / uvx

If `mise list` shows `uv` but other tools cannot find `uvx`:

```bash
mise-uvx-check
```

It validates that `uvx` is active in `mise`, that `~/bin/uvx` is symlinked correctly, and that `uvx`
executes.

## Update and repository sync output

The update flow prints one line per repository and hides git's progress output. When a sync fails and
the one-line reason is not enough:

```bash
ZSHBOP_UPDATE_VERBOSE=1 zbu
zb update-status -l
```

## See also

- [Boot timing](./boot-timing.md) — measure where startup time goes.
- [Configuration](../reference/configuration.md) — the switches used above.
