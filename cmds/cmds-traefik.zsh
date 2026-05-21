#
# Traefik commands
#
_debug " -- Loading ${(%):-%N}"

help_files[traefik]='Traefik commands'
if [[ "${(t)help_traefik}" != *association* ]]; then
    unset help_traefik
    typeset -gA help_traefik
fi

# ==============================================================================
# -- _traefik_status_has_command () - Check if a command is available in PATH
# ==============================================================================
function _traefik_status_has_command () {
    command -v "$1" >/dev/null 2>&1
}

# ==============================================================================
# -- _traefik_status_api_get () - Fetch a Traefik API endpoint from the host
# ==============================================================================
function _traefik_status_api_get () {
    local api_base="$1"
    local endpoint="$2"

    if _traefik_status_has_command curl; then
        curl -sf "${api_base}${endpoint}"
        return $?
    elif _traefik_status_has_command wget; then
        wget -qO- "${api_base}${endpoint}"
        return $?
    fi

    return 127
}

# ==============================================================================
# -- traefik-status () - Show Traefik status from the API
# ==============================================================================
help_traefik[traefik-status]='Show Traefik routers, services, and certificate status'
function traefik-status () {
    local -a opts_help opts_raw
    local TRAEFIK_API overview routers services
    local router_total router_errors router_warnings svc_total svc_errors svc_warnings
    local container_status container_uptime container_image error_logs host_api traefik_image
    local ep_names ep ep_addr cert_count
    local has_jq=0
    local has_python=0

    zparseopts -D -E -- h=opts_help -help=opts_help r=opts_raw -raw=opts_raw

    if [[ -n $opts_help ]]; then
        echo "Usage: traefik-status [-h|--help] [-r|--raw]"
        echo "  -r, --raw    Show raw JSON output"
        return 0
    fi

    [[ -z "${DOCKSOFT_CONTAINERS:-}" ]] && DOCKSOFT_CONTAINERS="/root/containers"

    if ! docker ps --format '{{.Names}}' | grep -q '^traefik$'; then
        _error "Traefik container is not running"
        return 1
    fi

    TRAEFIK_API="http://127.0.0.1:8080/api"

    if _traefik_status_has_command jq; then
        has_jq=1
    fi

    if _traefik_status_has_command python3; then
        has_python=1
    fi

    if [[ -n $opts_raw ]]; then
        _loading "Traefik API - Raw Overview"
        _traefik_status_api_get "$TRAEFIK_API" "/overview"
        echo ""
        _loading "Traefik API - Raw HTTP Routers"
        _traefik_status_api_get "$TRAEFIK_API" "/http/routers"
        echo ""
        _loading "Traefik API - Raw HTTP Services"
        _traefik_status_api_get "$TRAEFIK_API" "/http/services"
        echo ""
        return 0
    fi

    _loading "Traefik Status"
    overview=$(_traefik_status_api_get "$TRAEFIK_API" "/overview" 2>/dev/null)
    if [[ -z "$overview" ]]; then
        _error "Failed to query Traefik API at ${TRAEFIK_API}"
        _loading2 "Checks:"
        _loading3 "Traefik static config must include: api.insecure: true"
        _loading3 "docker-compose.yml should publish localhost API: 127.0.0.1:8080:8080"
        _loading3 "Host must have curl (preferred) or wget"
        return 1
    fi

    if (( ! has_jq )); then
        if (( has_python )); then
            _warning "jq not installed — using python3 for formatted output"
        else
            _warning "jq not installed — showing raw JSON output"
            _loading2 "Overview:"
            echo "$overview"
            _loading2 "HTTP Routers:"
            _traefik_status_api_get "$TRAEFIK_API" "/http/routers"
            echo ""
            _loading2 "HTTP Services:"
            _traefik_status_api_get "$TRAEFIK_API" "/http/services"
            echo ""
            return 0
        fi
    fi

    if (( has_jq )); then
        _loading2 "Entrypoints"
        ep_names=$(echo "$overview" | jq -r '.entryPoints // {} | keys[]' 2>/dev/null)
        if [[ -n "$ep_names" ]]; then
            while IFS= read -r ep; do
                ep_addr=$(echo "$overview" | jq -r ".entryPoints.\"$ep\".address // \"unknown\"" 2>/dev/null)
                _loading3 "$ep -> $ep_addr"
            done <<< "$ep_names"
        else
            _loading3 "No entrypoints found"
        fi

        router_total=$(echo "$overview" | jq -r '.http.routers.total // 0' 2>/dev/null)
        router_errors=$(echo "$overview" | jq -r '.http.routers.errors // 0' 2>/dev/null)
        router_warnings=$(echo "$overview" | jq -r '.http.routers.warnings // 0' 2>/dev/null)
        svc_total=$(echo "$overview" | jq -r '.http.services.total // 0' 2>/dev/null)
        svc_errors=$(echo "$overview" | jq -r '.http.services.errors // 0' 2>/dev/null)
        svc_warnings=$(echo "$overview" | jq -r '.http.services.warnings // 0' 2>/dev/null)

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
    elif (( has_python )); then
        _loading2 "Entrypoints"
        print -r -- "$overview" | python3 -c '
import json
import sys

try:
    overview = json.load(sys.stdin)
except Exception:
    sys.exit(0)

entrypoints = overview.get("entryPoints") or {}
if not entrypoints:
    print("  No entrypoints found")
else:
    for name, cfg in entrypoints.items():
        address = (cfg or {}).get("address", "unknown")
        print(f"  {name} -> {address}")

http = overview.get("http") or {}
routers = http.get("routers") or {}
services = http.get("services") or {}

def get_value(data, key):
    value = data.get(key, 0)
    return 0 if value is None else value

print(f"  HTTP Routers: {get_value(routers, \"total\")} total, {get_value(routers, \"errors\")} errors, {get_value(routers, \"warnings\")} warnings")
print(f"  HTTP Services: {get_value(services, \"total\")} total, {get_value(services, \"errors\")} errors, {get_value(services, \"warnings\")} warnings")
'
    fi

    _loading2 "HTTP Routers"
    routers=$(_traefik_status_api_get "$TRAEFIK_API" "/http/routers" 2>/dev/null)
    if [[ -n "$routers" ]]; then
        if (( has_jq )); then
            echo "$routers" | jq -r '.[] | "  [\(.status // "unknown")] \(.name) tls=\(if .tls == null then "no" else "yes" end) ep=\(.entryPoints // ["none"] | join(",")) svc=\(.service // "unknown") mw=\(.middlewares // [] | join(",")) rule=\(.rule // "no rule")"' 2>/dev/null
        elif (( has_python )); then
            print -r -- "$routers" | python3 -c '
import json
import sys

try:
    data = json.load(sys.stdin)
except Exception:
    sys.exit(0)

for router in data or []:
    status = router.get("status", "unknown")
    name = router.get("name", "unknown")
    rule = router.get("rule", "no rule")
    entrypoints = ",".join(router.get("entryPoints") or ["none"])
    tls = "yes" if router.get("tls") is not None else "no"
    service = router.get("service", "unknown")
    middlewares = ",".join(router.get("middlewares") or [])
    print(f"  [{status}] {name} tls={tls} ep={entrypoints} svc={service} mw={middlewares} rule={rule}")
'
        fi
    else
        _loading3 "No HTTP routers found"
    fi

    _loading2 "HTTP Services"
    services=$(_traefik_status_api_get "$TRAEFIK_API" "/http/services" 2>/dev/null)
    if [[ -n "$services" ]]; then
        if (( has_jq )); then
            echo "$services" | jq -r '.[] | "  [\(.status // "unknown")] \(.name) type=\(.type // "unknown")"' 2>/dev/null
        elif (( has_python )); then
            print -r -- "$services" | python3 -c '
import json
import sys

try:
    data = json.load(sys.stdin)
except Exception:
    sys.exit(0)

for service in data or []:
    status = service.get("status", "unknown")
    name = service.get("name", "unknown")
    service_type = service.get("type", "unknown")
    print(f"  [{status}] {name} type={service_type}")
'
        fi
    else
        _loading3 "No HTTP services found"
    fi

    _loading2 "TLS Certificates (ACME)"
    if [[ -f "$DOCKSOFT_CONTAINERS/traefik/acme.json" ]]; then
        if (( has_jq )); then
            cert_count=$(jq '[.letsencrypt.Certificates // [] | length] | add // 0' "$DOCKSOFT_CONTAINERS/traefik/acme.json" 2>/dev/null)
            if [[ "$cert_count" -gt 0 ]]; then
                jq -r '.letsencrypt.Certificates[] | "  \(.domain.main) (SANs: \(.domain.sans // ["none"] | join(", ")))"' "$DOCKSOFT_CONTAINERS/traefik/acme.json" 2>/dev/null
            else
                _loading3 "No certificates issued yet"
            fi
        elif (( has_python )); then
            python3 -c '
import json
import sys

path = sys.argv[1]
try:
    with open(path, "r", encoding="utf-8") as handle:
        data = json.load(handle)
except Exception:
    print("  Unable to parse acme.json")
    sys.exit(0)

letsencrypt = data.get("letsencrypt") or {}
certificates = letsencrypt.get("Certificates") or []
if not certificates:
    print("  No certificates issued yet")
else:
    for certificate in certificates:
        domain = certificate.get("domain") or {}
        main = domain.get("main", "unknown")
        sans = domain.get("sans") or []
        sans_text = ", ".join(sans) if sans else "none"
        print(f"  {main} (SANs: {sans_text})")
' "$DOCKSOFT_CONTAINERS/traefik/acme.json"
        else
            _loading3 "acme.json present but neither jq nor python3 is available to parse it"
        fi
    else
        _loading3 "acme.json not found at $DOCKSOFT_CONTAINERS/traefik/acme.json"
    fi

    _loading2 "Traefik Container"
    container_status=$(docker inspect --format '{{.State.Status}}' traefik 2>/dev/null)
    container_uptime=$(docker inspect --format '{{.State.StartedAt}}' traefik 2>/dev/null)
    container_image=$(docker inspect --format '{{.Config.Image}}' traefik 2>/dev/null)
    _loading3 "Image: $container_image"
    _loading3 "Status: $container_status"
    _loading3 "Started: $container_uptime"

    _loading2 "Recent Errors (last 10)"
    error_logs=$(docker logs traefik --tail 50 2>&1 | grep -i 'level=error\|ERR\|error' | tail -10)
    if [[ -n "$error_logs" ]]; then
        echo "$error_logs"
        if echo "$error_logs" | grep -q 'client version.*is too old\|API version'; then
            echo ""
            _warning "Docker API version mismatch detected!"
            host_api=$(docker version --format '{{.Server.APIVersion}}' 2>/dev/null)
            traefik_image=$(docker inspect --format '{{.Config.Image}}' traefik 2>/dev/null)
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
