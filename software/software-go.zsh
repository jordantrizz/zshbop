# ==============================================================================
# Go software
# ==============================================================================

# ===============================================
# -- _check_go
# ===============================================
function _check_go () {
    _cmd_exists go
    if [[ $? == "1" ]]; then
        _error "go not installed, go required."
        return 1
    fi
}

# ===============================================
# -- gonzo
# ===============================================
help_software[gonzo]='Install Gonzo, a real-time log analysis terminal UI'
function software_gonzo () {
    if ! _check_go; then
        return 1
    fi
    go install github.com/control-theory/gonzo/cmd/gonzo@latest
}
