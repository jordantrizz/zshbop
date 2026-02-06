# --
# docksoft - Docker software scaffolding
# --
_debug " -- Loading ${(%):-%N}"
help_files[docksoft]="Docker software scaffolding" # Help file description
typeset -gA help_docksoft # Init help array.

# -- docksoft variables
DOCKSOFT_CONTAINERS="/root/containers"
DOCKSOFT_DATA="/srv/containers"
DOCKSOFT_NETWORK="proxy"
DOCKSOFT_TEMPLATES="${ZSHBOP_ROOT}/templates/docksoft"

# ==============================================================================
# -- _docksoft_usage () - Print docksoft usage
# ==============================================================================
function _docksoft_usage () {
    echo ""
    echo "Usage: docksoft <command> [options]"
    echo ""
    echo "Commands:"
    echo "  init                        Initialize docksoft directories and Docker network"
    echo "  list                        List available container templates"
    echo "  traefik-status [-r|--raw]   Show Traefik routers, services, and certificate status"
    echo "  <container> [options]       Deploy a container from templates"
    echo ""
    echo "Options:"
    echo "  -h, --help                  Show this help message"
    echo "  -e, --email <email>         Email for Let's Encrypt / ACME (used by traefik)"
    echo "  -d, --domain <domain>       Domain name (used by templates with {{DOMAIN}})"
    echo ""
    echo "Examples:"
    echo "  docksoft init"
    echo "  docksoft list"
    echo "  docksoft traefik --email admin@example.com"
    echo "  docksoft uptime-kuma"
    echo ""
    _docksoft_list
}

