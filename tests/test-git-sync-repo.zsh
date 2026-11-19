#!/usr/bin/env zsh
# =============================================================================
# test-git-sync-repo.zsh - Verify the quiet repository sync helper
#
# Covers the 20261105-quiet-repo-updates PGF:
#   1. up to date      -> one "up to date" line, no fetch progress, no hint: block
#   2. behind          -> "updated (+1 commits)", HEAD matches origin/main
#   3. diverged        -> warns, then resets to origin/main (local commit gone)
#   4. dirty worktree  -> refuses, keeps the file, HEAD unchanged
#   5. no upstream     -> one error line, non-zero
#   6. fetch failure   -> one error line carrying the fatal reason, no hint: block
#   7. --optional      -> a plain directory is a skip; without it, a failure
#   8. --quiet         -> no status lines, return code still reports the outcome
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
unset ZSHBOP_UPDATE_VERBOSE

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

source "$ZSHBOP_ROOT/lib/functions.zsh"

# -- Fixtures live outside the checkout and are always removed
TEST_TMP=$(mktemp -d "${TMPDIR:-/tmp}/zshbop-git-sync.XXXXXX")

cleanup () {
    rm -rf "$TEST_TMP"
}
trap cleanup EXIT

gitq () {
    git -c user.email=t@t -c user.name=t -c init.defaultBranch=main "$@"
}

reset_out () {
    OUT=()
    _GIT_SYNC_STATUS=""
    _GIT_SYNC_DETAIL=""
    _GIT_SYNC_REASON=""
}

joined () {
    print -r -- "${(pj:\n:)OUT}"
}

has () {
    [[ "$(joined)" == *"$1"* ]]
}

has_not () {
    [[ "$(joined)" != *"$1"* ]]
}

# -- No git chatter may ever reach the transcript
assert_quiet () {
    local label="$1"
    if has_not "hint:" && has_not "remote:" && has_not "Receiving objects" \
        && has_not "Resolving deltas" && has_not "Enumerating objects"; then
        ok "$label: no fetch progress or hint: output"
    else
        fail "$label: git chatter leaked - $(joined)"
    fi
}

# ---------------------------------------------------------------
# -- Fixture: bare origin, an upstream clone, and a work clone that tracks it
# ---------------------------------------------------------------
make_fixture () {
    local base="$1"
    mkdir -p "$base"
    git init -q --bare "$base/origin.git"
    git clone -q "$base/origin.git" "$base/upstream" 2>/dev/null
    gitq -C "$base/upstream" commit -q --allow-empty -m one
    gitq -C "$base/upstream" checkout -q -B main
    gitq -C "$base/upstream" push -q -u origin main
    git clone -q "$base/origin.git" "$base/work" 2>/dev/null
    return 0
}

push_upstream () {
    local base="$1" message="$2"
    gitq -C "$base/upstream" commit -q --allow-empty -m "$message"
    gitq -C "$base/upstream" push -q origin main
    return 0
}

