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
# -- _traefik_status_container_label_source () - Dump every running container's
# -- name, networks and labels as one JSON line, in two constant Docker calls
# ==============================================================================
function _traefik_status_container_label_source () {
    local ids

    ids=$(docker ps -q 2>/dev/null) || return 1
    [[ -z "$ids" ]] && return 0

    docker inspect --format '{"name":{{json .Name}},"networks":{{json .NetworkSettings.Networks}},"labels":{{json .Config.Labels}}}' ${(f)ids} 2>/dev/null
}

# ==============================================================================
# -- _traefik_status_label_rows () - Turn the container dump into tab-separated
# -- label rows: container, router, enabled, network, host, tls, certresolver, port
# ==============================================================================
function _traefik_status_label_rows () {
    local raw="$1"
    local all_flag="${2:-0}"

    [[ "$all_flag" == "1" ]] && all_flag=true || all_flag=false

    if _traefik_status_has_command jq; then
        print -r -- "$raw" | jq -R -r -s --argjson all "$all_flag" '
def e($v): if $v == "true" then "yes" elif $v == "false" then "no" else $v end;

def firstport($l):
  ([ $l | keys[] | select(test("\\.loadbalancer\\.server\\.port$")) | $l[.] ] | .[0] // "-");

def hosts:
  [ scan("Host\\(([^)]*)\\)") ]
  | map(if type == "array" then .[0] else . end)
  | map(split(",")[] | gsub("`"; "") | gsub("\""; "") | gsub("^\\s+|\\s+$"; ""))
  | map(select(length > 0))
  | join(",");

def tls_of($l; $b):
  if ($l | has($b + ".tls")) or ([ $l | keys[] | select(startswith($b + ".tls.")) ] | length > 0)
  then "yes" else "-" end;

split("\n")[] | select(length > 0) | fromjson
| (.name | sub("^/"; "")) as $name
| (.labels // {}) as $l
| ([ (.networks // {}) | keys[] ] | join(",")) as $attached
| ([ $l | keys[] | select(startswith("traefik.http.routers."))
     | capture("^traefik\\.http\\.routers\\.(?<r>[^.]+)\\.") | .r ] | unique) as $routers
| if ($routers | length) == 0 then
    (if $all or ([ $l | keys[] | select(startswith("traefik")) ] | length > 0) then
       [ $name, "-", e($l["traefik.enable"] // "-"),
         ($l["traefik.docker.network"] // (if $attached == "" then "-" else $attached end)),
         "-", "-", "-", firstport($l) ]
     else empty end)
  else
    $routers[] as $r
    | ("traefik.http.routers." + $r) as $b
    | ($l[$b + ".service"] // $r) as $svc
    | [ $name,
        $r,
        e($l["traefik.enable"] // "-"),
        ($l["traefik.docker.network"] // (if $attached == "" then "-" else $attached end)),
        (($l[$b + ".rule"] // "") | hosts | if . == "" then "-" else . end),
        tls_of($l; $b),
        ($l[$b + ".tls.certresolver"] // "-"),
        ($l["traefik.http.services." + $svc + ".loadbalancer.server.port"] // firstport($l)) ]
  end
| @tsv
' 2>/dev/null
        return $?
    elif _traefik_status_has_command python3; then
        print -r -- "$raw" | python3 -c '
import json
import re
import sys

show_all = sys.argv[1] == "1"


def enabled(value):
    if value == "true":
        return "yes"
    if value == "false":
        return "no"
    return value


def hosts(rule):
    names = []
    for group in re.findall(r"Host\(([^)]*)\)", rule or ""):
        for part in group.split(","):
            part = part.strip().strip("`\"")
            if part:
                names.append(part)
    return ",".join(names)


def first_port(labels):
    for key in sorted(labels):
        if key.endswith(".loadbalancer.server.port"):
            return labels[key]
    return "-"


for line in sys.stdin:
    line = line.strip()
    if not line:
        continue
    try:
        container = json.loads(line)
    except ValueError:
        continue
    name = (container.get("name") or "").lstrip("/")
    labels = container.get("labels") or {}
    networks = container.get("networks") or {}
    attached = ",".join(sorted(networks.keys()))
    network = labels.get("traefik.docker.network") or attached or "-"
    routers = sorted({
        match.group(1)
        for key in labels
        for match in [re.match(r"^traefik\.http\.routers\.([^.]+)\.", key)]
        if match
    })
    if not routers:
        if show_all or any(key.startswith("traefik") for key in labels):
            print("\t".join([
                name,
                "-",
                enabled(labels.get("traefik.enable", "-")),
                network,
                "-",
                "-",
                "-",
                first_port(labels),
            ]))
        continue
    for router in routers:
        base = "traefik.http.routers." + router
        service = labels.get(base + ".service") or router
        tls = "-"
        if base + ".tls" in labels or any(key.startswith(base + ".tls.") for key in labels):
            tls = "yes"
        port = labels.get("traefik.http.services." + service + ".loadbalancer.server.port")
        if not port:
            port = first_port(labels)
        print("\t".join([
            name,
            router,
            enabled(labels.get("traefik.enable", "-")),
            network,
            hosts(labels.get(base + ".rule", "")) or "-",
            tls,
            labels.get(base + ".tls.certresolver", "-"),
            port,
        ]))
' "$all_flag"
        return $?
    fi

    return 3
}

# ==============================================================================
# -- _traefik_status_labels_view () - Print the container label table
# ==============================================================================
function _traefik_status_labels_view () {
    local all_flag="${1:-0}"
    local raw rows rc header row_count container_count enabled_count

    if ! _traefik_status_has_command docker; then
        _error "docker is not installed or not in PATH"
        return 1
    fi

    raw=$(_traefik_status_container_label_source)
    rc=$?
    if (( rc != 0 )); then
        _error "Unable to query Docker for running containers"
        return 1
    fi

    if [[ -z "$raw" ]]; then
        _warning "No running containers found"
        return 0
    fi

    rows=$(_traefik_status_label_rows "$raw" "$all_flag" | sort -t $'\t' -k1,1 -k2,2)
    rc=$?
    if (( rc == 3 )); then
        _warning "Neither jq nor python3 is available — showing raw container labels"
        print -r -- "$raw"
        return 0
    fi
    if (( rc != 0 )); then
        _error "Failed to parse container labels"
        return 1
    fi

    if [[ -z "$rows" ]]; then
        _warning "No container declares traefik.* labels (use -a to include every container)"
        return 0
    fi

    header=$'CONTAINER\tROUTER\tENABLED\tNETWORK\tHOST\tTLS\tCERTRESOLVER\tPORT'
    if (( $+commands[column] )); then
        print -r -- "${header}"$'\n'"${rows}" | column -t -s $'\t'
    else
        print -r -- "$header"
        print -r -- "$rows"
    fi

    row_count=$(print -r -- "$rows" | grep -c .)
    container_count=$(print -r -- "$rows" | cut -f1 | sort -u | grep -c .)
    enabled_count=$(print -r -- "$rows" | awk -F'\t' '$3 == "yes" {n++} END {print n+0}')
    _loading3 "$container_count container(s), $row_count router row(s), $enabled_count enabled"
}

# ==============================================================================
# -- traefik-status () - Show Traefik status from the API
# ==============================================================================
help_traefik[traefik-status]='Show Traefik routers, services, certificates, and container labels'
function traefik-status () {
    local -a opts_help opts_raw opts_labels opts_all
    local TRAEFIK_API overview routers services
    local router_total router_errors router_warnings svc_total svc_errors svc_warnings
    local container_status container_uptime container_image error_logs host_api traefik_image
    local ep_names ep ep_addr cert_count
    local has_jq=0
    local has_python=0

    zparseopts -D -E -- \
        h=opts_help -help=opts_help \
        r=opts_raw -raw=opts_raw \
        l=opts_labels -labels=opts_labels \
        a=opts_all -all=opts_all

    if [[ -n $opts_help ]]; then
        echo "Usage: traefik-status [-h|--help] [-l|--labels] [-a|--all] [-r|--raw]"
        echo "  -l, --labels   Show the Traefik labels declared by running containers"
        echo "  -a, --all      With --labels, include containers with no traefik.* labels"
        echo "  -r, --raw      Show raw JSON output"
        echo ""
        echo "Examples:"
        echo "  traefik-status -l"
        echo "  traefik-status -l -a"
        return 0
    fi

    if [[ -n $opts_labels && -n $opts_raw ]]; then
        _error "-l|--labels cannot be combined with -r|--raw"
        return 1
    fi

    if [[ -n $opts_labels ]]; then
        _traefik_status_labels_view "${opts_all:+1}" || return 1
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
            echo "$routers" | jq -r '
                map(
                    . as $router
                    | (($router.entryPoints // ["none"])[]) as $ep
                    | {
                        ep: $ep,
                        tls: (if $router.tls == null then "no" else "yes" end),
                        router: $router
                    }
                )
                | sort_by(.ep, .tls, .router.name)
                | group_by(.ep)[]
                | "  ep=\(.[0].ep)",
                  (
                    group_by(.tls)[]
                    | "    tls=\(.[0].tls)",
                                        (
                                                sort_by(.router.name)[]
                                                | "      [\(.router.status // "unknown")] \(.router.name) svc=\(.router.service // "unknown") mw=\(.router.middlewares // [] | join(",")) rule=\(.router.rule // "no rule")"
                                        )
                  )
            ' 2>/dev/null
        elif (( has_python )); then
            print -r -- "$routers" | python3 -c '
import json
import sys

try:
    data = json.load(sys.stdin)
except Exception:
    sys.exit(0)

grouped = {}
for router in data or []:
    entrypoints = router.get("entryPoints") or ["none"]
    tls = "yes" if router.get("tls") is not None else "no"
    for ep in entrypoints:
        if ep not in grouped:
            grouped[ep] = {"no": [], "yes": []}
        grouped[ep][tls].append(router)

for ep in sorted(grouped):
    print(f"  ep={ep}")
    for tls in ("no", "yes"):
        routers = sorted(grouped[ep][tls], key=lambda item: item.get("name", "unknown"))
        if not routers:
            continue
        print(f"    tls={tls}")
        for router in routers:
            status = router.get("status", "unknown")
            name = router.get("name", "unknown")
            rule = router.get("rule", "no rule")
            service = router.get("service", "unknown")
            middlewares = ",".join(router.get("middlewares") or [])
            print(f"      [{status}] {name} svc={service} mw={middlewares} rule={rule}")
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
