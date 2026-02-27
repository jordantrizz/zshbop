# ==============================================================================
# -- _docksoft_detect_network () - Choose an existing proxy network if present
# ==============================================================================
function _docksoft_detect_network () {
    local candidate
    for candidate in traefik-proxy traefik proxy; do
        if docker network inspect "$candidate" &>/dev/null; then
            echo "$candidate"
            return 0
        fi
    done
    echo "proxy"
    return 0
}

# ==============================================================================
# -- _docksoft_name_is_taken () - Check if instance name collides
# ==============================================================================
function _docksoft_name_is_taken () {
    local candidate_name="$1"

    [[ -z "$candidate_name" ]] && return 1

    if [[ -d "$DOCKSOFT_CONTAINERS/$candidate_name" ]]; then
        return 0
    fi

    if (( $+commands[docker] )); then
        if docker ps -a --format '{{.Names}}' 2>/dev/null | grep -Fxq "$candidate_name"; then
            return 0
        fi
    fi

    return 1
}

# ==============================================================================
# -- _docksoft_port_in_use () - Check if a TCP port is in use on host
# ==============================================================================
function _docksoft_port_in_use () {
    local port="$1"

    if [[ -z "$port" ]]; then
        return 2
    fi

    if (( $+commands[ss] )); then
        ss -lnt 2>/dev/null | awk '{print $4}' | grep -Eq "(:|\])${port}$"
        return $?
    fi

    if (( $+commands[lsof] )); then
        lsof -nP -iTCP:"$port" -sTCP:LISTEN >/dev/null 2>&1
        return $?
    fi

    if (( $+commands[netstat] )); then
        netstat -an 2>/dev/null | grep -E 'LISTEN|LISTENING' | awk '{print $4}' | grep -Eq "\.${port}$|:${port}$"
        return $?
    fi

    return 1
}
