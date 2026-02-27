# ==============================================================================
# -- _docksoft_traefik_status () - Show Traefik status from API
# ==============================================================================
if [[ "${(t)help_docksoft}" != *association* ]]; then
    unset help_docksoft
    typeset -gA help_docksoft
fi
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
