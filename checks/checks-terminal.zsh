#!/usr/bin/env zsh
# -----------------------------------------------------------------------------------
# -- checks-terminal.zsh -- Checks for terminal environment and IDE integrations
# -----------------------------------------------------------------------------------
_debug " -- Loading ${(%):-%N}"

# ==================================================
# -- terminal-checks
# ==================================================
help_checks[terminal-checks]='Run all checks for terminal environment'
function terminal-checks () {
    terminal-check-detect
    
    # Run IDE-specific integrations
    case "$ZSHBOP_TERMINAL" in
        vscode)
            if [[ "$ZSHBOP_DISABLE_VSCODE_SHELL" == "1" ]]; then
                terminal-disable-vscode-shell
            else
                terminal-check-vscode
            fi
            ;;
    esac
}

# ==================================================
# -- terminal-check-detect () - Detects terminal emulator environment
# ==================================================
help_checks[terminal-check-detect]='Detects terminal emulator environment'
function terminal-check-detect () {
    # Default to unknown
    export ZSHBOP_TERMINAL="unknown"
    
    # Detect based on TERM_PROGRAM or other environment variables
    if [[ -n "$TERM_PROGRAM" ]]; then
        case "$TERM_PROGRAM" in
            vscode)
                ZSHBOP_TERMINAL="vscode"
                ;;
            iTerm.app)
                ZSHBOP_TERMINAL="iterm"
                ;;
            WezTerm)
                ZSHBOP_TERMINAL="wezterm"
                ;;
            Apple_Terminal)
                ZSHBOP_TERMINAL="apple-terminal"
                ;;
            tmux)
                ZSHBOP_TERMINAL="tmux"
                ;;
            *)
                ZSHBOP_TERMINAL="$TERM_PROGRAM"
                ;;
        esac
    elif [[ -n "$WT_SESSION" ]]; then
        # Windows Terminal detection
        ZSHBOP_TERMINAL="windows-terminal"
    elif [[ -n "$VSCODE_IPC_HOOK_CLI" ]]; then
        # VSCode Remote-SSH detection (TERM_PROGRAM may not be set)
        ZSHBOP_TERMINAL="vscode"
    fi
    
    _debug "Terminal detected: $ZSHBOP_TERMINAL"
}

# ==================================================
# -- terminal-check-vscode () - Enables VSCode shell integration
# ==================================================
help_checks[terminal-check-vscode]='Enables VSCode shell integration if available'
function terminal-check-vscode () {
    # Allow users to opt out of VSCode shell integration (prompt or env conflicts)
    if [[ "$ZSHBOP_DISABLE_VSCODE_SHELL" == "1" ]]; then
        _debug "Skipping VSCode shell integration (ZSHBOP_DISABLE_VSCODE_SHELL=1)"
        return 0
    fi

    # Check if code command is available or if we're in a VSCode IPC session
    if (( $+commands[code] )); then
        # code command available, use it to locate shell integration
        local integration_path
        integration_path="$(code --locate-shell-integration-path zsh 2>/dev/null)"
        if [[ -n "$integration_path" && -f "$integration_path" ]]; then
            source "$integration_path"
            _debug "VSCode shell integration loaded from: $integration_path"
        else
            _debug "VSCode shell integration path not found"
        fi
    elif [[ -n "$VSCODE_IPC_HOOK_CLI" ]]; then
        # In VSCode terminal but code command not in PATH (e.g., Remote-SSH)
        # Try common integration paths
        local integration_paths=(
            "${HOME}/.vscode-server/bin/"*"/out/vs/workbench/contrib/terminal/common/scripts/shellIntegration-rc.zsh"
            "${HOME}/.vscode-server/bin/"*"/out/vs/workbench/contrib/terminal/browser/media/shellIntegration-rc.zsh"
        )
        for path in $integration_paths; do
            if [[ -f "$path" ]]; then
                source "$path"
                _debug "VSCode shell integration loaded from: $path"
                return 0
            fi
        done
        _debug "VSCode detected but shell integration not found (Remote-SSH session)"
    fi
}

# ==================================================
# -- terminal-disable-vscode-shell () - Remove VSCode shell integration side effects
# ==================================================
help_checks[terminal-disable-vscode-shell]='Disable VSCode shell integration when requested'
function terminal-disable-vscode-shell () {
    _debug "Disabling VSCode shell integration per ZSHBOP_DISABLE_VSCODE_SHELL=1"

    # Clear VSCode shell integration markers so downstream logic won’t re-enable it
    unset VSCODE_SHELL_INTEGRATION
    unset VSCODE_SHELL_INTEGRATION_VERSION

    # Remove VSCode prompt hooks if they were already loaded
    local hook
    for hook in precmd_functions preexec_functions chpwd_functions; do
        if typeset -p $hook &>/dev/null; then
            local -a arr
            eval "arr=(\${${hook}})"
            arr=(${arr:#__vscode_*})
            arr=(${arr:#vscode_*})
            arr=(${arr:#__vscodeshell*})
            eval "$hook=(\${arr})"
        fi
    done

    # Restore p10k prompt if available
    if (( ${+functions[prompt_powerlevel10k_setup]} )); then
        prompt_powerlevel10k_setup
    elif (( ${+functions[p10k]} )); then
        p10k reload
    fi
}

# Run terminal checks on load
terminal-checks
