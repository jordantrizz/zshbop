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
            terminal-check-vscode
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

# Run terminal checks on load
terminal-checks
