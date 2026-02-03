# AGENTS.md

## Project Notes
* Always create a git commit message for each change made, use the format feat, fix, docs, style, refactor, perf, test, chore.
* Use semantic versioning for releases, increment major, minor, patch as needed.
* Maintain a changelog for each release, documenting new features, bug fixes, and improvements.

## ZSH Development Notes
* Within ZSH using local within a loop will cause the variable to be echoed to stdout, so avoid using local in loops.
* Always use zparseopts for parsing options in functions.
* Always provide a one line git commit message when making a change, ensure you use feat:, fix:, docs:, style:, refactor:, perf:, test:, chore: as prefixes.

## File Naming Conventions
* Check files: `checks/checks-<environment>.zsh` (e.g., `checks-docker.zsh`, `checks-terminal.zsh`)
* Command files: `cmds/cmds-<category>.zsh` (e.g., `cmds-core.zsh`, `cmds-git.zsh`)
* Library files: `lib/<name>.zsh` (e.g., `lib/init.zsh`, `lib/functions.zsh`)

## Help Array Patterns
* Register functions in help arrays for discoverability:
  * `help_checks[function-name]='Description'` for check functions
  * `help_core[function-name]='Description'` for core commands
  * `help_<category>[function-name]='Description'` for category-specific commands

## Output Functions
* `_success "message"` - Green success message
* `_warning "message"` - Yellow warning message
* `_error "message"` - Red error message
* `_log "message"` - Standard log message
* `_debug "message"` - Debug message (shown when debug enabled)
* `_debugf "message"` - Debug message for function-level debugging with `zbdebug`
* `_loading "message"` - Loading/section header message

## Common Idioms
* Check if command exists: `(( $+commands[cmd] ))`
* Check if variable is set: `[[ -n "$VAR" ]]`
* Return success/failure: `return 0` (success), `return 1` (failure)

## Example Function Template
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

## Formatting Comments
* Standardize divider widths (count of `=` characters):
    * Major dividers (top-of-file / major sections): **77** `=`
        * Canonical: `# =============================================================================`
    * Section dividers (functions / subsections): **47** `=`
        * Canonical: `# ===============================================`
* Use the major divider for top-of-file headers and major file sections.
* Use the section divider for function blocks and subsections.
* Use `# -- function-name () - Brief description` for function headers.
* 