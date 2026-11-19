#!/usr/bin/env zsh
# =================================================================================================
# -- repo-update.zsh -- Background sync for $ZSHBOP_UPDATE_GIT repositories
# -- A detached worker updates the configured mirrors one at a time; the shell shows
# -- one summary line at the next prompt. No job-table noise, no blocking boot, no
# -- git progress/hint output on the terminal.
# -- State lives in $ZSHBOP_CACHE_DIR/repo-update/ (survives quick and full reloads).
# =================================================================================================
_debug_load

# -- Last known run state, filled by _repo_update_parse_state
typeset -gA _REPO_UPDATE_STATE=()
# -- Resolved repository targets, filled by _repo_update_targets
typeset -ga _REPO_UPDATE_TARGETS=()
# -- Configured entries that resolve to no directory, filled by _repo_update_targets
typeset -ga _REPO_UPDATE_MISSING=()

# ==============================================
# -- _repo_update_state_dir () - state directory in REPLY
# -- Creates the directory on demand; never prints.
# ==============================================
function _repo_update_state_dir () {
    REPLY="${ZSHBOP_CACHE_DIR:-${ZSHBOP_HOME:-$HOME}/.zshbop_cache}/repo-update"
    [[ -d "$REPLY" ]] || mkdir -p "$REPLY" 2>/dev/null
    return 0
}

# ==============================================
# -- _repo_update_write_state () - atomic state writes
# -- Usage: _repo_update_write_state <dir> <file> <content>
# -- Writes a temp file in the same directory, then renames it, so a reader
# -- never sees a half-written file.
# ==============================================
function _repo_update_write_state () {
    local dir="$1" file="$2" content="$3"
    local tmp="$dir/${file}.tmp.$$"

    print -r -- "$content" > "$tmp" || return 1
    mv -f "$tmp" "$dir/$file" || return 1
    return 0
}

# ==============================================
# -- _repo_update_parse_state () - load state into _REPO_UPDATE_STATE
# -- Uses $(<file) so the prompt path never forks.
# ==============================================
function _repo_update_parse_state () {
    local dir="$1" line

    _REPO_UPDATE_STATE=()
    [[ -f "$dir/state" ]] || return 1

    for line in ${(f)"$(<"$dir/state")"}; do
        [[ -z "$line" ]] && continue
        [[ "$line" == *=* ]] || continue
        _REPO_UPDATE_STATE[${line%%=*}]="${line#*=}"
    done

    return 0
}

