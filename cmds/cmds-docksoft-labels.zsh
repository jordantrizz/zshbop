# ==============================================================================
# -- _docksoft_gen_labels () - Generate Traefik Docker labels for a domain
# ==============================================================================
if [[ "${(t)help_docksoft}" != *association* ]]; then
    unset help_docksoft
    typeset -gA help_docksoft
fi
help_docksoft[gen-labels]='Generate Traefik Docker labels for a domain'
function _docksoft_gen_labels () {
    local -a opts_help opts_config opts_run
    local opt_name opt_port opt_network
    zparseopts -D -E -- \
        h=opts_help -help=opts_help \
        n:=opt_name -name:=opt_name \
        p:=opt_port -port:=opt_port \
        c=opts_config -config=opts_config \
        N:=opt_network -network:=opt_network \
        -run=opts_run

    if [[ -n $opts_help ]]; then
        echo "Usage: docksoft gen-labels [options] <domain>"
        echo ""
        echo "Generate Traefik Docker labels for a service domain."
        echo ""
        echo "Options:"
        echo "  -h, --help                  Show this help message"
        echo "  -n, --name <name>           Container/service name (default: first label of domain)"
        echo "  -p, --port <port>           Internal service port (default: 80)"
        echo "  -c, --config                Read network from docksoft config"
        echo "  -N, --network <network>     Docker network name (default: proxy)"
        echo "  --run                       Output docker run --label flags instead of YAML"
        echo ""
        echo "Examples:"
        echo "  docksoft gen-labels uptime.example.com -p 3001"
        echo "  docksoft gen-labels myapp.example.com -n myapp -p 8080 -c"
        echo "  docksoft gen-labels app.example.com -p 9000 --run"
        return 0
    fi

    if [[ $# -lt 1 ]]; then
        _error "Usage: docksoft gen-labels [options] <domain>"
        return 1
    fi

    local domain="$1"
    local name="${opt_name[-1]}"
    local port="${opt_port[-1]:-80}"
    local network="${opt_network[-1]:-proxy}"

    if [[ -n $opts_config ]]; then
        if [[ -f "$DOCKSOFT_CONF" ]]; then
            source "$DOCKSOFT_CONF"
            network="${DOCKSOFT_NETWORK:-$network}"
        else
            _warning "docksoft config not found at $DOCKSOFT_CONF; using defaults"
        fi
    fi

    if [[ -z "$name" ]]; then
        local label_count
        label_count=$(echo "$domain" | awk -F'.' '{print NF}')
        if (( label_count < 2 )); then
            _error "Domain '$domain' is not a valid FQDN"
            return 1
        fi
        if (( label_count == 2 )); then
            _error "Domain '$domain' has no subdomain label to derive a name. Use --name."
            return 1
        fi
        name="${domain%%.*}"
    fi

    if [[ -n $opts_run ]]; then
        echo "--label \"traefik.enable=true\""
        echo "--label \"traefik.http.routers.${name}.rule=Host(\`${domain}\`)\""
        echo "--label \"traefik.http.routers.${name}.entrypoints=websecure\""
        echo "--label \"traefik.http.routers.${name}.tls.certresolver=letsencrypt\""
        echo "--label \"traefik.http.services.${name}.loadbalancer.server.port=${port}\""
    else
        cat <<EOF
labels:
  - "traefik.enable=true"
  - "traefik.http.routers.${name}.rule=Host(\`${domain}\`)"
  - "traefik.http.routers.${name}.entrypoints=websecure"
  - "traefik.http.routers.${name}.tls.certresolver=letsencrypt"
  - "traefik.http.services.${name}.loadbalancer.server.port=${port}"

networks:
  ${network}:
    external: true
EOF
    fi
}
