# -----------------------------------------------------------------------------------
# -- zshbop debugging and logging
# -----------------------------------------------------------------------------------
_debug_load

# -- Make directory and log file
mkdir -p "${SCRIPT_LOG_PATH}"
touch ${SCRIPT_LOG_PATH}/${SCRIPT_LOG_FILE}

# -- Start log
function STARTLOG() {
    SCRIPT_NAME=$(basename "$0")
    SCRIPT_NAME="${SCRIPT_NAME%.*}"
    echo -e "\e[1;30;40m[$(date)]\e[0m \e[0;35;40m[DEBUG]\e[0m \e[1;30;40m> $SCRIPT_NAME ${funcstack[0]}\e[0m" > "$SCRIPT_LOG"
}
export STARTLOG

function STOPLOG() {
 SCRIPT_NAME=$(basename "$0")
 SCRIPT_NAME="${SCRIPT_NAME%.*}"
 echo -e "\e[1;30;40m[$(date)]\e[0m \e[0;35;40m[DEBUG]\e[0m \e[1;30;40m< $SCRIPT_NAME ${funcstack[0]}\e[0m" >> "$SCRIPT_LOG"
}
export STOPLOG

# --------------------------------
# -- Debugging
# -- Debug
# --\033[36mThis text is cyan!\033[0m
# -- Debug Levels
# -- 0 - error, warning, alert
# -- 1 - +debug
# --------------------------------
ZSH_DEBUG="0"
DEBUG_MSG=""
DEBUGF_MSG=""
[[ -f $ZSHBOP_ROOT/.debug ]] && export ZSH_DEBUG=1 || export ZSH_DEBUG=0 # -- zshbop debugging
_debug () { DEBUG_MSG="\033[36m[DEBUG]: $@\033[0m"; [[ $ZSH_DEBUG == 1 ]] && { echo "$DEBUG_MSG" | tee -a "$SCRIPT_LOG"; } || { echo "$DEBUG_MSG" >> "$SCRIPT_LOG"; } } # -- debug for core
_debugf () { DEBUGF_MSG="\033[36m** [DEBUG]: $@\033[0m"; [[ $DEBUGF == 1 ]] && { echo $DEBUGF_MSG | tee -a "$SCRIPT_LOG"; } || { echo "$DEBUGF_MSG" >> "$SCRIPT_LOG"; } } # -- debugf for debugging third party scripts
_debug_load () { _debug "Loading $funcstack" | tee >(sed 's/^/[LOAD] /' >> ${SCRIPT_LOG}) } # -- debug load
# -- _debug_all instead of _debug_function
_debug_all () {
        _debug "--------------------------"
        _debug "arguments - $@ | funcstack - $funcstack"
        _debug "ZSH_ARGZERO - $ZSH_ARGZERO | SCRIPT_DIR - $SCRIPT_DIR"
        _debug "--------------------------"
}

# --------------------------------
# -- Logging errors and Warnings
# --------------------------------
#LOG_MSG="\033[30m** : ${*}\033[0m";
ZSH_VERBOSE="0"
ZSHBOP_LOGS=""
LOG_MSG=""
[[ -f $ZSHBOP_ROOT/.verbose ]] && export ZSH_VERBOSE=1 || export ZSH_VERBOSE=0 # -- zshbop verbose logging
_log () { LOG_MSG="${*}"; [[ $ZSH_VERBOSE == 1 ]] && { echo "[LOG] \033[30m** : ${*}\033[0m" | tee -a "$SCRIPT_LOG"; } || { echo "[LOG] $LOG_MSG" >> "$SCRIPT_LOG"; } } # -- log for core
_error () { echo "$fg[red] *[ERROR] $@ ${RSC}" | tee -a "$SCRIPT_LOG"; }
_error2 () { echo "$bg[red] *[ERROR] $@ ${RSC}" | tee -a "$SCRIPT_LOG"; }
_warning () { echo "$fg[yellow] *[WARNING] $@ ${RSC}" | tee -a "$SCRIPT_LOG"; }
_alert () { echo "$bg[red] $fg[yellow] *[ALERT] $@ ${RSC}" | tee -a "$SCRIPT_LOG"; }
_notice () { NOTICE_MSG="$fg[blue] * $@ ${RSC}"; echo "$NOTICE_MSG";echo "[NOTICE] $NOTICE_MSG" >> "$SCRIPT_LOG"; }
_dlog () { _log "${*}"; _debug "${*}" }
_elog () { _log "${*}"; _error "${*}" }