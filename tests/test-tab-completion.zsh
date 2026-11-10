#!/usr/bin/env zsh
# =============================================================================
# test-tab-completion.zsh - Verify the Tab completion modes
#
# Covers the 20261110-tab-completion-menu-select PGF:
#   1. select : 1 Tab -> common prefix, 2 Tabs -> prefix kept + candidates listed
#   2. select : 3 Tabs -> first candidate, Down moves the highlight
#   3. select : ^G after the menu leaves the common prefix in the buffer
#   4. cycle  : 1 Tab -> first candidate, 2 Tabs -> second (previous behaviour)
#   5. expand : Tabs never put a candidate in the buffer
#   6. #      : the opencode query branch replaces the buffer
#   7. mode   : an unknown value warns and falls back to select
#   8. plain  : without opencode the widget is bound directly
#
# Runs the real _zshbop_bind_tab_completion in an isolated interactive zsh over
# zpty; it never boots the full zshbop config and needs no network.
# =============================================================================

setopt no_monitor 2>/dev/null

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

if ! zmodload zsh/zpty 2>/dev/null; then
    echo "SKIP: zsh/zpty is not available"
    exit 0
fi

WORK="$(mktemp -d "${TMPDIR:-/tmp}/zshbop-tab.XXXXXX")"
trap 'zpty -d pty 2>/dev/null; rm -rf "$WORK"' EXIT

ZDOTDIR="$WORK/zdotdir"
BINDIR="$WORK/bin"
LOG="$WORK/buffer.log"
mkdir -p "$ZDOTDIR" "$BINDIR"

# -- A fake `opencode` binary so the AI branch is taken when wanted
print -r -- '#!/bin/sh' > "$BINDIR/opencode"
print -r -- 'exit 0' >> "$BINDIR/opencode"
chmod +x "$BINDIR/opencode"

# -- Extract the binder (and its widget helper) from the real source
BINDER_SNIPPET="$(sed -n '/^# -- _zshbop_tab_complete_widget/,/^INIT_LAST_CORE+=/p' "$ZSHBOP_ROOT/cmds/cmds-zsh.zsh")"
if [[ -z "$BINDER_SNIPPET" ]]; then
    echo "FAIL: could not extract the binder from $ZSHBOP_ROOT/cmds/cmds-zsh.zsh"
    exit 1
fi

# -- Isolated zshrc: completion, a compadd completer, a #-query stub and a
# -- ^X^B widget that dumps $BUFFER so a scenario can read the command line.
cat > "$ZDOTDIR/.zshrc" <<'RC'
PS1='Z> '
precmd () { print -r -- '@@READY@@' }
autoload -Uz compinit && compinit
_debug () { : }
_warning () { print -r -- "[warning] $*" >> "$DUMP_LOG" }
_fake () { compadd vm2-small.runlocalsrv.com vm2-vh1-sydseast-large.ebundanthost.com vm2-vh1-uswest-large.optikhosting.com }
compdef _fake probe
_zshbop_opencode_query () { print -r -- 'echo stubbed-ai' }
_dump_buffer () { print -r -- "$BUFFER" >> "$DUMP_LOG" }
zle -N _dump_buffer
bindkey '^X^B' _dump_buffer
RC
print -r -- "$BINDER_SNIPPET" >> "$ZDOTDIR/.zshrc"
print -r -- '_zshbop_bind_tab_completion' >> "$ZDOTDIR/.zshrc"

OUT=''

# -- _start <mode> <with-opencode:1|0> - boot one isolated interactive shell
_start () {
    local mode="$1" with_opencode="$2" child_path
    if [[ "$with_opencode" == "1" ]]; then
        child_path="$BINDIR:/usr/bin:/bin"
    else
        child_path="/usr/bin:/bin"
    fi
    : > "$LOG"
    zpty -d pty 2>/dev/null
    zpty -b pty "env -i HOME='$WORK' TERM=xterm PATH='$child_path' ZDOTDIR='$ZDOTDIR' DUMP_LOG='$LOG' ZSHBOP_TAB_COMPLETE_MODE='$mode' zsh -i"
    _boot
}

# -- _boot - wait for the first prompt marker
_boot () {
    local chunk
    local -i i
    OUT=''
    for (( i = 0; i < 200; i++ )); do
        while zpty -rt pty chunk 2>/dev/null; do OUT+="$chunk"; done
        [[ "$OUT" == *'@@READY@@'* ]] && return 0
        sleep 0.05
    done
    return 1
}

# -- _settle [ticks] - read whatever the shell emits for a moment
_settle () {
    local chunk
    local -i i
    for (( i = 0; i < ${1:-10}; i++ )); do
        while zpty -rt pty chunk 2>/dev/null; do OUT+="$chunk"; done
        sleep 0.05
    done
}

# -- _send <keys> [ticks] - type keys and let the shell react
_send () {
    OUT=''
    zpty -w -n pty "$1"
    _settle "${2:-10}"
}

# -- _buffer - dump $BUFFER through the ^X^B widget and return the last line
_buffer () {
    _send $'\x18\x02' 12 >/dev/null
    local line
    line="$(tail -n 1 "$LOG" 2>/dev/null)"
    _send $'\x15' 6 >/dev/null
    print -r -- "$line"
}

# -- _stop - close the pty
_stop () {
    zpty -d pty 2>/dev/null
    sleep 0.1
}

