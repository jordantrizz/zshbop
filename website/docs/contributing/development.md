---
title: Development
description: The conventions for changing zshbop — Zsh rules, file naming, help arrays, output functions, and the function template.
---

## Project notes

- Auto-commit and push after every change. Do not wait to be asked; print the commit message when
  finishing.
- Maintain a changelog for each release: new features, bug fixes, and improvements.
- Do not create test files such as bash or PHP scripts in the main codebase; the test scripts live in
  `tests/` and stay in Zsh.

## Zsh rules

### Never use `local` inside a loop

`local` is a builtin that both declares *and* assigns, and inside a loop every iteration echoes the
assigned value to stdout. That corrupts command output and breaks callers that capture it. The same
applies to `typeset`.

```zsh
# BAD — leaks "v=..." to stdout on every iteration
for f in "${files[@]}"; do
    local v=$(grep "pattern" "$f")
done

# GOOD — declare local before the loop
local f v
for f in "${files[@]}"; do
    v=$(grep "pattern" "$f")
done
```

### Parse options with `zparseopts`

Every function that takes options uses `zparseopts`, including a help flag.

## Layout and naming

| Kind | Path |
|------|------|
| Environment checks | `checks/checks-<environment>.zsh` (`checks-docker.zsh`, `checks-terminal.zsh`, …) |
| Commands | `cmds/cmds-<category>.zsh` (`cmds-core.zsh`, `cmds-git.zsh`, …) |
| Libraries | `lib/<name>.zsh` (`lib/init.zsh`, `lib/functions.zsh`, …) |
| Tests | `tests/test-<feature>.zsh` |
| Knowledge base | `kb/<article>.md` |

## Help arrays

Every function is registered so it can be discovered:

| Array | For |
|-------|-----|
| `help_checks[function-name]='Description'` | check functions |
| `help_core[function-name]='Description'` | core commands |
| `help_<category>[function-name]='Description'` | category commands |

`help <category>` reads these arrays, and the generated command reference is built from them. A
function without an entry is invisible in both.

## Output functions

| Function | Use |
|----------|-----|
| `_success "message"` | green success message |
| `_warning "message"` | yellow warning |
| `_error "message"` | red error |
| `_log "message"` | standard log line |
| `_debug "message"` | debug message, shown when debug is enabled |
| `_debugf "message"` | function-level debug, printed by `zbdebug` |
| `_loading "message"` | loading and section header |

## Common idioms

```zsh
(( $+commands[cmd] ))        # is a command available?
[[ -n "$VAR" ]]              # is a variable set?
return 0                     # success
return 1                     # failure
```

## Function template

```zsh
# ==================================================
# -- example-function () - Brief description
# ==================================================
help_checks[example-function]='Brief description of what this function does'
function example-function () {
    # Parse options with zparseopts
    local -a opts_help opts_verbose
    zparseopts -D -E -- h=opts_help -help=opts_help v=opts_verbose -verbose=opts_verbose

    if [[ -n $opts_help ]]; then
        echo "Usage: example-function [-h|--help] [-v|--verbose] <arg>"
        return 0
    fi

    # Check if required command exists
    if (( $+commands[required-cmd] )); then
        _success "Required command found"
    else
        _warning "Required command not installed"
        return 1
    fi

    _debug "Processing with arg: $1"
    # Function logic here
}
```

## Internal function comments

Put a banner above each internal function:

```zsh
# ==============================================
# -- init_mise - activate mise runtime manager if present
# ==============================================
```

Add a second line when the name alone does not explain it:

```zsh
# ==============================================
# -- _init_mise_ensure_uvx_symlink
# -- Ensure that if mise is present and uvx is available, we have a ~/bin/uvx symlink
# ==============================================
```

## See also

- [Documentation](./documentation.md) — the docs contract: generated pages, front matter, and the gate.
- [Testing](./testing.md) — the test scripts and how to run them.
- [Boot timing](../guides/boot-timing.md) — the timing wrapper for new initialization code.
- [Debugging](../guides/debugging.md) — `_debugf`, `zbdebug`, and the debug files.
