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
        _error "Containers directory already exists: $DOCKSOFT_CONTAINERS"
        _warning "Stopping to protect existing container data."
        _loading3 "Use a different path or move/backup existing data before running 'docksoft init'."
        return 1
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

    # -- Detect or create the Docker network used for reverse-proxy routing
    # If a common Traefik network already exists, prefer it.
    DOCKSOFT_NETWORK=$(_docksoft_detect_network)
    _loading2 "Using Docker network: $DOCKSOFT_NETWORK"

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

    # -- Configuration questionnaire
    _loading "Configuring docksoft"

    if [[ -f "$DOCKSOFT_CONF" ]]; then
        _loading2 "Existing configuration found:"
        source "$DOCKSOFT_CONF"
        _loading3 "Mode: $DOCKSOFT_MODE"
        _loading3 "Domain: $DOCKSOFT_DOMAIN"
        _loading3 "Email: $DOCKSOFT_EMAIL"
        _loading3 "Network: ${DOCKSOFT_NETWORK:-proxy}"
        local reconfig=""
        read "reconfig?Reconfigure? (y/N): "
        if [[ "$reconfig" != [yY] ]]; then
            _loading3 "Keeping existing configuration"
            return 0
        fi
    fi

    # -- Ask for deployment mode
    _loading2 "Deployment mode"
    echo "  single - This server runs one primary service"
    echo "           Domain is used directly (e.g., uptime.ohmyhi.net)"
    echo "  multi  - This server hosts multiple services"
    echo "           Services get subdomains (e.g., uptime.docker01.example.com)"
    echo "  skip   - Skip configuration for now"
    echo ""
    local mode=""
    while [[ "$mode" != "single" && "$mode" != "multi" && "$mode" != "skip" ]]; do
        read "mode?Enter mode (single/multi/skip): "
        mode="${mode:l}"

        if [[ "$mode" == "skip" ]]; then
            _warning "Skipping docksoft configuration (no domain/email written)."
            _loading3 "Re-run 'docksoft init' to configure later."
            return 0
        fi

        if [[ "$mode" != "single" && "$mode" != "multi" ]]; then
            _warning "Please enter 'single', 'multi', or 'skip'"
        fi
    done

    # -- Ask for base domain
    local base_domain=""
    if [[ "$mode" == "single" ]]; then
        _loading2 "Base domain"
        echo "  For single mode, this is the server's hostname"
        echo "  e.g., uptime.ohmyhi.net or myserver.example.com"
    else
        _loading2 "Base domain"
        echo "  For multi mode, services will be created as <service>.<domain>"
        echo "  e.g., docker01.example.com -> uptime.docker01.example.com"
    fi
    while [[ -z "$base_domain" ]]; do
        read "base_domain?Enter base domain: "
        if [[ -z "$base_domain" ]]; then
            _warning "Domain cannot be empty"
        fi
    done

    # -- Ask for email
    _loading2 "Let's Encrypt email"
    echo "  Used for ACME certificate registration with Let's Encrypt"
    local acme_email=""
    while [[ -z "$acme_email" ]]; do
        read "acme_email?Enter email address: "
        if [[ -z "$acme_email" ]]; then
            _warning "Email cannot be empty (required for Let's Encrypt)"
        fi
    done

    # -- Write configuration
    cat > "$DOCKSOFT_CONF" <<EOF
# docksoft configuration - generated by 'docksoft init'
# Mode: single (domain used as-is) or multi (subdomain.domain)
DOCKSOFT_MODE="$mode"
DOCKSOFT_DOMAIN="$base_domain"
DOCKSOFT_EMAIL="$acme_email"
DOCKSOFT_NETWORK="$DOCKSOFT_NETWORK"
EOF

    _success "Configuration saved to $DOCKSOFT_CONF"
    _loading3 "Mode: $mode"
    _loading3 "Domain: $base_domain"
    _loading3 "Email: $acme_email"
    _loading3 "Network: $DOCKSOFT_NETWORK"
}
