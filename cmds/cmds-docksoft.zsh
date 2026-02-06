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
DOCKSOFT_CONF="${DOCKSOFT_CONTAINERS}/.docksoft.conf"

# Host port tracking (persisted in $DOCKSOFT_CONF)
typeset -gA DOCKSOFT_PORTS

# ==============================================================================
# -- _docksoft_load_conf () - Load docksoft configuration
# ==============================================================================
function _docksoft_load_conf () {
    if [[ ! -f "$DOCKSOFT_CONF" ]]; then
        return 1
    fi
    source "$DOCKSOFT_CONF"

    # Ensure associative array exists even if config is old
    typeset -gA DOCKSOFT_PORTS
    return 0
}

# ==============================================================================
# -- _docksoft_port_in_use () - Check if a TCP port is in use on host
# ==============================================================================
function _docksoft_port_in_use () {
    local port="$1"

    if [[ -z "$port" ]]; then
        return 2
    fi

    # Prefer ss (Linux)
    if (( $+commands[ss] )); then
        ss -lnt 2>/dev/null | awk '{print $4}' | grep -Eq "(:|\])${port}$"
        return $?
    fi

    # lsof works on macOS and many Linux distros
    if (( $+commands[lsof] )); then
        lsof -nP -iTCP:"$port" -sTCP:LISTEN >/dev/null 2>&1
        return $?
    fi

    # netstat fallback
    if (( $+commands[netstat] )); then
        netstat -an 2>/dev/null | grep -E 'LISTEN|LISTENING' | awk '{print $4}' | grep -Eq "\.${port}$|:${port}$"
        return $?
    fi

    # Can't determine; assume free
    return 1
}

# ==============================================================================
# -- _docksoft_ports_is_allocated () - Check if port is already allocated in state
# ==============================================================================
function _docksoft_ports_is_allocated () {
    local port="$1"
    local key

    for key in "${(@k)DOCKSOFT_PORTS}"; do
        if [[ "${DOCKSOFT_PORTS[$key]}" == "$port" ]]; then
            return 0
        fi
    done
    return 1
}

# ==============================================================================
# -- _docksoft_ports_find_free () - Find a free host port starting at desired
# ==============================================================================
function _docksoft_ports_find_free () {
    local desired="$1"
    local port
    local tries=0

    port="$desired"
    while (( tries < 2000 )); do
        # must be numeric
        if [[ "$port" != <-> ]]; then
            return 2
        fi

        if ! _docksoft_ports_is_allocated "$port" && ! _docksoft_port_in_use "$port"; then
            echo "$port"
            return 0
        fi

        (( port++ ))
        (( tries++ ))
        if (( port > 65535 )); then
            break
        fi
    done
    return 1
}

# ==============================================================================
# -- _docksoft_conf_write_ports_state () - Persist DOCKSOFT_PORTS into conf file
# ==============================================================================
function _docksoft_conf_write_ports_state () {
    # Writes a stable block to $DOCKSOFT_CONF, keeping all other config intact.
    local tmp
    tmp=$(mktemp "${DOCKSOFT_CONF}.tmp.XXXXXX") || return 1

    if [[ -f "$DOCKSOFT_CONF" ]]; then
        awk '
            BEGIN{skip=0}
            /^# -- DOCKSOFT_PORTS_BEGIN/{skip=1; next}
            /^# -- DOCKSOFT_PORTS_END/{skip=0; next}
            skip==0{print}
        ' "$DOCKSOFT_CONF" > "$tmp" || { rm -f "$tmp"; return 1; }
    fi

    {
        echo ""
        echo "# -- DOCKSOFT_PORTS_BEGIN"
        echo "typeset -gA DOCKSOFT_PORTS"
        local key
        for key in "${(@ok)DOCKSOFT_PORTS}"; do
            echo "DOCKSOFT_PORTS[\"$key\"]=\"${DOCKSOFT_PORTS[$key]}\""
        done
        echo "# -- DOCKSOFT_PORTS_END"
    } >> "$tmp" || { rm -f "$tmp"; return 1; }

    mv "$tmp" "$DOCKSOFT_CONF"
    return $?
}

