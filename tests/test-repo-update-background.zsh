#!/usr/bin/env zsh
# =============================================================================
# test-repo-update-background.zsh - Verify the background repo-update contract
#
# Covers the 20261106-background-repo-updates PGF:
#   1. the launcher returns immediately and prints exactly one line
#   2. the worker never writes to the caller's stdout/stderr
#   3. the summary prints at the next prompt, exactly once
#   4. an all-current run stays silent
#   5. a failing repository produces a warning summary with the status hint
#   6. a live worker blocks a second launch; a dead/overdue one does not
#   7. ZSHBOP_UPDATE_GIT_NOTIFY=0 silences the summary but keeps results
#   8. ZSHBOP_UPDATE_GIT_BACKGROUND=0 keeps the blocking, non-zero-return path
#   9. `zb update-status` reports state, results and a valid JSON document
#  10. the precmd hook is registered once and preserves the previous status
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

ZSHBOP_ROOT="${ZSHBOP_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
export ZSHBOP_ROOT
export GIT_TERMINAL_PROMPT=0
export ZSHBOP_UPDATE_GIT_NOTIFY=1
export ZSHBOP_UPDATE_GIT_BACKGROUND=1
zmodload -F zsh/datetime p:EPOCHSECONDS 2>/dev/null

# -- Minimal environment (same shape as tests/test-update-prompt.zsh)
RSC=""
typeset -gA fg bg help_checks help_core help_zshbop help_zshbop_quick help_int
fg[green]="" fg[yellow]="" fg[red]="" fg[black]="" fg[white]="" fg[bright-white]="" fg[bright-grey]=""
bg[red]="" bg[green]="" bg[yellow]="" bg[black]="" bg[white]="" bg[bright-grey]="" bg[magenta]=""

typeset -ga OUT
OUT=()

_loading ()  { OUT+=("L1: $*") }
_loading2 () { OUT+=("L2: $*") }
_loading3 () { OUT+=("L3: $*") }
_loading4 () { :; }
_success ()  { OUT+=("OK: $*") }
_warning ()  { OUT+=("WARN: $*") }
_error ()    { OUT+=("ERR: $*") }
_log ()      { :; }
_debug ()    { :; }
_debug_all () { :; }
_debugf ()   { :; }
_debug_load () { :; }

source "$ZSHBOP_ROOT/lib/update-check.zsh" 2>/dev/null
source "$ZSHBOP_ROOT/lib/functions.zsh"
source "$ZSHBOP_ROOT/lib/repo-update.zsh"

# -- Isolated state directory for every scenario
TEST_TMP=$(mktemp -d "${TMPDIR:-/tmp}/zshbop-repo-update.XXXXXX")
export ZSHBOP_CACHE_DIR="$TEST_TMP/cache"
mkdir -p "$ZSHBOP_CACHE_DIR"
STATE_DIR="$ZSHBOP_CACHE_DIR/repo-update"

cleanup () {
    rm -rf "$TEST_TMP"
}
trap cleanup EXIT

gitq () {
    git -c user.email=t@t -c user.name=t -c init.defaultBranch=main "$@"
}

# -- Build a bare origin plus a clone that is one commit behind
make_fixture () {
    local base="$1"
    mkdir -p "$base"
    git init -q --bare "$base/origin.git"
    git clone -q "$base/origin.git" "$base/upstream" 2>/dev/null
    gitq -C "$base/upstream" commit -q --allow-empty -m one
    gitq -C "$base/upstream" checkout -q -B main
    gitq -C "$base/upstream" push -q -u origin main
    git clone -q "$base/origin.git" "$base/behind" 2>/dev/null
    gitq -C "$base/behind" checkout -q -B main origin/main
    gitq -C "$base/upstream" commit -q --allow-empty -m two
    gitq -C "$base/upstream" push -q origin main
    print -r -- "$base/behind"
}

# -- Block until the current worker records status=done (max 8s)
wait_done () {
    local i
    for i in {1..80}; do
        _repo_update_parse_state "$STATE_DIR" 2>/dev/null
        [[ "${_REPO_UPDATE_STATE[status]:-}" == "done" ]] && return 0
        sleep 0.1
    done
    return 1
}

