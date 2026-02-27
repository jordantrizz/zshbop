# ==============================================================================
# -- _docksoft_load_conf () - Load docksoft configuration
# ==============================================================================
function _docksoft_load_conf () {
    if [[ ! -f "$DOCKSOFT_CONF" ]]; then
        return 1
    fi
    source "$DOCKSOFT_CONF"

    typeset -g DOCKSOFT_NETWORK="${DOCKSOFT_NETWORK:-proxy}"
    typeset -gA DOCKSOFT_PORTS
    return 0
}

# ==============================================================================
# -- _docksoft_conf_ensure_network () - Persist DOCKSOFT_NETWORK into conf
# ==============================================================================
function _docksoft_conf_ensure_network () {
    local network="$1"

    [[ -n "$network" ]] || return 1
    [[ -f "$DOCKSOFT_CONF" ]] || return 1

    if grep -Eq '^DOCKSOFT_NETWORK=' "$DOCKSOFT_CONF"; then
        return 0
    fi

    {
        echo ""
        echo "# Proxy network used by docksoft templates"
        echo "DOCKSOFT_NETWORK=\"$network\""
    } >> "$DOCKSOFT_CONF" 2>/dev/null

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
        echo "${DOCKSOFT_DOMAIN}"
    else
        echo "${subdomain}.${DOCKSOFT_DOMAIN}"
    fi
}

# ==============================================================================
# -- _docksoft_domain_label_count () - Count labels in a hostname
# ==============================================================================
function _docksoft_domain_label_count () {
    local host="$1"

    if [[ -z "$host" ]]; then
        echo 0
        return 0
    fi

    echo "$host" | awk -F'.' '{print NF}'
    return 0
}

# ==============================================================================
# -- _docksoft_hyphenate_fqdn () - Merge leading labels until 3 remain
# ==============================================================================
function _docksoft_hyphenate_fqdn () {
    local fqdn="$1"
    local label_count
    local first_label=""
    local remaining=""
    local second_label=""
    local trailing=""

    label_count=$(_docksoft_domain_label_count "$fqdn")
    while (( label_count > 3 )); do
        first_label="${fqdn%%.*}"
        remaining="${fqdn#*.}"
        second_label="${remaining%%.*}"
        trailing="${remaining#*.}"

        if [[ "$trailing" == "$remaining" ]]; then
            break
        fi

        fqdn="${first_label}-${second_label}.${trailing}"
        label_count=$(_docksoft_domain_label_count "$fqdn")
    done

    echo "$fqdn"
    return 0
}

# ==============================================================================
# -- _docksoft_remove_host_label_fqdn () - Remove second label from deep FQDN
# ==============================================================================
function _docksoft_remove_host_label_fqdn () {
    local fqdn="$1"
    local first_label=""
    local remainder_after_first=""
    local remainder_after_second=""

    if (( $(_docksoft_domain_label_count "$fqdn") < 4 )); then
        echo "$fqdn"
        return 0
    fi

    first_label="${fqdn%%.*}"
    remainder_after_first="${fqdn#*.}"
    remainder_after_second="${remainder_after_first#*.}"

    if [[ "$remainder_after_second" == "$remainder_after_first" ]]; then
        echo "$fqdn"
        return 0
    fi

    echo "${first_label}.${remainder_after_second}"
    return 0
}

# ==============================================================================
# -- _docksoft_show_config () - Show current docksoft configuration
# ==============================================================================
if [[ "${(t)help_docksoft}" != *association* ]]; then
    unset help_docksoft
    typeset -gA help_docksoft
fi
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
    _loading2 "Network: ${DOCKSOFT_NETWORK:-proxy}"

    _loading "Deployed containers"
    local found=0
    for cdir in "$DOCKSOFT_CONTAINERS"/*(N/); do
        local cname="${cdir:t}"
        [[ "$cname" == ".*" ]] && continue

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