# ==============================================================================
# -- _docksoft_compose_get_port_lines () - Extract port mapping strings
# ==============================================================================
function _docksoft_compose_get_port_lines () {
    local compose_file="$1"
    local -a out
    local in_ports=0
    local line

    [[ -f "$compose_file" ]] || return 1

    while IFS= read -r line; do
        if [[ "$line" =~ '^[[:space:]]*ports:[[:space:]]*$' ]]; then
            in_ports=1
            continue
        fi

        if (( in_ports )); then
            # stop when we hit a non-list item at same or lesser indentation
            if [[ ! "$line" =~ '^[[:space:]]*-[[:space:]]*' ]]; then
                # allow blank lines inside ports block
                if [[ -z "${line//[[:space:]]/}" ]]; then
                    continue
                fi
                in_ports=0
                continue
            fi

            local mapping="${line#*-}"
            mapping="${mapping##[[:space:]]}"
            mapping="${mapping%%[[:space:]]}"
            mapping="${mapping%\"}"
            mapping="${mapping#\"}"
            out+=("$mapping")
        fi
    done < "$compose_file"

    print -rl -- "${out[@]}"
}

# ==============================================================================
# -- _docksoft_compose_rewrite_port () - Replace a specific port mapping string
# ==============================================================================
function _docksoft_compose_rewrite_port () {
    local compose_file="$1"
    local old_mapping="$2"
    local new_mapping="$3"

    [[ -f "$compose_file" ]] || return 1

    # Try perl first for portability
    if (( $+commands[perl] )); then
        perl -0777 -pe 's/\Q'"$old_mapping"'\E/'"$new_mapping"'/g' -i "$compose_file" 2>/dev/null
        return $?
    fi

    # sed fallback (GNU/BSD differences: use a temp file)
    local tmp
    tmp=$(mktemp "${compose_file}.tmp.XXXXXX") || return 1
    sed "s|${old_mapping//|/\\|}|${new_mapping//|/\\|}|g" "$compose_file" > "$tmp" || { rm -f "$tmp"; return 1; }
    mv "$tmp" "$compose_file"
    return $?
}