# ==============================================================================
# -- _docksoft_list () - List available container templates
# ==============================================================================
function _docksoft_list () {
    _loading "Available container templates:"
    if [[ ! -d "$DOCKSOFT_TEMPLATES" ]]; then
        _warning "Templates directory not found: $DOCKSOFT_TEMPLATES"
        return 1
    fi

    local found=0
    for tpl_dir in "$DOCKSOFT_TEMPLATES"/*(N/); do
        local tpl_name="${tpl_dir:t}"
        _loading3 "$tpl_name"
        found=1
    done

    if [[ $found -eq 0 ]]; then
        _warning "No container templates found in $DOCKSOFT_TEMPLATES"
    fi
}

# ==============================================================================
# -- _docksoft_init () - Initialize docksoft directories and network
# ==============================================================================
function _docksoft_init () {
    _loading "Initializing docksoft environment"

    # -- Check if Docker is installed
    if (( ! $+commands[docker] )); then
        _error "Docker is not installed. Please install Docker first."
        return 1
    fi

    # -- Check Docker socket
    local DOCKER_SOCK="/var/run/docker.sock"
    if [[ ! -e "$DOCKER_SOCK" ]]; then
        _warning "Docker socket not found at $DOCKER_SOCK"
        _loading2 "Checking if Docker uses a non-default socket..."
        local DOCKER_HOST_SOCK=$(docker context inspect --format '{{.Endpoints.docker.Host}}' 2>/dev/null)
        if [[ -n "$DOCKER_HOST_SOCK" ]]; then
            _loading3 "Docker socket found via context: $DOCKER_HOST_SOCK"
            DOCKER_SOCK="${DOCKER_HOST_SOCK#unix://}"
        else
            _error "Docker socket not found. Ensure Docker daemon is running."
            return 1
        fi
    fi

    if [[ ! -r "$DOCKER_SOCK" ]] || [[ ! -w "$DOCKER_SOCK" ]]; then
        _warning "Current user may not have permission to access $DOCKER_SOCK"
        _loading3 "Consider adding your user to the docker group: sudo usermod -aG docker \$USER"
    fi

    # -- Check Docker daemon is responsive
    if ! docker info &>/dev/null; then
        _error "Docker daemon is not responding. Ensure Docker is running: sudo systemctl start docker"
        return 1
    fi
    _success "Docker daemon is running and socket is accessible"

    # -- Check Docker socket is bind-mountable (required for Traefik)
    _loading2 "Docker socket: $DOCKER_SOCK"
    _loading3 "Traefik will mount this socket read-only for container discovery"

    # -- Create containers directory
    if [[ -d "$DOCKSOFT_CONTAINERS" ]]; then
        _warning "Containers directory already exists: $DOCKSOFT_CONTAINERS"
    else
        _loading2 "Creating containers directory: $DOCKSOFT_CONTAINERS"
        mkdir -p "$DOCKSOFT_CONTAINERS"
        if [[ $? -eq 0 ]]; then
            _success "Created $DOCKSOFT_CONTAINERS"
        else
            _error "Failed to create $DOCKSOFT_CONTAINERS"
            return 1
        fi
    fi

    # -- Create data directory
    if [[ -d "$DOCKSOFT_DATA" ]]; then
        _warning "Data directory already exists: $DOCKSOFT_DATA"
    else
        _loading2 "Creating data directory: $DOCKSOFT_DATA"
        mkdir -p "$DOCKSOFT_DATA"
        if [[ $? -eq 0 ]]; then
            _success "Created $DOCKSOFT_DATA"
        else
            _error "Failed to create $DOCKSOFT_DATA"
            return 1
        fi
    fi

    # -- Create proxy Docker network
    if docker network inspect "$DOCKSOFT_NETWORK" &>/dev/null; then
        _warning "Docker network '$DOCKSOFT_NETWORK' already exists"
    else
        _loading2 "Creating Docker network: $DOCKSOFT_NETWORK"
        docker network create "$DOCKSOFT_NETWORK"
        if [[ $? -eq 0 ]]; then
            _success "Created Docker network '$DOCKSOFT_NETWORK'"
        else
            _error "Failed to create Docker network '$DOCKSOFT_NETWORK'"
            return 1
        fi
    fi

    _success "docksoft environment initialized"
}

# ==============================================================================
# -- _docksoft_deploy () - Deploy a container from template
# ==============================================================================
function _docksoft_deploy () {
    local container_name="$1"
    shift

    # -- Parse deploy options
    local -a opts_email opts_domain
    zparseopts -D -E -- e:=opts_email -email:=opts_email d:=opts_domain -domain:=opts_domain

    local email="" domain=""
    [[ -n $opts_email ]] && email="${opts_email[-1]}"
    [[ -n $opts_domain ]] && domain="${opts_domain[-1]}"

    _loading "Deploying container: $container_name"

    # -- Check if Docker is installed
    if (( ! $+commands[docker] )); then
        _error "Docker is not installed. Please install Docker first."
        return 1
    fi

    # -- Check if init has been run
    if [[ ! -d "$DOCKSOFT_CONTAINERS" ]] || [[ ! -d "$DOCKSOFT_DATA" ]]; then
        _error "docksoft has not been initialized. Run 'docksoft init' first."
        return 1
    fi

    # -- Check if template exists
    if [[ ! -d "$DOCKSOFT_TEMPLATES/$container_name" ]]; then
        _error "No template found for '$container_name'"
        _loading2 "Run 'docksoft list' to see available templates"
        return 1
    fi

    # -- Check if traefik is deployed (required for all containers except traefik itself)
    if [[ "$container_name" != "traefik" ]] && [[ ! -d "$DOCKSOFT_CONTAINERS/traefik" ]]; then
        _error "Traefik is not deployed. Deploy traefik first: docksoft traefik"
        return 1
    fi

    # -- Check if container already exists
    if [[ -d "$DOCKSOFT_CONTAINERS/$container_name" ]]; then
        _warning "Container '$container_name' already exists at $DOCKSOFT_CONTAINERS/$container_name"
        return 1
    fi

    # -- Copy template to containers directory
    _loading2 "Copying template to $DOCKSOFT_CONTAINERS/$container_name"
    cp -r "$DOCKSOFT_TEMPLATES/$container_name" "$DOCKSOFT_CONTAINERS/$container_name"
    if [[ $? -ne 0 ]]; then
        _error "Failed to copy template for '$container_name'"
        return 1
    fi

    # -- Handle {{EMAIL}} placeholder
    if grep -rq '{{EMAIL}}' "$DOCKSOFT_CONTAINERS/$container_name/" 2>/dev/null; then
        if [[ -z "$email" ]]; then
            _loading3 "Template contains {{EMAIL}} placeholder"
            read "email?Enter email address for this container (e.g. admin@example.com): "
            if [[ -z "$email" ]]; then
                _warning "No email provided. {{EMAIL}} placeholders left unchanged — edit manually."
            fi
        fi
        if [[ -n "$email" ]]; then
            find "$DOCKSOFT_CONTAINERS/$container_name" -type f -exec sed -i "s/{{EMAIL}}/$email/g" {} +
            _loading3 "Replaced {{EMAIL}} with $email"
        fi
    fi

    # -- Handle {{DOMAIN}} placeholder
    if grep -rq '{{DOMAIN}}' "$DOCKSOFT_CONTAINERS/$container_name/" 2>/dev/null; then
        if [[ -z "$domain" ]]; then
            _loading3 "Template contains {{DOMAIN}} placeholder"
            read "domain?Enter domain name for this container (e.g. example.com): "
            if [[ -z "$domain" ]]; then
                _warning "No domain provided. {{DOMAIN}} placeholders left unchanged — edit manually."
            fi
        fi
        if [[ -n "$domain" ]]; then
            find "$DOCKSOFT_CONTAINERS/$container_name" -type f -exec sed -i "s/{{DOMAIN}}/$domain/g" {} +
            _loading3 "Replaced {{DOMAIN}} with $domain"
        fi
    fi

    # -- Create data directory
    _loading2 "Creating data directory: $DOCKSOFT_DATA/$container_name/data"
    mkdir -p "$DOCKSOFT_DATA/$container_name/data"

    # -- Run post-deploy script if it exists
    if [[ -f "$DOCKSOFT_CONTAINERS/$container_name/post-deploy.zsh" ]]; then
        _loading2 "Running post-deploy script"
        source "$DOCKSOFT_CONTAINERS/$container_name/post-deploy.zsh"
        # Remove post-deploy script from deployed container
        rm -f "$DOCKSOFT_CONTAINERS/$container_name/post-deploy.zsh"
    fi

    _success "Container '$container_name' deployed to $DOCKSOFT_CONTAINERS/$container_name"
    _loading2 "To start: cd $DOCKSOFT_CONTAINERS/$container_name && docker compose up -d"
}

# ==============================================================================
# -- _docksoft_traefik_status () - Show Traefik status from API
# ==============================================================================
help_docksoft[traefik-status]='Show Traefik routers, services, and entrypoints status'
function _docksoft_traefik_status () {
    local -a opts_help opts_raw
    zparseopts -D -E -- h=opts_help -help=opts_help r=opts_raw -raw=opts_raw

    if [[ -n $opts_help ]]; then
        echo "Usage: docksoft traefik-status [-h|--help] [-r|--raw]"
        echo "  -r, --raw    Show raw JSON output"
        return 0
    fi

    # -- Check if traefik container is running
    if ! docker ps --format '{{.Names}}' | grep -q '^traefik$'; then
        _error "Traefik container is not running"
        return 1
    fi

    # -- Determine which HTTP client is available inside the container
    local TRAEFIK_API="http://localhost:8080/api"
    local HTTP_CMD=""
    if docker exec traefik which wget &>/dev/null; then
        HTTP_CMD="wget -qO-"
    elif docker exec traefik which curl &>/dev/null; then
        HTTP_CMD="curl -sf"
    else
        # Traefik v3 alpine image has wget; fallback to /dev/tcp via shell
        _error "No HTTP client (wget/curl) found in traefik container"
        _loading2 "Trying host-side curl..."
        # Check if port 8080 is published or reachable
        if (( $+commands[curl] )); then
            local TRAEFIK_IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' traefik 2>/dev/null | head -1)
            if [[ -n "$TRAEFIK_IP" ]]; then
                HTTP_CMD="_host_curl"
                TRAEFIK_API="http://${TRAEFIK_IP}:8080/api"
            else
                _error "Cannot determine traefik container IP"
                return 1
            fi
        else
            _error "curl not available on host either"
            return 1
        fi
    fi

    # -- Helper for host-side curl
    function _host_curl () {
        curl -sf "$@"
    }

    # -- Fetch function: runs inside container or on host
    function _traefik_api_get () {
        local endpoint="$1"
        if [[ "$HTTP_CMD" == "_host_curl" ]]; then
            curl -sf "${TRAEFIK_API}${endpoint}"
        else
            docker exec traefik $HTTP_CMD "${TRAEFIK_API}${endpoint}"
        fi
    }

    # -- Raw mode
    if [[ -n $opts_raw ]]; then
        _loading "Traefik API - Raw Overview"
        _traefik_api_get "/overview"
        echo ""
        _loading "Traefik API - Raw HTTP Routers"
        _traefik_api_get "/http/routers"
        echo ""
        _loading "Traefik API - Raw HTTP Services"
        _traefik_api_get "/http/services"
        echo ""
        return 0
    fi

    # -- Overview
    _loading "Traefik Status"
    local overview=$(_traefik_api_get "/overview" 2>/dev/null)
    if [[ -z "$overview" ]]; then
        _error "Failed to query Traefik API. Is the API enabled (api.insecure: true) in traefik.yml?"
        return 1
    fi

    # -- Check for jq
    if (( ! $+commands[jq] )); then
        _warning "jq not installed — showing raw JSON output"
        _loading2 "Overview:"
        echo "$overview"
        _loading2 "HTTP Routers:"
        _traefik_api_get "/http/routers"
        echo ""
        _loading2 "HTTP Services:"
        _traefik_api_get "/http/services"
        echo ""
        return 0
    fi

    # -- Parse overview
    _loading2 "Entrypoints"
    local ep_names=$(echo "$overview" | jq -r '.entryPoints // {} | keys[]' 2>/dev/null)
    if [[ -n "$ep_names" ]]; then
        echo "$ep_names" | while IFS= read -r ep; do
            local ep_addr=$(echo "$overview" | jq -r ".entryPoints.\"$ep\".address // \"unknown\"" 2>/dev/null)
            _loading3 "$ep -> $ep_addr"
        done
    else
        _loading3 "No entrypoints found"
    fi

    local router_total=$(echo "$overview" | jq -r '.http.routers.total // 0' 2>/dev/null)
    local router_errors=$(echo "$overview" | jq -r '.http.routers.errors // 0' 2>/dev/null)
    local router_warnings=$(echo "$overview" | jq -r '.http.routers.warnings // 0' 2>/dev/null)
    local svc_total=$(echo "$overview" | jq -r '.http.services.total // 0' 2>/dev/null)
    local svc_errors=$(echo "$overview" | jq -r '.http.services.errors // 0' 2>/dev/null)
    local svc_warnings=$(echo "$overview" | jq -r '.http.services.warnings // 0' 2>/dev/null)

    # -- Fallback: if values are empty, default to 0
    [[ -z "$router_total" ]] && router_total=0
    [[ -z "$router_errors" ]] && router_errors=0
    [[ -z "$router_warnings" ]] && router_warnings=0
    [[ -z "$svc_total" ]] && svc_total=0
    [[ -z "$svc_errors" ]] && svc_errors=0
    [[ -z "$svc_warnings" ]] && svc_warnings=0

    _loading3 "HTTP Routers: $router_total total, $router_errors errors, $router_warnings warnings"
    _loading3 "HTTP Services: $svc_total total, $svc_errors errors, $svc_warnings warnings"

    if [[ "$router_errors" -gt 0 ]] || [[ "$svc_errors" -gt 0 ]]; then
        _warning "Errors detected in Traefik configuration"
    fi

    # -- HTTP Routers
    _loading2 "HTTP Routers"
    local routers=$(_traefik_api_get "/http/routers" 2>/dev/null)
    if [[ -n "$routers" ]]; then
        echo "$routers" | jq -r '.[] | "  [\(.status // "unknown")] \(.name) -> \(.rule // "no rule") (entryPoints: \(.entryPoints // ["none"] | join(", ")))"' 2>/dev/null
    else
        _loading3 "No HTTP routers found"
    fi

    # -- HTTP Services
    _loading2 "HTTP Services"
    local services=$(_traefik_api_get "/http/services" 2>/dev/null)
    if [[ -n "$services" ]]; then
        echo "$services" | jq -r '.[] | "  [\(.status // "unknown")] \(.name) (type: \(.type // "unknown"))"' 2>/dev/null
    else
        _loading3 "No HTTP services found"
    fi

    # -- TLS Certificates
    _loading2 "TLS Certificates (ACME)"
    if [[ -f "$DOCKSOFT_CONTAINERS/traefik/acme.json" ]]; then
        local cert_count=$(jq '[.letsencrypt.Certificates // [] | length] | add // 0' "$DOCKSOFT_CONTAINERS/traefik/acme.json" 2>/dev/null)
        if [[ "$cert_count" -gt 0 ]]; then
            jq -r '.letsencrypt.Certificates[] | "  \(.domain.main) (SANs: \(.domain.sans // ["none"] | join(", ")))"' "$DOCKSOFT_CONTAINERS/traefik/acme.json" 2>/dev/null
        else
            _loading3 "No certificates issued yet"
        fi
    else
        _loading3 "acme.json not found at $DOCKSOFT_CONTAINERS/traefik/acme.json"
    fi

    # -- Container health
    _loading2 "Traefik Container"
    local container_status=$(docker inspect --format '{{.State.Status}}' traefik 2>/dev/null)
    local container_uptime=$(docker inspect --format '{{.State.StartedAt}}' traefik 2>/dev/null)
    local container_image=$(docker inspect --format '{{.Config.Image}}' traefik 2>/dev/null)
    _loading3 "Image: $container_image"
    _loading3 "Status: $container_status"
    _loading3 "Started: $container_uptime"

    # -- Recent logs (last 10 lines of errors)
    _loading2 "Recent Errors (last 10)"
    local error_logs=$(docker logs traefik --tail 50 2>&1 | grep -i 'level=error\|ERR\|error' | tail -10)
    if [[ -n "$error_logs" ]]; then
        echo "$error_logs"
        # -- Detect common issues and provide hints
        if echo "$error_logs" | grep -q 'client version.*is too old\|API version'; then
            echo ""
            _warning "Docker API version mismatch detected!"
            local host_api=$(docker version --format '{{.Server.APIVersion}}' 2>/dev/null)
            local traefik_image=$(docker inspect --format '{{.Config.Image}}' traefik 2>/dev/null)
            _loading3 "Host Docker API version: ${host_api:-unknown}"
            _loading3 "Traefik image: ${traefik_image:-unknown}"
            _loading3 "Fix: Update Traefik to a newer image version"
            _loading3 "  cd $DOCKSOFT_CONTAINERS/traefik"
            _loading3 "  Edit docker-compose.yml: change image to traefik:v3.3"
            _loading3 "  docker compose pull && docker compose up -d"
        fi
    else
        _success "No recent errors in Traefik logs"
    fi
}

# ==============================================================================
# -- docksoft () - Docker software scaffolding tool
# ==============================================================================
help_docksoft[docksoft]='Docker software container scaffolding tool'
function docksoft () {
    # -- Parse global options
    local -a opts_help
    zparseopts -D -E -- h=opts_help -help=opts_help

    if [[ -n $opts_help ]]; then
        _docksoft_usage
        return 0
    fi

    # -- Check for subcommand
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
