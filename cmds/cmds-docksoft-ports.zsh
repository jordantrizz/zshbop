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
            if [[ ! "$line" =~ '^[[:space:]]*-[[:space:]]*' ]]; then
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

    if (( $+commands[perl] )); then
        perl -0777 -pe 's/\Q'"$old_mapping"'\E/'"$new_mapping"'/g' -i "$compose_file" 2>/dev/null
        return $?
    fi

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

        if [[ "$host_port" != <-> ]] || [[ "$container_port" != <-> ]]; then
            continue
        fi

        if [[ "$container_name" == "traefik" ]] && [[ "$host_port" == "80" || "$host_port" == "443" ]]; then
            if _docksoft_port_in_use "$host_port"; then
                _error "Port $host_port is already in use; cannot auto-remap Traefik. Free the port and re-run."
                return 1
            fi
        fi

        local key="${container_name}:${container_port}/${proto}"

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

        local needs_new=0
        if _docksoft_ports_is_allocated "$host_port"; then
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

    _docksoft_conf_write_ports_state || return 1

    if (( changed )); then
        _success "Adjusted published ports to avoid overlaps"
    fi
    return 0
}
