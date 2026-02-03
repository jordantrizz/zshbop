#!/usr/bin/env zsh
# -----------------------------------------------------------------------------------
# -- checks-terminal.zsh -- Checks for terminal environment and IDE integrations
# -----------------------------------------------------------------------------------
_debug " -- Loading ${(%):-%N}"

# =============================================================================
# -- terminal-checks
# ===============================================
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

# ===============================================
# -- terminal-check-detect () - Detects terminal emulator environment
# ===============================================
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

# ===============================================
# -- terminal-check-vscode () - Enables VSCode shell integration
# ===============================================
help_checks[terminal-check-vscode]='Enables VSCode shell integration if available'
function terminal-check-vscode () {
    # VS Code automatically injects shell integration via VSCODE_SHELL_INTEGRATION
    # Manual loading can conflict with p10k prompt, so we skip it
    # If shell integration is needed, VS Code handles it automatically
    _debug "VSCode detected - shell integration handled by VS Code automatically"
}

# Run terminal checks on load
terminal-checks