# -- Write a synthetic finished run so summary assertions stay deterministic
write_state () {
    local current="$1" updated="$2" these_reset="$3" skipped="$4" failed="$5" started="${6:-100}" finished="${7:-112}"
    mkdir -p "$STATE_DIR"
    _repo_update_write_state "$STATE_DIR" state "started=${started}
finished=${finished}
status=done
total=$(( current + updated + these_reset + skipped + failed ))
done=$(( current + updated + these_reset + skipped + failed ))
current=${current}
updated=${updated}
reset=${these_reset}
skipped=${skipped}
failed=${failed}
exit=$(( failed > 0 ? 1 : 0 ))"
    rm -f "$STATE_DIR/notified" "$STATE_DIR/results"
}

# ---------------------------------------------------------------
echo "=== Scenario 1: the launcher returns immediately ==="
FIXTURE=$(make_fixture "$TEST_TMP/s1")
_git_sync_repo () { sleep 2; _GIT_SYNC_STATUS=current; _GIT_SYNC_DETAIL="up to date"; return 0 }
ZSHBOP_UPDATE_GIT=("$FIXTURE")
OUT=()
t0=$EPOCHREALTIME
_repo_update_start
t1=$EPOCHREALTIME
elapsed_ms=$(( (t1 - t0) * 1000 ))
if (( elapsed_ms < 250 )); then
    ok "launcher returned in ${elapsed_ms}ms"
else
    fail "launcher blocked for ${elapsed_ms}ms"
