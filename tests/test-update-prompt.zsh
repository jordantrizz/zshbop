#!/usr/bin/env zsh
# =============================================================================
# test-update-prompt.zsh - Verify the interactive MOTD update prompt
#
# Covers the 20260928-interactive-update-prompt PGF:
#   1. guard denies in a non-interactive shell (INTERACTIVE/TTY gate)
#   2. ZSHBOP_UPDATE_PROMPT=0 disables the prompt
#   3. non-writable repo ($ZSHBOP_ROOT/.git) denies
#   4. dirty tree denies; clean tree allows
#   5. allowed + reply y -> zshbop_update then zshbop_reload
#   6. allowed + reply n -> neither runs
#   7. no update available -> no prompt (read not called)
#   8. update fails -> no reload
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
export ZSHBOP_UPDATE_PROMPT=1

# -- Quiet helpers
RSC=""
fg=() ; bg=()
typeset -gA help_checks
_loading () { :; }
_loading2 () { :; }
_loading3 () { :; }
_success () { :; }
_warning () { :; }
_error () { :; }
_log () { :; }
_debug () { :; }
_debug_all () { :; }
_debug_load () { :; }

# -- Source the real implementation
source "$ZSHBOP_ROOT/lib/update-check.zsh" 2>/dev/null

# ---------------------------------------------------------------
echo "=== Scenario 1: non-interactive shell denies the prompt ==="
_zshbop_update_prompt_allowed
[[ $? -eq 1 ]] && ok "guard denies in non-interactive shell" || fail "guard allowed in non-interactive shell"

# ---------------------------------------------------------------
echo "=== Scenario 2: ZSHBOP_UPDATE_PROMPT=0 disables the prompt ==="
# Force the interactive gate open so only the config guard can deny
_zshbop_update_prompt_is_interactive () { return 0 }
ZSHBOP_UPDATE_PROMPT=0
_zshbop_update_prompt_allowed
rc=$?
ZSHBOP_UPDATE_PROMPT=1
[[ $rc -eq 1 ]] && ok "config opt-out denies" || fail "config opt-out ignored"

# ---------------------------------------------------------------
echo "=== Scenario 3: non-writable repo denies ==="
if [[ $EUID -eq 0 ]]; then
    echo "  [SKIP] running as root; permission checks are bypassed"
else
    TMPREPO=$(mktemp -d "${TMPDIR:-/tmp}/zshbop-update-prompt.XXXXXX")
    mkdir -p "$TMPREPO/.git"
    chmod 500 "$TMPREPO/.git"
    SAVE_ROOT="$ZSHBOP_ROOT"
    ZSHBOP_ROOT="$TMPREPO"
    _zshbop_update_prompt_allowed
    rc=$?
    ZSHBOP_ROOT="$SAVE_ROOT"
    chmod 700 "$TMPREPO/.git"; rm -rf "$TMPREPO"
    [[ $rc -eq 1 ]] && ok "non-writable repo denies" || fail "non-writable repo allowed"
fi

# ---------------------------------------------------------------
echo "=== Scenario 4: dirty tree denies, clean tree allows ==="
GIT_STATUS_OUT=""
git () { print -r -- "$GIT_STATUS_OUT"; return 0 }
TMPREPO=$(mktemp -d "${TMPDIR:-/tmp}/zshbop-update-prompt.XXXXXX")
mkdir -p "$TMPREPO/.git"
SAVE_ROOT="$ZSHBOP_ROOT"
ZSHBOP_ROOT="$TMPREPO"
GIT_STATUS_OUT=" M lib/update-check.zsh"
_zshbop_update_prompt_allowed
dirty_rc=$?
GIT_STATUS_OUT=""
_zshbop_update_prompt_allowed
clean_rc=$?
ZSHBOP_ROOT="$SAVE_ROOT"
rm -rf "$TMPREPO"
unfunction git 2>/dev/null
[[ $dirty_rc -eq 1 ]] && ok "dirty tree denies" || fail "dirty tree allowed"
[[ $clean_rc -eq 0 ]] && ok "clean tree allows" || fail "clean tree denied"

# ---------------------------------------------------------------
# -- Stub the check, guard, actions and read for the action scenarios
zshbop-check-update () {
    ZSHBOP_UPDATE_AVAILABLE=$STUB_AVAILABLE
    ZSHBOP_UPDATE_LATEST="9.9.9"
    ZSHBOP_UPDATE_BEHIND=3
}
zshbop_update () { UPDATE_RAN=1; return ${STUB_UPDATE_RC:-0}; }
zshbop_reload () { RELOAD_RAN=1; return 0; }
read () { READ_RAN=1; REPLY="$STUB_REPLY"; return 0; }

echo "=== Scenario 5: reply y runs update then reload ==="
_zshbop_update_prompt_allowed () { return 0 }
STUB_AVAILABLE=1 STUB_REPLY=y STUB_UPDATE_RC=0
UPDATE_RAN= RELOAD_RAN= READ_RAN=
zshbop_update_prompt >/dev/null
[[ "$UPDATE_RAN" == 1 && "$RELOAD_RAN" == 1 ]] && ok "y runs update + reload" || fail "y path: update=$UPDATE_RAN reload=$RELOAD_RAN"

echo "=== Scenario 6: reply n runs neither ==="
STUB_AVAILABLE=1 STUB_REPLY=n
UPDATE_RAN= RELOAD_RAN= READ_RAN=
zshbop_update_prompt >/dev/null
[[ -z "$UPDATE_RAN" && -z "$RELOAD_RAN" ]] && ok "n runs neither" || fail "n path: update=$UPDATE_RAN reload=$RELOAD_RAN"

echo "=== Scenario 7: no update available -> no prompt ==="
STUB_AVAILABLE=0 STUB_REPLY=y
UPDATE_RAN= RELOAD_RAN= READ_RAN=
zshbop_update_prompt >/dev/null
[[ -z "$READ_RAN" ]] && ok "no update -> no prompt" || fail "prompted with no update available"

echo "=== Scenario 8: failed update -> no reload ==="
STUB_AVAILABLE=1 STUB_REPLY=y STUB_UPDATE_RC=1
UPDATE_RAN= RELOAD_RAN= READ_RAN=
zshbop_update_prompt >/dev/null
[[ "$UPDATE_RAN" == 1 && -z "$RELOAD_RAN" ]] && ok "failed update -> no reload" || fail "reload after failure: upd=$UPDATE_RAN reload=$RELOAD_RAN"

# ---------------------------------------------------------------
echo ""
echo "==============================="
echo "Results: $PASS passed, $FAIL failed"
echo "==============================="
[[ $FAIL -eq 0 ]] && exit 0 || exit 1
