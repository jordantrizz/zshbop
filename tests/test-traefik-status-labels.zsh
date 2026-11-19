#!/usr/bin/env zsh
# =============================================================================
# test-traefik-status-labels.zsh - Offline checks for traefik-status --labels
#
# Covers the 20261119-traefik-status-labels PGF:
#   1. the table header and one row per declared router
#   2. multi-host Host(`a`, `b`) rules are comma-joined
#   3. NETWORK falls back to the container's attached networks
#   4. missing resolver/port render as "-", traefik.enable maps to yes/no
#   5. -a includes containers with no traefik.* labels
#   6. -l refuses -r|--raw
#   7. the python3 path matches the jq path
#   8. the labels path makes exactly two docker calls
#   9. an empty container list warns instead of failing
# =============================================================================

PASS=0
FAIL=0

ok () {
    PASS=$((PASS+1))
    echo "  [PASS] $1"
}
fail () {
    FAIL=$((FAIL+1))
    echo "  [FAIL] $1"
}

ZSHBOP_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
export ZSHBOP_ROOT

# -- Quiet helpers
_debug () { :; }
_loading () { :; }
_loading2 () { :; }
_loading3 () { print -r -- "  $*"; }
_loading4 () { :; }
_success () { :; }
_warning () { print -u2 -r -- "WARN: $*"; }
_error () { print -u2 -r -- "ERR: $*"; }
_log () { :; }
typeset -gA help_files help_traefik

# -- Docker stub served from a fixture; every call is logged
FIXTURE_DIR=$(mktemp -d)
export DOCKER_LOG="$FIXTURE_DIR/calls.log"
: > "$DOCKER_LOG"
EMPTY_DOCKER=0

cat > "$FIXTURE_DIR/containers.jsonl" <<'EOF'
{"name":"/multi","networks":{"proxy":{}},"labels":{"traefik.enable":"true","traefik.docker.network":"proxy","traefik.http.routers.a.rule":"Host(`a.example.com`, `b.example.com`)","traefik.http.routers.a.tls":"true","traefik.http.routers.a.tls.certresolver":"cloudflare","traefik.http.routers.b.rule":"PathPrefix(`/x`)","traefik.http.services.svc.loadbalancer.server.port":"9000"}}
{"name":"/noport","networks":{"host":{},"backend":{}},"labels":{"traefik.enable":"true","traefik.http.routers.noport.rule":"Host(`noport.example.com`)"}}
{"name":"/disabled","networks":{"proxy":{}},"labels":{"traefik.enable":"false"}}
{"name":"/silent","networks":{"bridge":{}},"labels":{"com.docker.compose.project":"x"}}
EOF

docker () {
    print -r -- "$*" >> "$DOCKER_LOG"
    case "$1" in
        ps)
            (( EMPTY_DOCKER )) || print -r -- $'id-multi\nid-noport\nid-disabled\nid-silent'
            ;;
        inspect)
            (( EMPTY_DOCKER )) || cat "$FIXTURE_DIR/containers.jsonl"
            ;;
    esac
}

# -- Source the real implementation
source "$ZSHBOP_ROOT/cmds/cmds-traefik.zsh" 2>/dev/null

# ---------------------------------------------------------------
echo "=== Scenario 1: header and one row per router ==="
out=$(traefik-status -l)
if print -r -- "$out" | head -1 | grep -q '^CONTAINER  *ROUTER  *ENABLED  *NETWORK  *HOST  *TLS  *CERTRESOLVER  *PORT$'; then
    ok "table header is rendered"
else
    fail "table header missing or misordered"
fi
if (( $(print -r -- "$out" | awk -F'[ \t]+' '$2 == "a" || $2 == "b"' | wc -l) == 2 )); then
    ok "one row per declared router"
else
    fail "multi-router container did not produce two rows"
fi

# ---------------------------------------------------------------
echo "=== Scenario 2: multi-host rules ==="
if print -r -- "$out" | grep -q 'a.example.com,b.example.com'; then
    ok "Host() hosts are comma-joined"