# ---------------------------------------------------------------
echo "=== Scenario 1: select - prefix, then list, buffer stays put ==="
_start select 1
_send 'probe vm2'
[[ "$(_buffer)" == 'probe vm2' ]] && ok "baseline buffer is 'probe vm2'" || fail "baseline buffer: '$(_buffer)'"
_send 'probe vm2'
_send $'\t'
[[ "$(_buffer)" == 'probe vm2-' ]] && ok "1 Tab completes to the common prefix" || fail "1 Tab buffer: '$(_buffer)'"
_send 'probe vm2'
_send $'\t\t'
buf="$(_buffer)"
[[ "$buf" == 'probe vm2-' ]] && ok "2 Tabs keep the common prefix" || fail "2 Tabs buffer: '$buf'"
_send 'probe vm2'
OUT=''
zpty -w -n pty $'probe vm2\t\t'
_settle 20
[[ "$OUT" == *'vm2-vh1-uswest-large.optikhosting.com'* ]] && ok "2 Tabs list the candidates" || fail "candidates not listed"
_stop

# ---------------------------------------------------------------
echo "=== Scenario 2: select - the menu is selectable ==="
_start select 1
_send 'probe vm2'
_send $'\t\t\t'
buf="$(_buffer)"
[[ "$buf" == 'probe vm2-small.runlocalsrv.com '* ]] && ok "3 Tabs highlight the first candidate" || fail "3 Tabs buffer: '$buf'"
_send 'probe vm2'
_send $'\t\t\t'
_send $'\x1b[B' 12
buf="$(_buffer)"
[[ "$buf" == 'probe vm2-vh1-sydseast-large.ebundanthost.com '* ]] && ok "Down moves the highlight to the second" || fail "Down buffer: '$buf'"
_send 'probe vm2'
_send $'\t\t\t'
_send $'\x1b[B\x1b[B' 12
buf="$(_buffer)"
[[ "$buf" == 'probe vm2-vh1-uswest-large.optikhosting.com '* ]] && ok "Down twice moves to the third" || fail "Down x2 buffer: '$buf'"
_stop

# ---------------------------------------------------------------
echo "=== Scenario 3: select - send-break keeps the prefix ==="
_start select 1
_send 'probe vm2'
_send $'\t\t\t'
_send $'\x07' 12
buf="$(_buffer)"
[[ "$buf" == 'probe vm2-' ]] && ok "^G leaves the common prefix" || fail "^G buffer: '$buf'"
_stop

# ---------------------------------------------------------------
echo "=== Scenario 4: cycle - previous behaviour is preserved ==="
_start cycle 1
_send 'probe vm2'
_send $'\t'
buf="$(_buffer)"
[[ "$buf" == 'probe vm2-small.runlocalsrv.com' ]] && ok "1 Tab inserts the first candidate" || fail "cycle 1 Tab buffer: '$buf'"
_send 'probe vm2'
_send $'\t\t'
buf="$(_buffer)"
[[ "$buf" == 'probe vm2-vh1-sydseast-large.ebundanthost.com' ]] && ok "2 Tabs cycle to the second" || fail "cycle 2 Tabs buffer: '$buf'"
_stop

# ---------------------------------------------------------------
echo "=== Scenario 5: expand - lists but never commits a candidate ==="
_start expand 1
_send 'probe vm2'
_send $'\t\t\t'
buf="$(_buffer)"
[[ "$buf" == 'probe vm2-' ]] && ok "3 Tabs keep the common prefix" || fail "expand buffer: '$buf'"
_stop

# ---------------------------------------------------------------
echo "=== Scenario 6: the # branch still runs the opencode query ==="
_start select 1
_send '# list the files'
_send $'\t' 20
buf="$(_buffer)"
[[ "$buf" == 'echo stubbed-ai' ]] && ok "Tab on a # line replaces the buffer" || fail "# branch buffer: '$buf'"
_stop

# ---------------------------------------------------------------
echo "=== Scenario 7: an unknown mode warns and falls back to select ==="
_start banana 1
_send 'probe vm2'
_send $'\t'
buf="$(_buffer)"
[[ "$buf" == 'probe vm2-' ]] && ok "unknown mode behaves like select" || fail "unknown mode buffer: '$buf'"
if grep -q 'ZSHBOP_TAB_COMPLETE_MODE=.banana. is not select|cycle|expand' "$LOG" 2>/dev/null; then
    ok "unknown mode warns once"
else
    fail "no warning for the unknown mode: $(tail -n 2 "$LOG" 2>/dev/null)"
fi
_stop

# ---------------------------------------------------------------
echo "=== Scenario 8: without opencode the widget is bound directly ==="
_start select 0
_send $'bindkey "^I"\r' 40
[[ "$OUT" == *'expand-or-complete'* ]] && ok "select binds expand-or-complete" || fail "select binding: '$OUT'"
_stop
_start cycle 0
_send $'bindkey "^I"\r' 40
[[ "$OUT" == *'menu-complete'* ]] && ok "cycle binds menu-complete" || fail "cycle binding: '$OUT'"
_stop

# ---------------------------------------------------------------
echo "=== Scenario 9: the binder is inert in a non-interactive shell ==="
if env -i HOME="$WORK" PATH="/usr/bin:/bin" ZSHBOP_TAB_COMPLETE_MODE=select zsh -c "\
$BINDER_SNIPPET
_zshbop_bind_tab_completion" 2>/dev/null; then
    ok "non-interactive call returns 0"
else
    fail "non-interactive call returned non-zero"
fi

# ---------------------------------------------------------------
echo ""
echo "==============================="
echo "Results: $PASS passed, $FAIL failed"
echo "==============================="
[[ $FAIL -eq 0 ]] && exit 0 || exit 1
