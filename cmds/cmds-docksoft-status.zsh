# ==============================================================================
# -- _docksoft_traefik_status () - Compatibility wrapper for traefik-status
# ==============================================================================
if [[ "${(t)help_docksoft}" != *association* ]]; then
    unset help_docksoft
    typeset -gA help_docksoft
fi
help_docksoft[traefik-status]='Alias for traefik-status'
function _docksoft_traefik_status () {
    if (( ! $+functions[traefik-status] )); then
        _error "traefik-status command is not available"
        return 1
    fi

    traefik-status "$@"
}