# ---------------------------------------------------------------
echo "=== Scenario 1: an up-to-date repository reports one line ==="
F="$TEST_TMP/s1"
make_fixture "$F"
reset_out
_git_sync_repo "$F/work"
rc=$?
[[ $rc -eq 0 ]] && ok "returns 0" || fail "returned $rc"
[[ $_GIT_SYNC_STATUS == "current" ]] && ok "status is current" || fail "status is $_GIT_SYNC_STATUS"
has "up to date" && ok "reports 'up to date'" || fail "missing 'up to date': $(joined)"
[[ ${#OUT[@]} -eq 1 ]] && ok "prints exactly one line" || fail "printed ${#OUT[@]} lines"
assert_quiet "up to date"

# ---------------------------------------------------------------
echo "=== Scenario 2: a behind repository fast-forwards ==="
F="$TEST_TMP/s2"
make_fixture "$F"
push_upstream "$F" two
reset_out
_git_sync_repo "$F/work"
rc=$?
[[ $rc -eq 0 ]] && ok "returns 0" || fail "returned $rc"
[[ $_GIT_SYNC_STATUS == "updated" ]] && ok "status is updated" || fail "status is $_GIT_SYNC_STATUS"
has "updated (+1 commits)" && ok "reports 'updated (+1 commits)'" || fail "wrong detail: $(joined)"
[[ "$(git -C "$F/work" rev-parse HEAD)" == "$(git -C "$F/work" rev-parse origin/main)" ]] \
    && ok "HEAD matches origin/main" || fail "HEAD did not move to origin/main"
assert_quiet "updated"

# ---------------------------------------------------------------
echo "=== Scenario 3: a diverged repository is reset to upstream ==="
F="$TEST_TMP/s3"
make_fixture "$F"
gitq -C "$F/work" commit -q --allow-empty -m local-only
push_upstream "$F" remote-only
reset_out
_git_sync_repo "$F/work"
rc=$?
[[ $rc -eq 0 ]] && ok "returns 0" || fail "returned $rc"
[[ $_GIT_SYNC_STATUS == "reset" ]] && ok "status is reset" || fail "status is $_GIT_SYNC_STATUS"
has "diverged (1 local, 1 remote)" && ok "warns that it diverged" || fail "missing divergence warning: $(joined)"
has "reset to origin/main" && ok "reports the reset" || fail "missing reset line: $(joined)"
[[ "$(git -C "$F/work" rev-parse HEAD)" == "$(git -C "$F/work" rev-parse origin/main)" ]] \
    && ok "HEAD matches origin/main" || fail "HEAD is not origin/main"
has_not "local-only" && [[ -z "$(git -C "$F/work" log --oneline --all --grep=local-only)" ]] \
    && ok "the local commit is gone" || fail "the local commit survived the reset"
assert_quiet "reset"

# ---------------------------------------------------------------
echo "=== Scenario 4: a dirty worktree blocks the reset ==="
F="$TEST_TMP/s4"
make_fixture "$F"
gitq -C "$F/work" commit -q --allow-empty -m local-only
push_upstream "$F" remote-only
print -r -- "unsaved" > "$F/work/dirty.txt"
head_before="$(git -C "$F/work" rev-parse HEAD)"
reset_out
_git_sync_repo "$F/work"
rc=$?
[[ $rc -eq 1 ]] && ok "returns 1" || fail "returned $rc"
[[ $_GIT_SYNC_STATUS == "failed" ]] && ok "status is failed" || fail "status is $_GIT_SYNC_STATUS"
has "local changes present" && ok "reports local changes" || fail "missing 'local changes present': $(joined)"
[[ -f "$F/work/dirty.txt" ]] && ok "the dirty file survives" || fail "the dirty file was removed"
[[ "$(git -C "$F/work" rev-parse HEAD)" == "$head_before" ]] \
    && ok "HEAD is unchanged" || fail "HEAD moved despite the dirty tree"

# ---------------------------------------------------------------
echo "=== Scenario 5: a repository with no upstream fails cleanly ==="
F="$TEST_TMP/s5"
mkdir -p "$F/lonely"
gitq -C "$F/lonely" init -q
gitq -C "$F/lonely" commit -q --allow-empty -m only
reset_out
_git_sync_repo "$F/lonely"
rc=$?
[[ $rc -eq 1 ]] && ok "returns 1" || fail "returned $rc"
has "no upstream branch configured" && ok "names the missing upstream" || fail "wrong error: $(joined)"

# ---------------------------------------------------------------
echo "=== Scenario 6: a fetch failure carries one fatal reason ==="
F="$TEST_TMP/s6"
make_fixture "$F"
git -C "$F/work" remote set-url origin "$F/does-not-exist.git"
reset_out
_git_sync_repo "$F/work"
rc=$?
[[ $rc -eq 1 ]] && ok "returns 1" || fail "returned $rc"
[[ $_GIT_SYNC_STATUS == "failed" ]] && ok "status is failed" || fail "status is $_GIT_SYNC_STATUS"
has "fetch failed:" && ok "prefixes the reason with 'fetch failed:'" || fail "missing reason prefix: $(joined)"
has "fatal:" && fail "raw fatal: prefix was not stripped: $(joined)" || ok "strips the raw fatal: prefix"
has_not "hint:" && ok "no hint: advice block" || fail "hint: advice leaked: $(joined)"

# ---------------------------------------------------------------
echo "=== Scenario 7: --optional turns a plain directory into a skip ==="
F="$TEST_TMP/s7"
mkdir -p "$F/plain"
reset_out
_git_sync_repo --optional "$F/plain"
rc=$?
[[ $rc -eq 0 ]] && ok "--optional returns 0" || fail "--optional returned $rc"
[[ $_GIT_SYNC_STATUS == "skipped" ]] && ok "status is skipped" || fail "status is $_GIT_SYNC_STATUS"
has "not a git repository, skipped" && ok "prints the skip line" || fail "wrong line: $(joined)"
reset_out
_git_sync_repo "$F/plain"
rc=$?
[[ $rc -eq 1 ]] && ok "without --optional it fails" || fail "returned $rc"
has "not a git repository" && ok "names the reason" || fail "wrong error: $(joined)"

# ---------------------------------------------------------------
echo "=== Scenario 8: --quiet prints nothing but still sets the status ==="
F="$TEST_TMP/s8"
make_fixture "$F"
push_upstream "$F" two
reset_out
_git_sync_repo --quiet "$F/work"
rc=$?
[[ $rc -eq 0 ]] && ok "returns 0" || fail "returned $rc"
[[ ${#OUT[@]} -eq 0 ]] && ok "prints nothing" || fail "printed ${#OUT[@]} lines: $(joined)"
[[ $_GIT_SYNC_STATUS == "updated" ]] && ok "status is still updated" || fail "status is $_GIT_SYNC_STATUS"
[[ "$(git -C "$F/work" rev-parse HEAD)" == "$(git -C "$F/work" rev-parse origin/main)" ]] \
    && ok "the sync still happened" || fail "the sync did not happen"

# ---------------------------------------------------------------
echo "=== Scenario 9: ZSHBOP_UPDATE_VERBOSE=1 restores the raw git output ==="
F="$TEST_TMP/s9"
make_fixture "$F"
git -C "$F/work" remote set-url origin "$F/does-not-exist.git"
reset_out
raw="$TEST_TMP/s9-raw.txt"
ZSHBOP_UPDATE_VERBOSE=1 _git_sync_repo "$F/work" 2> "$raw"
rc=$?
[[ $rc -eq 1 ]] && ok "still returns 1" || fail "returned $rc"
grep -q 'fatal:' "$raw" && ok "raw git output is shown on stderr" || fail "no raw git output: $(<"$raw")"
has "fetch failed:" && ok "the one-line error is still emitted" || fail "missing the summary error: $(joined)"
unset ZSHBOP_UPDATE_VERBOSE

# ---------------------------------------------------------------
echo ""
echo "Passed: $PASS  Failed: $FAIL"
[[ $FAIL -eq 0 ]] && exit 0 || exit 1