fi
if (( ${#OUT} == 1 )) && [[ "$OUT[1]" == L2:*Syncing\ 1\ extra\ repositories* ]]; then
    ok "launcher printed exactly one count line"
else
    fail "launcher output: ${(j:|:)OUT}"
fi
wait_done || true

echo "=== Scenario 2: the worker never writes to the terminal ==="
_git_sync_repo () { print -r -- "LEAK-STDOUT"; print -ru2 -- "LEAK-STDERR"; _GIT_SYNC_STATUS=current; _GIT_SYNC_DETAIL="up to date"; return 0 }
wait_done || true
OUT=()
_repo_update_start
wait_done || true
leaked=0
for line in "${OUT[@]}"; do
    [[ "$line" == *LEAK* ]] && leaked=1
done
if (( leaked == 0 )); then
    ok "worker output did not reach the caller"
else
    fail "worker leaked to the caller: ${(j:|:)OUT}"
fi
if grep -q LEAK-STDERR "$STATE_DIR/log" 2>/dev/null; then
    ok "worker output landed in the run log"
else
    fail "run log missing worker output"
fi

echo "=== Scenario 3: the summary prints once, at the next prompt ==="
write_state 1 2 0 1 0
first=$(_repo_update_notify)
second=$(_repo_update_notify)
if [[ "$first" == *"Extra repositories"* ]] && [[ -z "$second" ]]; then
    ok "summary printed once then stayed silent"
else
    fail "first='${first}' second='${second}'"
fi
if [[ -f "$STATE_DIR/notified" ]]; then
    ok "notified marker written"
else
    fail "notified marker missing"
fi

echo "=== Scenario 4: an all-current run stays silent ==="
write_state 4 0 0 0 0
printed=$(_repo_update_notify)
if [[ -z "$printed" ]]; then
    ok "all-current run printed nothing"
else
    fail "all-current run printed: ${printed}"
fi
if [[ -f "$STATE_DIR/notified" ]]; then
    ok "all-current run still marked notified"
else
    fail "all-current run did not mark notified"
fi

echo "=== Scenario 5: a failure produces a warning summary ==="
write_state 2 1 0 0 1
printed=$(_repo_update_notify)
if [[ "$printed" == *"1 failed"* ]] && [[ "$printed" == *"zb update-status"* ]]; then
    ok "failure summary names the count and the status command"
else
    fail "failure summary: ${printed}"
fi

echo "=== Scenario 6: a live worker blocks a second launch ==="
write_state 1 0 0 0 0 "$EPOCHSECONDS" "$(( EPOCHSECONDS + 1 ))"
_repo_update_write_state "$STATE_DIR" run.pid "$$"
pid_before="$(<"$STATE_DIR/run.pid")"
OUT=()
_git_sync_repo () { sleep 1; _GIT_SYNC_STATUS=current; return 0 }
_repo_update_start
if [[ -z "$OUT" ]] && [[ "$(<"$STATE_DIR/run.pid")" == "$pid_before" ]]; then
    ok "live worker blocked the second launch"
else
    fail "second launch started anyway: ${(j:|:)OUT}"
fi

echo "=== Scenario 7: dead and overdue workers do not block ==="
_repo_update_write_state "$STATE_DIR" run.pid "999999"
if _repo_update_worker_alive "$STATE_DIR"; then
    fail "dead pid counted as alive"
else
    ok "dead pid treated as dead"
fi
_repo_update_write_state "$STATE_DIR" run.pid "$$"
write_state 1 0 0 0 0 1 2
if _repo_update_worker_alive "$STATE_DIR"; then
    fail "overdue worker counted as alive"
else
    ok "worker past ZSHBOP_UPDATE_GIT_TIMEOUT treated as dead"
fi

echo "=== Scenario 8: notify opt-out keeps the results ==="
write_state 1 1 0 0 0
printed=$(ZSHBOP_UPDATE_GIT_NOTIFY=0 _repo_update_notify)
if [[ -z "$printed" ]] && [[ ! -f "$STATE_DIR/notified" ]]; then
    ok "NOTIFY=0 printed nothing and left the run unmarked"
else
    fail "NOTIFY=0 output: ${printed}"
fi

echo "=== Scenario 9: the hook is registered once and preserves \$? ==="
autoload -Uz add-zsh-hook
init_repo_update
init_repo_update
hook_count=$(print -l -- $precmd_functions | grep -c '^_repo_update_notify$')
if (( hook_count == 1 )); then
    ok "hook registered exactly once"
else
    fail "hook registered ${hook_count} times"
fi
write_state 1 1 0 0 0
false
_repo_update_notify > /dev/null
rc=$?
if (( rc == 1 )); then
    ok "hook preserved the previous exit status"
else
    fail "hook returned ${rc} instead of 1"
fi

echo "=== Scenario 10: zb update-status reports state and JSON ==="
write_state 1 1 0 1 1
OUT=()
zshbop_update-status > /dev/null
rc=$?
if (( rc == 1 )); then
    ok "update-status exits 1 with a failed repository"
else
    fail "update-status exit ${rc} with a failure"
fi
json=$(zshbop_update-status -j)
if whence -p python3 > /dev/null; then
    if print -r -- "$json" | python3 -m json.tool > /dev/null 2>&1; then
        ok "update-status -j emits valid JSON"
    else
        fail "update-status -j emitted invalid JSON: $json"
    fi
else
    echo "  [SKIP] python3 not available for JSON validation"
fi
write_state 3 0 0 0 0
zshbop_update-status > /dev/null
rc=$?
if (( rc == 0 )); then
    ok "update-status exits 0 on a clean run"
else
    fail "update-status exit ${rc} on a clean run"
fi

echo "=== Scenario 11: background vs foreground in zshbop_update ==="
FAKE_ROOT="$TEST_TMP/fake-zshbop"
make_fixture "$TEST_TMP/fake-origin" > /dev/null
git clone -q "$TEST_TMP/fake-origin/origin.git" "$FAKE_ROOT" 2>/dev/null
gitq -C "$FAKE_ROOT" checkout -q -B next-release origin/main
gitq -C "$FAKE_ROOT" push -q -u origin next-release
repos () { :; }
zshbop_version () { print -r -- "test-version" }

SAVED_ROOT="$ZSHBOP_ROOT"
SAVED_ZBC="$ZBC"
ZBC=""
ZSHBOP_ROOT="$FAKE_ROOT"
ZSHBOP_UPDATE_GIT=("$FIXTURE")
ZSHBOP_UPDATE_GIT_BACKGROUND=1
rm -rf "$STATE_DIR"
OUT=()
zshbop_update > /dev/null 2>&1
rc=$?
bg_started=0
[[ "${OUT[*]}" == *"Syncing 1 extra repositories in the background"* ]] && bg_started=1
if (( rc == 0 && bg_started == 1 )); then
    ok "background mode returns 0 and queues the sync"
else
    fail "background mode rc=${rc} out=${(j:|:)OUT}"
fi

ZSHBOP_UPDATE_GIT_BACKGROUND=0
ZSHBOP_UPDATE_GIT=("$TEST_TMP/does-not-exist")
OUT=()
zshbop_update > /dev/null 2>&1
rc=$?
if (( rc == 1 )) && [[ "${OUT[*]}" == *"repository(ies) failed to update"* ]]; then
    ok "foreground mode blocks and returns non-zero"
else
    fail "foreground mode rc=${rc} out=${(j:|:)OUT}"
fi

ZSHBOP_UPDATE_GIT_BACKGROUND=1
ZSHBOP_ROOT="$SAVED_ROOT"
ZBC="$SAVED_ZBC"

# ---------------------------------------------------------------
echo ""
echo "==============================="
echo "Results: $PASS passed, $FAIL failed"
echo "==============================="
[[ $FAIL -eq 0 ]] && exit 0 || exit 1