# ==============================================
# -- _repo_update_targets () - resolve $ZSHBOP_UPDATE_GIT
# -- Absolute paths are used as given, other entries are looked up in $HOME and
# -- then $GIT_HOME. Duplicates collapse; entries that resolve to nothing are
# -- collected in _REPO_UPDATE_MISSING so the worker can report them.
# ==============================================
function _repo_update_targets () {
    local entry candidate
    local -a out
    local -A seen

    _REPO_UPDATE_TARGETS=()
    _REPO_UPDATE_MISSING=()

    for entry in "${ZSHBOP_UPDATE_GIT[@]}"; do
        [[ -z "$entry" ]] && continue
        candidate=""

        if [[ "$entry" == /* ]]; then
            [[ -d "$entry" ]] && candidate="$entry"
        else
            [[ -d "$HOME/$entry" ]] && candidate="$HOME/$entry"
            if [[ -z "$candidate" ]] && [[ -n "$GIT_HOME" ]] && [[ -d "$GIT_HOME/$entry" ]]; then
                candidate="$GIT_HOME/$entry"
            fi
        fi

        if [[ -z "$candidate" ]]; then
            _REPO_UPDATE_MISSING+=("$entry")
            continue
        fi

        candidate="${candidate:A}"
        [[ -n "${seen[$candidate]}" ]] && continue
        seen[$candidate]=1
        out+=("$candidate")
    done

    _REPO_UPDATE_TARGETS=("${out[@]}")
    if (( ${#out} )); then
        print -l -- "${out[@]}"
    fi
    return 0
}

# ==============================================
# -- _repo_update_worker_alive () - is a worker still running?
# -- A recorded worker counts as alive while its pid exists and the run is
# -- younger than $ZSHBOP_UPDATE_GIT_TIMEOUT (default 300s), so one hung
# -- remote can never disable every future run.
# ==============================================
function _repo_update_worker_alive () {
    local dir="$1" pid started now timeout

    [[ -f "$dir/run.pid" ]] || return 1
    pid="$(<"$dir/run.pid")"
    [[ "$pid" == <-> ]] || return 1
    kill -0 "$pid" 2>/dev/null || return 1

    timeout="${ZSHBOP_UPDATE_GIT_TIMEOUT:-300}"
    [[ "$timeout" == <-> ]] || timeout=300

    _repo_update_parse_state "$dir" || return 0
    started="${_REPO_UPDATE_STATE[started]:-}"
    [[ -z "$started" ]] && return 0
    [[ "$started" != <-> ]] && return 0

    zmodload -F zsh/datetime p:EPOCHSECONDS 2>/dev/null
    now="${EPOCHSECONDS:-0}"
    (( now - started > timeout )) && return 1

    return 0
}

# ==============================================
# -- _repo_update_worker () - sync every target, record the result
# -- Runs detached: stdin is /dev/null, stdout/stderr are the run log, and no
# -- command in here may prompt or use a pager.
# ==============================================
function _repo_update_worker () {
    emulate -L zsh
    setopt local_options no_notify no_monitor
    zmodload -F zsh/datetime p:EPOCHSECONDS 2>/dev/null

    local dir="$1"
    shift
    local -a targets=("$@")
    local -a missing=("${_REPO_UPDATE_MISSING[@]}")
    local -a rows=()
    local target label total done_n=0 current=0 updated=0 extras_reset=0 skipped=0 failed=0 rc=0
    local started_at="${EPOCHSECONDS:-0}"

    export GIT_TERMINAL_PROMPT=0
    export GIT_PAGER=cat
    export GIT_OPTIONAL_LOCKS=0
    exec < /dev/null

    total=$(( ${#targets} + ${#missing} ))

    _repo_update_write_state "$dir" state "started=${started_at}
finished=
status=running
total=${total}
done=0
current=0
updated=0
reset=0
skipped=0
failed=0
exit="

    for target in "${targets[@]}"; do
        label="${target/#$HOME/~}"
        _git_sync_repo --quiet --optional "$target"

        case "$_GIT_SYNC_STATUS" in
            current) (( current++ )) ;;
            updated) (( updated++ )) ;;
            reset)   (( extras_reset++ )) ;;
            skipped) (( skipped++ )) ;;
            *)
                (( failed++ ))
                rc=1
                ;;
        esac

        rows+=("${_GIT_SYNC_STATUS:-failed}"$'\t'"${label}"$'\t'"${_GIT_SYNC_DETAIL:-${_GIT_SYNC_REASON:-unknown error}}")
        (( done_n++ ))

        _repo_update_write_state "$dir" state "started=${started_at}
finished=
status=running
total=${total}
done=${done_n}
current=${current}
updated=${updated}
reset=${extras_reset}
skipped=${skipped}
failed=${failed}
exit="
    done

    for target in "${missing[@]}"; do
        (( skipped++ ))
        (( done_n++ ))
        rows+=("skipped"$'\t'"${target}"$'\t'"not found")
        _repo_update_write_state "$dir" state "started=${started_at}
finished=
status=running
total=${total}
done=${done_n}
current=${current}
updated=${updated}
reset=${extras_reset}
skipped=${skipped}
failed=${failed}
exit="
    done

    _repo_update_write_state "$dir" results "${(pj:\n:)rows}"

    _repo_update_write_state "$dir" state "started=${started_at}
finished=${EPOCHSECONDS:-0}
status=done
total=${total}
done=${done_n}
current=${current}
updated=${updated}
reset=${extras_reset}
skipped=${skipped}
failed=${failed}
exit=${rc}"

    return $rc
}

# ==============================================
# -- _repo_update_start () - launch the detached worker
# -- Usage: _repo_update_start [<repo>...]
# -- Returns 0 immediately; prints exactly one line naming the count.
# ==============================================
function _repo_update_start () {
    local dir pid total

    local -a targets=()
    local -a missing=()

    if (( ${#@} )); then
        targets=("$@")
    else
        _repo_update_targets > /dev/null
        targets=("${_REPO_UPDATE_TARGETS[@]}")
        missing=("${_REPO_UPDATE_MISSING[@]}")
    fi

    total=$(( ${#targets} + ${#missing} ))
    if (( total == 0 )); then
        _debug "No \$ZSHBOP_UPDATE_GIT repositories to sync"
        return 0
    fi

    _repo_update_state_dir
    dir="$REPLY"

    if _repo_update_worker_alive "$dir"; then
        _debug "Extra repository sync already running (pid $(<"$dir/run.pid"))"
        return 0
    fi

    _REPO_UPDATE_MISSING=("${missing[@]}")

    rm -f "$dir/state" "$dir/results" "$dir/notified" "$dir/log"

    (
        _repo_update_worker "$dir" "${targets[@]}"
    ) >> "$dir/log" 2>&1 &!
    pid=$!

    _repo_update_write_state "$dir" run.pid "$pid"

    _loading2 "Syncing ${total} extra repositories in the background - 'zb update-status' for progress"
    return 0
}

# ==============================================
# -- _repo_update_summary () - one-line summary in REPLY
# -- Returns 0 when a run has finished (REPLY set, possibly empty when there is
# -- nothing worth saying), 1 while it is still running or never ran.
# -- Fork-free: state is read with $(<file).
# ==============================================
function _repo_update_summary () {
    local dir="$1"
    local -a bits=()
    local current updated extras_reset skipped failed elapsed started finished line

    _repo_update_parse_state "$dir" || return 1
    [[ "${_REPO_UPDATE_STATE[status]:-}" == "done" ]] || return 1

    current="${_REPO_UPDATE_STATE[current]:-0}"
    updated="${_REPO_UPDATE_STATE[updated]:-0}"
    extras_reset="${_REPO_UPDATE_STATE[reset]:-0}"
    skipped="${_REPO_UPDATE_STATE[skipped]:-0}"
    failed="${_REPO_UPDATE_STATE[failed]:-0}"
    started="${_REPO_UPDATE_STATE[started]:-0}"
    finished="${_REPO_UPDATE_STATE[finished]:-0}"

    REPLY=""

    # -- Nothing changed: stay quiet (no "N up to date" line on every login)
    if (( updated + extras_reset + failed == 0 )); then
        return 0
    fi

    (( updated )) && bits+=("${updated} updated")
    (( extras_reset )) && bits+=("${extras_reset} reset")
    (( skipped )) && bits+=("${skipped} skipped")
    (( current )) && bits+=("${current} current")

    if [[ "$started" == <-> ]] && [[ "$finished" == <-> ]]; then
        elapsed=$(( finished - started ))
        (( elapsed >= 1 )) && bits+=("${elapsed}s")
    fi

    line="${(j: · :)bits}"

    if (( failed )); then
        REPLY="${fg[yellow]:-} * Extra repositories: ${failed} failed · ${line} - 'zb update-status' for details${RSC:-}"
    else
        REPLY="${fg[green]:-} * Extra repositories: ${line}${RSC:-}"
    fi

    return 0
}

# ==============================================
# -- _repo_update_notify () - precmd hook: print the summary once
# -- Preserves the previous command's exit status for the prompt.
# ==============================================
function _repo_update_notify () {
    local ret=$?
    local dir

    [[ "${ZSHBOP_UPDATE_GIT_NOTIFY:-1}" == "0" ]] && return $ret
    [[ -n "${ZSHBOP_CACHE_DIR:-}" ]] || return $ret

    dir="${ZSHBOP_CACHE_DIR}/repo-update"
    [[ -f "$dir/state" ]] || return $ret
    [[ -f "$dir/notified" ]] && return $ret

    _repo_update_parse_state "$dir" || return $ret
    [[ "${_REPO_UPDATE_STATE[status]:-}" == "done" ]] || return $ret

    _repo_update_summary "$dir"
    [[ -n "$REPLY" ]] && print -r -- "$REPLY"

    : > "$dir/notified"
    return $ret
}

# ==============================================
# -- init_repo_update () - register the notification hook
# -- Idempotent: the hook is removed before it is added, so repeated reloads
# -- never stack duplicate notifications.
# ==============================================
function init_repo_update () {
    autoload -Uz add-zsh-hook

    add-zsh-hook -d precmd _repo_update_notify 2>/dev/null
    add-zsh-hook precmd _repo_update_notify
    return 0
}

# ==============================================
# -- zshbop_update-status () - report the background sync
# -- Usage: zb update-status [-l|--log] [-j|--json]
# ==============================================
help_zshbop[update-status]='Show the status of the background extra-repository sync'
function zshbop_update-status () {
    local -a opts_help opts_log opts_json
    local dir state started finished rc total done_n current updated extras_reset skipped failed row

    zparseopts -D -E -- h=opts_help -help=opts_help l=opts_log -log=opts_log j=opts_json -json=opts_json

    _zshbop_update_status_usage () {
        echo "Usage: zb update-status [-h|--help] [-l|--log] [-j|--json]"
        echo ""
        echo "Show the state of the background sync of \$ZSHBOP_UPDATE_GIT repositories."
        echo ""
        echo "  -h, --help   Show this help"
        echo "  -l, --log    Tail the last 40 lines of the run log"
        echo "  -j, --json   Machine-readable output"
        echo ""
        echo "Behaviour flags: ZSHBOP_UPDATE_GIT_BACKGROUND=0 (blocking updates),"
        echo "                 ZSHBOP_UPDATE_GIT_NOTIFY=0 (no prompt summary),"
        echo "                 ZSHBOP_UPDATE_GIT_TIMEOUT=<seconds> (stale worker cutoff)."
    }

    if [[ -n $opts_help ]]; then
        _zshbop_update_status_usage
        return 0
    fi

    _repo_update_state_dir
    dir="$REPLY"

    if ! _repo_update_parse_state "$dir"; then
        _loading3 "No background sync has run yet"
        return 0
    fi

    state="${_REPO_UPDATE_STATE[status]:-unknown}"
    started="${_REPO_UPDATE_STATE[started]:-}"
    finished="${_REPO_UPDATE_STATE[finished]:-}"
    rc="${_REPO_UPDATE_STATE[exit]:-0}"
    total="${_REPO_UPDATE_STATE[total]:-0}"
    done_n="${_REPO_UPDATE_STATE[done]:-0}"
    current="${_REPO_UPDATE_STATE[current]:-0}"
    updated="${_REPO_UPDATE_STATE[updated]:-0}"
    extras_reset="${_REPO_UPDATE_STATE[reset]:-0}"
    skipped="${_REPO_UPDATE_STATE[skipped]:-0}"
    failed="${_REPO_UPDATE_STATE[failed]:-0}"

    if [[ -n $opts_json ]]; then
        local -a json_rows=()
        local line st lbl dtl
        if [[ -f "$dir/results" ]]; then
            for line in ${(f)"$(<"$dir/results")"}; do
                [[ -z "$line" ]] && continue
                st="${line%%$'\t'*}"
                line="${line#*$'\t'}"
                lbl="${line%%$'\t'*}"
                dtl="${line#*$'\t'}"
                json_rows+=("{\"repo\":\"${lbl}\",\"status\":\"${st}\",\"detail\":\"${dtl}\"}")
            done
        fi
        print -r -- "{\"state\":\"${state}\",\"started\":\"${started}\",\"finished\":\"${finished}\",\"exit\":${rc:-0},\"total\":${total:-0},\"current\":${current:-0},\"updated\":${updated:-0},\"reset\":${extras_reset:-0},\"skipped\":${skipped:-0},\"failed\":${failed:-0},\"results\":[${(j:,:)json_rows}]}"

        (( ${failed:-0} )) && return 1
        return 0
    fi

    _loading "Extra repository sync"

    if [[ "$state" == "running" ]]; then
        _loading2 "State: running - ${done_n}/${total} done - pid $(<"$dir/run.pid" 2>/dev/null)"
        _repo_update_worker_alive "$dir" || _warning "Worker looks stale (older than \$ZSHBOP_UPDATE_GIT_TIMEOUT) - the next 'zb update' starts a fresh run"
    else
        _loading2 "State: idle - last run exit ${rc} - ${current} current, ${updated} updated, ${extras_reset} reset, ${skipped} skipped, ${failed} failed"
    fi

    if [[ -f "$dir/results" ]]; then
        local row_status row_label row_detail
        for row in ${(f)"$(<"$dir/results")"}; do
            [[ -z "$row" ]] && continue
            row_status="${row%%$'\t'*}"
            row="${row#*$'\t'}"
            row_label="${row%%$'\t'*}"
            row_detail="${row#*$'\t'}"
            _loading3 "${row_label} - ${row_status} (${row_detail})"
        done
    fi

    if [[ -n $opts_log ]]; then
        _loading "Run log (last 40 lines)"
        if [[ -f "$dir/log" ]]; then
            tail -n 40 "$dir/log"
        else
            _loading3 "No run log yet"
        fi
    fi

    (( ${failed:-0} )) && return 1
    return 0
}
