# ==============================================================================
# -- _docksoft_deploy () - Deploy a container from template
# ==============================================================================
function _docksoft_deploy () {
    local template_name="$1"
    local container_name="$template_name"
    shift

    # -- Parse deploy options
    local -a opts_email opts_domain
    zparseopts -D -E -- e:=opts_email -email:=opts_email d:=opts_domain -domain:=opts_domain

    local override_email="" override_domain=""
    [[ -n $opts_email ]] && override_email="${opts_email[-1]}"
    [[ -n $opts_domain ]] && override_domain="${opts_domain[-1]}"

    _loading "Deploying container: $template_name"

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

    # -- Ensure a network is set (back-compat) and persist it to state.
    if [[ -z "$DOCKSOFT_NETWORK" ]]; then
        DOCKSOFT_NETWORK=$(_docksoft_detect_network)
    fi
    _docksoft_conf_ensure_network "$DOCKSOFT_NETWORK" >/dev/null 2>&1

    # -- Check if template exists
    if [[ ! -d "$DOCKSOFT_TEMPLATES/$template_name" ]]; then
        _error "No template found for '$template_name'"
        _loading2 "Run 'docksoft list' to see available templates"
        return 1
    fi

    # -- Check if traefik is deployed (required for all containers except traefik itself)
    # Consider it deployed only if the compose file exists.
    if [[ "$template_name" != "traefik" ]] && [[ ! -f "$DOCKSOFT_CONTAINERS/traefik/docker-compose.yml" ]]; then
        _error "Traefik is not deployed. Deploy traefik first: docksoft traefik"
        return 1
    fi

    # -- Check if instance name already exists and prompt for a new one
    local prompted_for_new_name=0
    local new_name=""
    while _docksoft_name_is_taken "$container_name"; do
        if [[ -d "$DOCKSOFT_CONTAINERS/$container_name" ]]; then
            if [[ -f "$DOCKSOFT_CONTAINERS/$container_name/docker-compose.yml" ]]; then
                _warning "Container '$container_name' already exists at $DOCKSOFT_CONTAINERS/$container_name"
            else
                _warning "Folder exists but docker-compose.yml is missing: $DOCKSOFT_CONTAINERS/$container_name"
                _loading3 "If this is a partial deploy, remove the folder and re-run docksoft"
            fi
        fi

        if docker ps -a --format '{{.Names}}' 2>/dev/null | grep -Fxq "$container_name"; then
            _warning "A Docker container named '$container_name' already exists"
        fi

        read "new_name?Enter a new container name: "
        if [[ -z "$new_name" ]]; then
            _warning "Container name cannot be empty"
            continue
        fi

        if ! echo "$new_name" | grep -Eq '^[A-Za-z0-9][A-Za-z0-9_.-]*$'; then
            _warning "Invalid name. Use letters, numbers, dot, underscore, or hyphen"
            continue
        fi

        container_name="$new_name"
        prompted_for_new_name=1
    done

    if [[ $prompted_for_new_name -eq 1 ]]; then
        _loading3 "Using instance name: $container_name"
    fi

    # -- Read template's docksoft.conf for subdomain prefix
    local tpl_subdomain="$container_name"
    if [[ -f "$DOCKSOFT_TEMPLATES/$template_name/docksoft.conf" ]]; then
        source "$DOCKSOFT_TEMPLATES/$template_name/docksoft.conf"
        [[ -n "$DOCKSOFT_SUBDOMAIN" ]] && tpl_subdomain="$DOCKSOFT_SUBDOMAIN"
    fi

    # -- If deploy name was changed due to conflict, use the new instance name
    # as subdomain to avoid FQDN overlap between multiple instances.
    if [[ $prompted_for_new_name -eq 1 ]]; then
        tpl_subdomain="$container_name"
    fi

    # -- Compute FQDN
    local fqdn=""
    local fqdn_label_count=0
    local hyphenated_fqdn=""
    local hostless_fqdn=""
    local fqdn_action=""
    if [[ -n "$override_domain" ]]; then
        # -- User explicitly overrode the domain
        fqdn="$override_domain"
        local custom_fqdn=""
        _loading3 "Using override FQDN: $fqdn"
    else
        fqdn=$(_docksoft_compute_fqdn "$container_name" "$tpl_subdomain")
        if [[ $? -ne 0 ]]; then
            return 1
        fi
        _loading3 "Computed FQDN ($DOCKSOFT_MODE mode): $fqdn"
    fi

    # -- If FQDN is deeper than a single wildcard level, prompt user.
    # Example overlap risk: n8n-dev.docker01.example.com
    fqdn_label_count=$(_docksoft_domain_label_count "$fqdn")
    if (( fqdn_label_count > 3 )); then
        hyphenated_fqdn=$(_docksoft_hyphenate_fqdn "$fqdn")
        hostless_fqdn=$(_docksoft_remove_host_label_fqdn "$fqdn")
        _warning "FQDN '$fqdn' has ${fqdn_label_count} labels and may not match Cloudflare wildcard coverage"
        _loading3 "Choose FQDN option"
        _loading3 "1. $fqdn"
        _loading3 "2. $hyphenated_fqdn"
        _loading3 "3. $hostless_fqdn"
        _loading3 "4. Custom (Enter your own host)"

        while true; do
            read "fqdn_action?Choose FQDN [1-4] (2): "

            case "$fqdn_action" in
                1)
                    _loading3 "Proceeding with FQDN: $fqdn"
                    break
                    ;;
                ""|2)
                    fqdn="$hyphenated_fqdn"
                    _loading3 "Using hyphenated FQDN: $fqdn"
                    break
                    ;;
                3)
                    fqdn="$hostless_fqdn"
                    _loading3 "Using hostless FQDN: $fqdn"
                    break
                    ;;
                4)
                    read "custom_fqdn?Enter custom hostname/FQDN: "
                    if [[ -z "$custom_fqdn" ]]; then
                        _warning "Custom hostname cannot be empty"
                        continue
                    fi

                    if ! echo "$custom_fqdn" | grep -Eq '^[A-Za-z0-9][A-Za-z0-9.-]*[A-Za-z0-9]$'; then
                        _warning "Invalid hostname. Use letters, numbers, dots, and hyphens"
                        continue
                    fi

                    fqdn="$custom_fqdn"
                    _loading3 "Using custom FQDN: $fqdn"
                    break
                    ;;
                *)
                    _warning "Please enter 1, 2, 3, or 4"
                    ;;
            esac
        done
    fi

    # -- Determine email
    local email="${override_email:-$DOCKSOFT_EMAIL}"

    # -- Copy template to containers directory
    _loading2 "Copying template to $DOCKSOFT_CONTAINERS/$container_name"
    cp -r "$DOCKSOFT_TEMPLATES/$template_name" "$DOCKSOFT_CONTAINERS/$container_name"
    if [[ $? -ne 0 ]]; then
        _error "Failed to copy template for '$template_name'"
        return 1
    fi

    # -- Remove template's docksoft.conf from deployed copy
    rm -f "$DOCKSOFT_CONTAINERS/$container_name/docksoft.conf"

    # -- Replace {{CONTAINER_NAME}} placeholder
    if grep -rq '{{CONTAINER_NAME}}' "$DOCKSOFT_CONTAINERS/$container_name/" 2>/dev/null; then
        find "$DOCKSOFT_CONTAINERS/$container_name" -type f -exec sed -i "s/{{CONTAINER_NAME}}/$container_name/g" {} +
        _loading3 "Replaced {{CONTAINER_NAME}} with $container_name"
    fi

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

    # -- Replace {{NETWORK}} placeholder
    if grep -rq '{{NETWORK}}' "$DOCKSOFT_CONTAINERS/$container_name/" 2>/dev/null; then
        find "$DOCKSOFT_CONTAINERS/$container_name" -type f -exec sed -i "s/{{NETWORK}}/$DOCKSOFT_NETWORK/g" {} +
        _loading3 "Replaced {{NETWORK}} with $DOCKSOFT_NETWORK"
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
