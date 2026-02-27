# --
# docksoft - Docker software scaffolding
# --
_debug " -- Loading ${(%):-%N}"
help_files[docksoft]="Docker software scaffolding" # Help file description
if [[ "${(t)help_docksoft}" != *association* ]]; then
    unset help_docksoft
    typeset -gA help_docksoft
fi

# -- docksoft variables
DOCKSOFT_CONTAINERS="/root/containers"
DOCKSOFT_DATA="/srv/containers"
DOCKSOFT_NETWORK="proxy"
DOCKSOFT_TEMPLATES="${ZSHBOP_ROOT}/templates/docksoft"
DOCKSOFT_CONF="${DOCKSOFT_CONTAINERS}/.docksoft.conf"

# Host port tracking (persisted in $DOCKSOFT_CONF)
typeset -gA DOCKSOFT_PORTS

# -- docksoft modules (ordered by dependency)
[[ -f "${ZSHBOP_ROOT}/cmds/cmds-docksoft-core.zsh" ]] && source "${ZSHBOP_ROOT}/cmds/cmds-docksoft-core.zsh"
[[ -f "${ZSHBOP_ROOT}/cmds/cmds-docksoft-network.zsh" ]] && source "${ZSHBOP_ROOT}/cmds/cmds-docksoft-network.zsh"
[[ -f "${ZSHBOP_ROOT}/cmds/cmds-docksoft-ports.zsh" ]] && source "${ZSHBOP_ROOT}/cmds/cmds-docksoft-ports.zsh"
[[ -f "${ZSHBOP_ROOT}/cmds/cmds-docksoft-init.zsh" ]] && source "${ZSHBOP_ROOT}/cmds/cmds-docksoft-init.zsh"
[[ -f "${ZSHBOP_ROOT}/cmds/cmds-docksoft-deploy.zsh" ]] && source "${ZSHBOP_ROOT}/cmds/cmds-docksoft-deploy.zsh"
[[ -f "${ZSHBOP_ROOT}/cmds/cmds-docksoft-status.zsh" ]] && source "${ZSHBOP_ROOT}/cmds/cmds-docksoft-status.zsh"

# ==============================================================================
# -- _docksoft_usage () - Print docksoft usage
# ==============================================================================
function _docksoft_usage () {
    echo ""
    echo "Usage: docksoft <command> [options]"
    echo ""
    echo "Commands:"
    echo "  init                        Initialize docksoft (directories, network, config; type 'skip' to bypass config)"
    echo "  list                        List available container templates"
    echo "  config                      Show current docksoft configuration"
    echo "  traefik-status [-r|--raw]   Show Traefik routers, services, and certificate status"
    echo "  <container> [options]       Deploy a container from templates"
    echo ""
    echo "Options:"
    echo "  -h, --help                  Show this help message"
    echo "  -e, --email <email>         Override email for this deployment"
    echo "  -d, --domain <domain>       Override domain/FQDN for this deployment"
    echo ""
    echo "Modes (set during init):"
    echo "  single  - Server runs one service (domain used as-is)"
    echo "            e.g., uptime.ohmyhi.net -> uptime.ohmyhi.net"
    echo "  multi   - Server hosts multiple services (subdomain.domain)"
    echo "            e.g., docker01.example.com -> uptime.docker01.example.com"
    echo ""
    echo "Examples:"
    echo "  docksoft init"
    echo "  docksoft list"
    echo "  docksoft traefik"
    echo "  docksoft uptime-kuma"
    echo "  docksoft n8n"
    echo "  docksoft dashy"
    echo "  docksoft zerobyte"
    echo "  docksoft watchtower"
    echo "  docksoft uptime-kuma --domain custom.example.com   # override FQDN"
    echo ""
    _docksoft_list
}

# ==============================================================================
# -- docksoft () - Docker software scaffolding tool
# ==============================================================================
help_docksoft[docksoft]='Docker software container scaffolding tool'
function docksoft () {
    local -a opts_help
    zparseopts -D -E -- h=opts_help -help=opts_help

    if [[ -n $opts_help ]]; then
        _docksoft_usage
        return 0
    fi

    if [[ -z "$1" ]]; then
        _docksoft_usage
        return 0
    fi

    local subcmd="$1"
    shift

    case "$subcmd" in
        init)
            _docksoft_init
            ;;
        list)
            _docksoft_list
            ;;
        config)
            _docksoft_show_config
            ;;
        traefik-status)
            _docksoft_traefik_status "$@"
            ;;
        help)
            _docksoft_usage
            ;;
        *)
            _docksoft_deploy "$subcmd" "$@"
            ;;
    esac
}
