#!/usr/bin/env zsh
# =============================================================================
# test-glint-install.zsh - Verify glint install/detection for linux-arm64
#
# Covers the 20260911-fix-glint-arm64-install PGF:
#   1. linux-arm64 + cargo -> cargo install glint, no curl
#   2. linux-arm64 + no cargo -> actionable error, no download
#   3. linux-x86_64 -> curl glint-linux asset to glint-linux_x86_64
#   4. os-binary glint on linux-arm64 with a lingering x86_64 glint-linux ->
#      returns 1 and creates no glint wrapper (exec-format-error guard)
#   5. os-binary glint on linux-x86_64 with glint-linux_x86_64 ->
#      creates glint wrapper invoking glint-linux_x86_64, sets GLINT_CMD
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

# -- Set the root for sourcing
ZSHBOP_ROOT="${ZSHBOP_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
export ZSHBOP_ROOT

# -- Quiet helpers
export ZSH_DEBUG=0
export ZSH_DEBUG_LOG=0
export DEBUGF_LOG=0
export ZSH_VERBOSE=0
export DEBUGF=0

# -- Neutral colour functions (avoid relying on theme files in the test)
RSC=""
fg=() ; bg=()
_loading () { :; }
_loading3 () { :; }
_success () { :; }
_notice () { :; }
_warning () { :; }
_error () { :; }
_log () { :; }
_debug () { :; }
_debugf () { :; }
_debug_all () { :; }
_debug_load () { :; }
_software_chmod () { :; }

typeset -gA help_software help_int

# -- Source the real implementation files first (os-binary lives in functions-internal.zsh)
source "$ZSHBOP_ROOT/lib/functions-internal.zsh" 2>/dev/null
source "$ZSHBOP_ROOT/software/download-installs.zsh" 2>/dev/null

# -- Override the colour/logger helpers (functions-internal.zsh redefines them) so output is silent
_loading () { :; }
_loading3 () { :; }
_success () { :; }
_notice () { :; }
_warning () { :; }
_error () { :; }
_log () { :; }
_debug () { :; }
_debugf () { :; }
_debug_all () { :; }
_debug_load () { :; }
_software_chmod () { :; }

# -- Stubs for external commands (replaceable per scenario)
curl_stub () { CURL_RAN="$CURL_RAN $*"; }
cargo_stub () { CARGO_RAN="$CARGO_RAN $*"; }
command_stub () { return 0; }

# -- Control which binaries "exist" per scenario (overrides the real _cmd_exists)
_cmd_exists () {
    local c="$1"
    if [[ " ${EXISTING_BINS[@]} " == *" $c "* ]]; then
        return 0
    fi
    return 1
}

# -- Re-source the glint install file fresh for each scenario
load_glint () {
    unset GLINT_INSTALLED
    unalias glint 2>/dev/null
    unset GLINT_CMD
    unset CURL_RAN CARGO_RAN
    source "$ZSHBOP_ROOT/software/download-installs.zsh" 2>/dev/null
}

# ---------------------------------------------------------------
echo "=== Scenario 1: linux-arm64 + cargo -> cargo install glint ==="
MACHINE_OS="linux"
MACHINE_OS2="linux-arm64"
ZSHBOP_SOFTWARE_PATH="/tmp/zshbop-glint-test"
functions[cargo]='cargo_stub "$@"'
functions[curl]='curl_stub "$@"'
unset CURL_RAN CARGO_RAN
EXISTING_BINS=(cargo)
load_glint
software_glint
[[ "$CARGO_RAN" == *"install glint"* ]] && ok "cargo install glint invoked" || fail "cargo install glint NOT invoked (got: $CARGO_RAN)"
[[ -z "$CURL_RAN" ]] && ok "no curl download performed" || fail "unexpected curl on arm64 (got: $CURL_RAN)"

# ---------------------------------------------------------------
echo "=== Scenario 2: linux-arm64 + no cargo -> error, no download ==="
unset CURL_RAN CARGO_RAN
EXISTING_BINS=()
ERROR_MSG=""
_error () { ERROR_MSG="$*"; }
load_glint
software_glint
[[ -z "$CURL_RAN" ]] && ok "no curl download performed" || fail "unexpected curl on arm64 (got: $CURL_RAN)"
[[ "$ERROR_MSG" == *"cargo"* ]] && ok "actionable error mentions cargo" || fail "error missing cargo guidance (got: $ERROR_MSG)"
_error () { :; }

# ---------------------------------------------------------------
echo "=== Scenario 3: linux-x86_64 -> curl asset to glint-linux_x86_64 ==="
MACHINE_OS="linux"
MACHINE_OS2="linux-x86_64"
unset CURL_RAN CARGO_RAN
EXISTING_BINS=()
functions[curl]='curl_stub "$@"'
functions[cargo]='cargo_stub "$@"'
load_glint
software_glint
[[ "$CURL_RAN" == *"glint-linux"* ]] && ok "curl downloads glint-linux asset" || fail "curl not called with glint-linux (got: $CURL_RAN)"
[[ "$CURL_RAN" == *"glint-linux_x86_64"* ]] && ok "asset written to glint-linux_x86_64" || fail "not written to glint-linux_x86_64 (got: $CURL_RAN)"

# ---------------------------------------------------------------
echo "=== Scenario 4: os-binary glint, linux-arm64 + lingering x86_64 glint-linux ==="
# Simulate a broken previously-downloaded x86_64 binary present on PATH
MACHINE_OS="linux"
MACHINE_OS2="linux-arm64"
EXISTING_BINS=(glint-linux)
load_glint
unset GLINT_CMD
os-binary glint
rc=$?
[[ $rc -eq 1 ]] && ok "os-binary glint returns 1 on arm64" || fail "os-binary glint returned $rc (expected 1)"
[[ -z ${functions[glint]:-} ]] && ok "no glint wrapper created (no exec-format-error path)" || fail "glint wrapper was created on arm64"

# ---------------------------------------------------------------
echo "=== Scenario 5: os-binary glint, linux-x86_64 + glint-linux_x86_64 ==="
MACHINE_OS="linux"
MACHINE_OS2="linux-x86_64"
EXISTING_BINS=(glint-linux_x86_64)
load_glint
unset GLINT_CMD
os-binary glint
rc=$?
[[ $rc -eq 0 ]] && ok "os-binary glint returns 0 on x86_64" || fail "os-binary glint returned $rc (expected 0)"
[[ "${functions[glint]:-}" == *"glint-linux_x86_64"* ]] && ok "glint wrapper invokes glint-linux_x86_64" || fail "glint wrapper does not invoke glint-linux_x86_64 (got: ${functions[glint]:-})"
[[ "$GLINT_CMD" == "glint-linux_x86_64" ]] && ok "GLINT_CMD set to glint-linux_x86_64" || fail "GLINT_CMD is '$GLINT_CMD'"

# ---------------------------------------------------------------
echo ""
echo "==============================="
echo "Results: $PASS passed, $FAIL failed"
echo "==============================="
[[ $FAIL -eq 0 ]] && exit 0 || exit 1