else
    fail "multi-host rule was not joined"
fi

# ---------------------------------------------------------------
echo "=== Scenario 3: network fallback ==="
noport_network=$(print -r -- "$out" | awk -F'  +' '$1 == "noport" {print $4}')
if [[ "$noport_network" == "backend,host" || "$noport_network" == "host,backend" ]]; then
    ok "network falls back to attached networks ($noport_network)"
else
    fail "network fallback wrong: '$noport_network'"
fi

# ---------------------------------------------------------------
echo "=== Scenario 4: dashes and enable mapping ==="
noport_port=$(print -r -- "$out" | awk -F'  +' '$1 == "noport" {print $8}')
noport_resolver=$(print -r -- "$out" | awk -F'  +' '$1 == "noport" {print $7}')
disabled_enabled=$(print -r -- "$out" | awk -F'  +' '$1 == "disabled" {print $3}')
[[ "$noport_port" == "-" ]] && ok "missing port renders as -" || fail "port was '$noport_port'"
[[ "$noport_resolver" == "-" ]] && ok "missing resolver renders as -" || fail "resolver was '$noport_resolver'"
[[ "$disabled_enabled" == "no" ]] && ok "traefik.enable=false maps to no" || fail "enabled was '$disabled_enabled'"

# ---------------------------------------------------------------
echo "=== Scenario 5: -a includes unlabeled containers ==="
all_out=$(traefik-status -l -a)
print -r -- "$out" | grep -q '^silent' && fail "silent container leaked into the default view" || ok "default view hides unlabeled containers"
print -r -- "$all_out" | grep -q '^silent' && ok "-a includes the unlabeled container" || fail "-a dropped the unlabeled container"

# ---------------------------------------------------------------
echo "=== Scenario 6: -l refuses -r ==="
traefik-status -l -r >/dev/null 2>&1
[[ $? -eq 1 ]] && ok "-l -r exits 1" || fail "-l -r did not exit 1"

# ---------------------------------------------------------------
echo "=== Scenario 7: python3 path matches jq ==="
py_out=$(
    _traefik_status_has_command () { [[ "$1" != "jq" ]] }
    traefik-status -l
)
if [[ "$py_out" == "$out" ]]; then
    ok "python3 output matches the jq output"
else
    fail "python3 output differs from the jq output"
fi

# ---------------------------------------------------------------
echo "=== Scenario 8: constant docker calls ==="
: > "$DOCKER_LOG"
traefik-status -l >/dev/null 2>&1
calls=$(grep -c . "$DOCKER_LOG")
[[ "$calls" -eq 2 ]] && ok "labels path makes exactly two docker calls" || fail "labels path made $calls docker calls"

# ---------------------------------------------------------------
echo "=== Scenario 9: empty container list ==="
EMPTY_DOCKER=1
empty_out=$(traefik-status -l 2>&1)
empty_rc=$?
EMPTY_DOCKER=0
[[ "$empty_rc" -eq 0 && "$empty_out" == *"No running containers"* ]] \
    && ok "empty docker output warns and exits 0" \
    || fail "empty docker output gave rc=$empty_rc: '$empty_out'"

# ---------------------------------------------------------------
echo "=== Scenario 10: default view and -s ==="
default_out=$(traefik-status 2>&1)
if print -r -- "$default_out" | grep -q '^CONTAINER  *ROUTER'; then
    ok "bare traefik-status prints the label table"
else
    fail "bare traefik-status dropped the label table"
fi
status_out=$(traefik-status -s 2>&1)
if print -r -- "$status_out" | grep -q '^CONTAINER  *ROUTER'; then
    fail "-s still printed the label table"
else
    ok "-s skips the label table"
fi
traefik-status -l -s >/dev/null 2>&1
[[ $? -eq 1 ]] && ok "-l -s exits 1" || fail "-l -s did not exit 1"

# ---------------------------------------------------------------
rm -rf "$FIXTURE_DIR"

echo ""
echo "Passed: $PASS  Failed: $FAIL"
[[ $FAIL -eq 0 ]] && exit 0 || exit 1