# ==============================================================================
# -- _docksoft_allocate_ports_for_compose () - Ensure no host port overlaps
# ==============================================================================
function _docksoft_allocate_ports_for_compose () {
    local container_name="$1"
    local compose_file="$2"

    local mapping
    local changed=0

    for mapping in $(_docksoft_compose_get_port_lines "$compose_file" 2>/dev/null); do
        # Only handle explicit host-port mappings: host:container or ip:host:container
        local proto="tcp"
        local mapping_no_proto="$mapping"
        if [[ "$mapping_no_proto" == */* ]]; then
            proto="${mapping_no_proto##*/}"
            mapping_no_proto="${mapping_no_proto%/*}"
        fi

        local -a parts
        parts=(${(s/:/)mapping_no_proto})

        local ip_part=""
        local host_port=""
        local container_port=""

        if (( ${#parts[@]} == 3 )); then
            ip_part="${parts[1]}"
            host_port="${parts[2]}"
            container_port="${parts[3]}"
        elif (( ${#parts[@]} == 2 )); then
            host_port="${parts[1]}"
            container_port="${parts[2]}"
        else
            continue
        fi

        # numeric only
        if [[ "$host_port" != <-> ]] || [[ "$container_port" != <-> ]]; then
            continue
        fi

        # Don't silently remap Traefik's primary ports.
        if [[ "$container_name" == "traefik" ]] && [[ "$host_port" == "80" || "$host_port" == "443" ]]; then
            if _docksoft_port_in_use "$host_port"; then
                _error "Port $host_port is already in use; cannot auto-remap Traefik. Free the port and re-run."
                return 1
            fi
        fi

        local key="${container_name}:${container_port}/${proto}"

        # If already recorded, prefer the recorded host port.
        if [[ -n "${DOCKSOFT_PORTS[$key]}" ]]; then
            local recorded="${DOCKSOFT_PORTS[$key]}"
            if [[ "$recorded" != "$host_port" ]]; then
                local new_mapping
                if [[ -n "$ip_part" ]]; then
                    new_mapping="${ip_part}:${recorded}:${container_port}"
                else
                    new_mapping="${recorded}:${container_port}"
                fi
                [[ "$proto" != "tcp" ]] && new_mapping+="/${proto}"
                _docksoft_compose_rewrite_port "$compose_file" "$mapping" "$new_mapping" || return 1
                host_port="$recorded"
                changed=1
            fi
        fi

        # If host port is allocated to someone else or in use, bump.
        local needs_new=0
        if _docksoft_ports_is_allocated "$host_port"; then
            # allow if it's allocated to ourselves
            if [[ "${DOCKSOFT_PORTS[$key]}" != "$host_port" ]]; then
                needs_new=1
            fi
        fi
        if _docksoft_port_in_use "$host_port"; then
            needs_new=1
        fi

        if (( needs_new )); then
            local new_host
            new_host=$(_docksoft_ports_find_free "$host_port") || {
                _error "Unable to find a free port starting at $host_port"
                return 1
            }

            local new_mapping
            if [[ -n "$ip_part" ]]; then
                new_mapping="${ip_part}:${new_host}:${container_port}"
            else
                new_mapping="${new_host}:${container_port}"
            fi
            [[ "$proto" != "tcp" ]] && new_mapping+="/${proto}"

            _loading3 "Port conflict: ${mapping} -> ${new_mapping}"
            _docksoft_compose_rewrite_port "$compose_file" "$mapping" "$new_mapping" || return 1
            host_port="$new_host"
            changed=1
        fi

        DOCKSOFT_PORTS["$key"]="$host_port"
    done

    # Persist state if we allocated or recorded ports.
    _docksoft_conf_write_ports_state || return 1

    if (( changed )); then
        _success "Adjusted published ports to avoid overlaps"
    fi
    return 0
}

# ==============================================================================
# -- _docksoft_compute_fqdn () - Compute FQDN for a container
# ==============================================================================
function _docksoft_compute_fqdn () {
    local container_name="$1"
    local subdomain="$2"

    if ! _docksoft_load_conf; then
        _error "docksoft config not found. Run 'docksoft init' first."
        return 1
    fi

    if [[ "$DOCKSOFT_MODE" == "single" ]]; then
        # Single mode: just use the base domain directly
        echo "${DOCKSOFT_DOMAIN}"
    else
        # Multi mode: prepend subdomain
        echo "${subdomain}.${DOCKSOFT_DOMAIN}"
    fi
}

# ==============================================================================
# -- _docksoft_usage () - Print docksoft usage
# ==============================================================================
function _docksoft_usage () {
    echo ""
    echo "Usage: docksoft <command> [options]"
    echo ""
    echo "Commands:"
    echo "  init                        Initialize docksoft (directories, network, config)"
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
    echo "  docksoft uptime-kuma --domain custom.example.com   # override FQDN"
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

    # -- Configuration questionnaire
    _loading "Configuring docksoft"

    if [[ -f "$DOCKSOFT_CONF" ]]; then
        _loading2 "Existing configuration found:"
        source "$DOCKSOFT_CONF"
        _loading3 "Mode: $DOCKSOFT_MODE"
        _loading3 "Domain: $DOCKSOFT_DOMAIN"
        _loading3 "Email: $DOCKSOFT_EMAIL"
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
    echo ""
    local mode=""
    while [[ "$mode" != "single" && "$mode" != "multi" ]]; do
        read "mode?Enter mode (single/multi): "
        if [[ "$mode" != "single" && "$mode" != "multi" ]]; then
            _warning "Please enter 'single' or 'multi'"
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
EOF

    _success "Configuration saved to $DOCKSOFT_CONF"
    _loading3 "Mode: $mode"
    _loading3 "Domain: $base_domain"
    _loading3 "Email: $acme_email"
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

    local override_email="" override_domain=""
    [[ -n $opts_email ]] && override_email="${opts_email[-1]}"
    [[ -n $opts_domain ]] && override_domain="${opts_domain[-1]}"

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

    # -- Load configuration
    if ! _docksoft_load_conf; then
        _error "docksoft config not found at $DOCKSOFT_CONF. Run 'docksoft init' first."
        return 1
    fi

    # -- Check if template exists
    if [[ ! -d "$DOCKSOFT_TEMPLATES/$container_name" ]]; then
        _error "No template found for '$container_name'"
        _loading2 "Run 'docksoft list' to see available templates"
        return 1
    fi

    # -- Check if traefik is deployed (required for all containers except traefik itself)
    # Consider it deployed only if the compose file exists.
    if [[ "$container_name" != "traefik" ]] && [[ ! -f "$DOCKSOFT_CONTAINERS/traefik/docker-compose.yml" ]]; then
        _error "Traefik is not deployed. Deploy traefik first: docksoft traefik"
        return 1
    fi

    # -- Check if container already exists
    if [[ -d "$DOCKSOFT_CONTAINERS/$container_name" ]]; then
        if [[ -f "$DOCKSOFT_CONTAINERS/$container_name/docker-compose.yml" ]]; then
            _warning "Container '$container_name' already exists at $DOCKSOFT_CONTAINERS/$container_name"
        else
            _warning "Folder exists but docker-compose.yml is missing: $DOCKSOFT_CONTAINERS/$container_name"
            _loading3 "If this is a partial deploy, remove the folder and re-run docksoft"
        fi
        return 1
    fi

    # -- Read template's docksoft.conf for subdomain prefix
    local tpl_subdomain="$container_name"
    if [[ -f "$DOCKSOFT_TEMPLATES/$container_name/docksoft.conf" ]]; then
        source "$DOCKSOFT_TEMPLATES/$container_name/docksoft.conf"
        [[ -n "$DOCKSOFT_SUBDOMAIN" ]] && tpl_subdomain="$DOCKSOFT_SUBDOMAIN"
    fi

    # -- Compute FQDN
    local fqdn=""
    if [[ -n "$override_domain" ]]; then
        # -- User explicitly overrode the domain
        fqdn="$override_domain"
        _loading3 "Using override FQDN: $fqdn"
    else
        fqdn=$(_docksoft_compute_fqdn "$container_name" "$tpl_subdomain")
        if [[ $? -ne 0 ]]; then
            return 1
        fi
        _loading3 "Computed FQDN ($DOCKSOFT_MODE mode): $fqdn"
    fi

    # -- Determine email
    local email="${override_email:-$DOCKSOFT_EMAIL}"

    # -- Copy template to containers directory
    _loading2 "Copying template to $DOCKSOFT_CONTAINERS/$container_name"
    cp -r "$DOCKSOFT_TEMPLATES/$container_name" "$DOCKSOFT_CONTAINERS/$container_name"
    if [[ $? -ne 0 ]]; then
        _error "Failed to copy template for '$container_name'"
        return 1
    fi

    # -- Remove template's docksoft.conf from deployed copy
    rm -f "$DOCKSOFT_CONTAINERS/$container_name/docksoft.conf"

    # -- Replace {{FQDN}} placeholder
    if grep -rq '{{FQDN}}' "$DOCKSOFT_CONTAINERS/$container_name/" 2>/dev/null; then
        find "$DOCKSOFT_CONTAINERS/$container_name" -type f -exec sed -i "s/{{FQDN}}/$fqdn/g" {} +
        _loading3 "Replaced {{FQDN}} with $fqdn"
    fi

    # -- Replace {{DOMAIN}} placeholder (base domain for configs)
    if grep -rq '{{DOMAIN}}' "$DOCKSOFT_CONTAINERS/$container_name/" 2>/dev/null; then
        find "$DOCKSOFT_CONTAINERS/$container_name" -type f -exec sed -i "s/{{DOMAIN}}/$DOCKSOFT_DOMAIN/g" {} +
        _loading3 "Replaced {{DOMAIN}} with $DOCKSOFT_DOMAIN"
    fi

    # -- Replace {{EMAIL}} placeholder
    if grep -rq '{{EMAIL}}' "$DOCKSOFT_CONTAINERS/$container_name/" 2>/dev/null; then
        if [[ -n "$email" ]]; then
            find "$DOCKSOFT_CONTAINERS/$container_name" -type f -exec sed -i "s/{{EMAIL}}/$email/g" {} +
            _loading3 "Replaced {{EMAIL}} with $email"
        else
            _warning "No email configured. {{EMAIL}} placeholders left unchanged — edit manually."
        fi
    fi

    # -- Allocate/track published host ports to avoid overlaps
    if [[ -f "$DOCKSOFT_CONTAINERS/$container_name/docker-compose.yml" ]]; then
        if ! _docksoft_allocate_ports_for_compose "$container_name" "$DOCKSOFT_CONTAINERS/$container_name/docker-compose.yml"; then
            _error "Failed to allocate ports for $container_name"
            return 1
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
    _loading3 "FQDN: $fqdn"
    _loading2 "To start: cd $DOCKSOFT_CONTAINERS/$container_name && docker compose up -d"
}

# ==============================================================================
# -- _docksoft_show_config () - Show current docksoft configuration
# ==============================================================================
help_docksoft[config]='Show current docksoft configuration'
function _docksoft_show_config () {
    if ! _docksoft_load_conf; then
        _error "No configuration found. Run 'docksoft init' first."
        return 1
    fi

    _loading "docksoft configuration ($DOCKSOFT_CONF)"
    _loading2 "Mode: $DOCKSOFT_MODE"
    if [[ "$DOCKSOFT_MODE" == "single" ]]; then
        _loading3 "Services use domain as-is (no subdomain prefix)"
    else
        _loading3 "Services get subdomain prefix: <service>.$DOCKSOFT_DOMAIN"
    fi
    _loading2 "Domain: $DOCKSOFT_DOMAIN"
    _loading2 "Email: $DOCKSOFT_EMAIL"

    # -- Show deployed containers
    _loading "Deployed containers"
    local found=0
    for cdir in "$DOCKSOFT_CONTAINERS"/*(N/); do
        local cname="${cdir:t}"
        [[ "$cname" == ".*" ]] && continue

        # Consider a template deployed only if it has a docker-compose.yml
        if [[ ! -f "$cdir/docker-compose.yml" ]]; then
            continue
        fi

        local status="stopped"
        if docker ps --format '{{.Names}}' 2>/dev/null | grep -q "^${cname}$"; then
            status="running"
        fi
        _loading3 "$cname ($status)"
        found=1
    done
    if [[ $found -eq 0 ]]; then
        _loading3 "No containers deployed"
    fi
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

    # -- Prefer host-side API access.
    # On macOS Docker Desktop the container IP is not reliably reachable from the host,
    # and the Traefik image may not include curl/wget. The docksoft Traefik template
    # publishes 127.0.0.1:8080 for status checks.
    local TRAEFIK_API="http://127.0.0.1:8080/api"

    function _traefik_api_get () {
        local endpoint="$1"
        if (( $+commands[curl] )); then
            curl -sf "${TRAEFIK_API}${endpoint}"
            return $?
        elif (( $+commands[wget] )); then
            wget -qO- "${TRAEFIK_API}${endpoint}"
            return $?
        fi
        return 127
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
        _error "Failed to query Traefik API at ${TRAEFIK_API}"
        _loading2 "Checks:"
        _loading3 "Traefik static config must include: api.insecure: true"
        _loading3 "docker-compose.yml should publish localhost API: 127.0.0.1:8080:8080"
        _loading3 "Host must have curl (preferred) or wget"
        return 1
    fi

    # -- Check for jq
    if (( ! $+commands[jq] )); then
        if (( $+commands[python3] )); then
            _warning "jq not installed — using python3 for formatted output"
        else
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
    fi

    if (( $+commands[jq] )); then
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
    else
        # python3-based overview summary (minimal)
        if (( $+commands[python3] )); then
            _loading2 "Entrypoints"
            print -r -- "$overview" | python3 - <<'PY'
import json,sys
try:
    o=json.load(sys.stdin)
except Exception:
    sys.exit(0)
eps=o.get('entryPoints') or {}
if not eps:
    print('  No entrypoints found')
else:
    for name, cfg in eps.items():
        addr = (cfg or {}).get('address','unknown')
        print(f'  {name} -> {addr}')
http=o.get('http') or {}
routers=(http.get('routers') or {})
services=(http.get('services') or {})
def gv(d,k):
    v=d.get(k,0)
    return 0 if v is None else v
print(f"  HTTP Routers: {gv(routers,'total')} total, {gv(routers,'errors')} errors, {gv(routers,'warnings')} warnings")
print(f"  HTTP Services: {gv(services,'total')} total, {gv(services,'errors')} errors, {gv(services,'warnings')} warnings")
PY
        fi
    fi

    # -- HTTP Routers
    _loading2 "HTTP Routers"
    local routers=$(_traefik_api_get "/http/routers" 2>/dev/null)
    if [[ -n "$routers" ]]; then
        if (( $+commands[jq] )); then
            echo "$routers" | jq -r '.[] | "  [\(.status // "unknown")] \(.name) tls=\(if .tls == null then "no" else "yes" end) ep=\(.entryPoints // ["none"] | join(",")) svc=\(.service // "unknown") mw=\(.middlewares // [] | join(",")) rule=\(.rule // "no rule")"' 2>/dev/null
        else
            print -r -- "$routers" | python3 - <<'PY'
import json,sys
try:
    data=json.load(sys.stdin)
except Exception:
    sys.exit(0)
for r in data or []:
    status=r.get('status','unknown')
    name=r.get('name','unknown')
    rule=r.get('rule','no rule')
    eps=','.join(r.get('entryPoints') or ['none'])
    tls='yes' if r.get('tls') is not None else 'no'
    svc=r.get('service','unknown')
    mws=','.join(r.get('middlewares') or [])
    print(f"  [{status}] {name} tls={tls} ep={eps} svc={svc} mw={mws} rule={rule}")
PY
        fi
    else
        _loading3 "No HTTP routers found"
    fi

    # -- HTTP Services
    _loading2 "HTTP Services"
    local services=$(_traefik_api_get "/http/services" 2>/dev/null)
    if [[ -n "$services" ]]; then
        if (( $+commands[jq] )); then
            echo "$services" | jq -r '.[] | "  [\(.status // "unknown")] \(.name) type=\(.type // "unknown")"' 2>/dev/null
        else
            print -r -- "$services" | python3 - <<'PY'
import json,sys
try:
    data=json.load(sys.stdin)
except Exception:
    sys.exit(0)
for s in data or []:
    status=s.get('status','unknown')
    name=s.get('name','unknown')
    stype=s.get('type','unknown')
    print(f"  [{status}] {name} type={stype}")
PY
        fi
    else
        _loading3 "No HTTP services found"
    fi

    # -- TLS Certificates
    _loading2 "TLS Certificates (ACME)"
    if [[ -f "$DOCKSOFT_CONTAINERS/traefik/acme.json" ]]; then
        if (( $+commands[jq] )); then
            local cert_count=$(jq '[.letsencrypt.Certificates // [] | length] | add // 0' "$DOCKSOFT_CONTAINERS/traefik/acme.json" 2>/dev/null)
            if [[ "$cert_count" -gt 0 ]]; then
                jq -r '.letsencrypt.Certificates[] | "  \(.domain.main) (SANs: \(.domain.sans // ["none"] | join(", ")))"' "$DOCKSOFT_CONTAINERS/traefik/acme.json" 2>/dev/null
            else
                _loading3 "No certificates issued yet"
            fi
        elif (( $+commands[python3] )); then
            python3 - <<'PY' "$DOCKSOFT_CONTAINERS/traefik/acme.json"
import json,sys
path=sys.argv[1]
try:
    with open(path,'r') as f:
        data=json.load(f)
except Exception:
    print('  Unable to parse acme.json')
    sys.exit(0)
le=data.get('letsencrypt') or {}
certs=le.get('Certificates') or []
if not certs:
    print('  No certificates issued yet')
else:
    for c in certs:
        dom=(c.get('domain') or {})
        main=dom.get('main','unknown')
        sans=dom.get('sans') or []
        sans_txt=', '.join(sans) if sans else 'none'
        print(f'  {main} (SANs: {sans_txt})')
PY
        else
            _loading3 "acme.json present but neither jq nor python3 is available to parse it"
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
            _loading3 "  Edit docker-compose.yml: change image to traefik:latest"
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
