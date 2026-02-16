# =============================================================================
# -- include.zsh -- zshbop include file
# =============================================================================

# -- Potential zshbop paths, including old zsh path, left over from .zshrc removal
ZSHBOP_PATHS=("$HOME/zshbop" "$HOME/zsh" "$HOME/git/zshbop" "$HOME/git/zsh" "/usr/local/sbin/zshbop" "/usr/local/sbin/zsh")
export ZSHBOP_VERSION=$(cat ${ZSHBOP_ROOT}/VERSION) # -- Current version installed
if [[ -w $HOME ]]; then
    export ZSHBOP_HOME="$HOME" # -- zshbop root directory
else
    export ZSHBOP_HOME="$ZSHBOP_ROOT/../" # -- zshbop root directory
fi

# =========================================================
# ---- Variables
# =========================================================

# -- autoload
autoload -Uz compinit compdef
compinit

# -- Help arrays
typeset -gA help_files
typeset -gA help_files_description
typeset -gA help_int
typeset -gA help_core
typeset -gA help_zshbop
typeset -gA help_zshbop_quick
typeset -gA help_checks
typeset -gA help_custom # -- Set help_custom for custom help files

# -- System settings
umask 022
export TERM="xterm-256color"
export HISTSIZE=5000
export PAGER='less -Q -j16'
export EDITOR='joe-wrapper.sh'
export BLOCKSIZE='K'

# Language - check if locale is available before setting
if locale -a 2>/dev/null | grep -q '^en_US\.UTF-8$\|^en_US\.utf8$'; then
    export LC_ALL="en_US.UTF-8"
    export LANG="en_US.UTF-8"
    export LANGUAGE="en_US.UTF-8"
elif locale -a 2>/dev/null | grep -q '^C\.UTF-8$\|^C\.utf8$'; then
    export LC_ALL="C.UTF-8"
    export LANG="C.UTF-8"
    export LANGUAGE="C.UTF-8"
fi
# LC_TIME uses C.UTF-8 for consistent date formatting
if locale -a 2>/dev/null | grep -q '^C\.UTF-8$\|^C\.utf8$'; then
    export LC_TIME="C.UTF-8"
fi

# -- zsh sepcific
export ZDOTDIR="${ZSHBOP_HOME}" # -- Set the ZDOTDIR to $HOME this fixes system wide installs not being able to generate .zwc files for caching

# -- zshbop specific
export ZSHBOP_NAME="zshbop" # -- Current zshbop branch
export SCRIPT_DIR=${0:a:h} # -- Current working directory
export ZSHBOP_CACHE_DIR="${ZSHBOP_HOME}/.zshbop_cache"
export ZSHBOP_PLUGIN_MANAGER="init_antidote"
export ZSHBOP_PLUGIN_ZSH_AI_ENABLE="0"
export ZSHBOP_PLUGIN_ZSH_AUTOCOMPLETE_ENABLE="0"
export ZSH_ROOT="${ZSHBOP_ROOT}" # -- Converting from ZSH_ROOT to ZSHBOP_ROOT
export ZBR="${ZSHBOP_ROOT}" # -- Short hand $ZSHBOP_ROOT
export KB="${ZSHBOP_ROOT}/kb"
export GIT_HOME="${HOME}/git"
export REPOS_DIR="$ZSHBOP_ROOT/repos"
export RUN_REPORT="0"
# Only set ZSHBOP_RELOAD to 0 if not already set (preserve reload flag across exec zsh)
[[ -z "$ZSHBOP_RELOAD" ]] && export ZSHBOP_RELOAD="0"
typeset -a ZSHBOP_UPDATE_GIT=()
export ZSHBOP_REPO="jordantrizz/zshbop" # -- Github repository 
typeset -a ZSHBOP_LOAD=()
export ZSHBOP_TEMP="$HOME/tmp"
export SSHK="${ZSHBOP_HOME}/.ssh"
export TMP="${ZSHBOP_HOME}/tmp"
export INIT_LAST_CORE=()
export INIT_LAST_CUSTOM=()
export DEBUGF="0"

# -- Software specific
GIT_CONFIG="${ZSHBOP_HOME}/.gitconfig"
export bgnotify_threshold='6' # https://github.com/robbyrussell/oh-my-zsh/tree/master/plugins/bgnotify # -- ohmyzsh specific environment variables

# -- Required Software
ZB_REQUIRED_PACKAGES=('git' 'zsh' 'wget' 'curl' 'sudo' 'jq')

# -- Optional Software
ZB_OPTIONAL_PACKAGES=('sudo' 'screen' 'wget' 'joe')
ZB_OPTIONAL_PACKAGES+=('dnsutils' 'net-tools' 'dmidecode' 'virt-what' 'wget')
ZB_OPTIONAL_PACKAGES+=('unzip' 'zip' 'bc' 'whois' 'telnet' 'lynx' 'ncdu')
ZB_OPTIONAL_PACKAGES+=('traceroute' 'tree' 'mtr' 'ncdu' 'fpart' 'md5sum')
ZB_OPTIONAL_PACKAGES+=('pwgen' 'tree' 'htop' 'iftop' 'iotop' 'lsof')

# -- Extra Software
ZB_EXTRA_PACKAGES=('fzf' 'shellcheck' 'npm' 'golang-go' 'aspell-en')
ZB_EXTRA_PACKAGES+=('mosh' 'keychain' 'gh' 'pwgen' 'python3' 'python3-pip')
ZB_EXTRA_PACKAGES+=('php-cli' 'libssl-dev' 'strace')

ZB_BINARIES=('ngxtop' 'apt-select' 'semgrep' 'doge' 'cargo')

# -- Take $EDITOR run it through alias and strip it down
EDITOR_RUN=${${$(alias $EDITOR)#joe=\'}%\'}

# -- fzf keybindings, enable if fzf is available @@ISSUE
#[ -f $ZSH_CUSTOM/.fzf-key-bindings.zsh ] && source $ZSH_CUSTOM/.fzf-key-bindings.zsh;echo "Enabled FZF keybindgs"
####-- diff-so-fancy
# git config --global core.pager "diff-so-fancy | less --tabs=4 -RFX"

# -- OMZ History Plugin
setopt extended_history       # record timestamp of command in HISTFILE
setopt hist_expire_dups_first # delete duplicates first when HISTFILE size exceeds HISTSIZE
setopt hist_ignore_all_dups   # remove older duplicate entries from the history
setopt hist_ignore_dups       # ignore duplicated commands history list
setopt hist_ignore_space      # ignore commands that start with space
setopt hist_reduce_blanks     # remove superfluous blanks from history items
setopt hist_save_no_dups      # do not write a duplicate event to the history file
setopt hist_verify            # show command with history expansion to user before running it
setopt share_history          # share command history data
setopt inc_append_history     # allow multiple terminal sessions to append to one history
setopt share_history          # share command history data

# =========================================================
# -- Debugging and Logging
# =========================================================

# -- Logging
[[ -z $ZB_LOG_PATH ]] && export ZB_LOG_PATH="$ZSHBOP_HOME" # -- Default log path
ZB_LOG_FILE=".zshbop.log" # -- Default log file
export ZB_LOG="${ZB_LOG_PATH}/${ZB_LOG_FILE}" # -- Default log path and file

# -- Make directory and log file
mkdir -p "${ZB_LOG_PATH}"
touch ${ZB_LOG_PATH}/${ZB_LOG_FILE}

# -- Start log
function STARTLOG() {
    SCRIPT_NAME=$(basename "$0")
    SCRIPT_NAME="${SCRIPT_NAME%.*}"
    export ZB_LOG_STATUS="1"
    DEBUG_LOG="$ZB_LOG"
    echo -e "\e[1;30;40m[$(date)]\e[0m \e[0;35;40m[DEBUG]\e[0m \e[1;30;40m> $SCRIPT_NAME ${funcstack[0]}\e[0m" > "$DEBUG_LOG"
}
export STARTLOG

# -- Stop log
function STOPLOG() {
    SCRIPT_NAME=$(basename "$0")
    SCRIPT_NAME="${SCRIPT_NAME%.*}"
    export ZB_LOG_STATUS="0"
    DEBUG_LOG="$ZB_LOG"
    echo -e "\e[1;30;40m[$(date)]\e[0m \e[0;35;40m[DEBUG]\e[0m \e[1;30;40m< $SCRIPT_NAME ${funcstack[0]}\e[0m" >> "$DEBUG_LOG"
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
ZSH_DEBUG_LOG="0"
DEBUGF_LOG="0"
DEBUG_MSG=""
DEBUGF_MSG=""

[[ -f $ZSHBOP_ROOT/.debug ]] && export ZSH_DEBUG=1 || export ZSH_DEBUG=0 # -- zshbop debugging
[[ -f $ZSHBOP_ROOT/.debug_log ]] && export ZSH_DEBUG_LOG=1 || export ZSH_DEBUG_LOG=0 # -- zshbop debugging log
[[ -f $ZSHBOP_ROOT/.debugf_log ]] && export DEBUGF_LOG=1 || export DEBUGF_LOG=0 # -- zshbop debugging log

_debug () { 
    local funcstack="${funcstack[1]}"
    DEBUG_MSG="\033[36m** [DEBUG]: $funcstack -- $@\033[0m";
    # Log to screen
    [[ $ZSH_DEBUG == 1 ]] && echo $DEBUG_MSG
    # Log to file.
    [[ $ZSH_DEBUG_LOG == 1 ]] && zb_logger "DEBUG" 0 "$@"; 
}

_debugf () { 
    # Get previous function calling _debugf
    local funcstack="${funcstack[2]}"
    [[ -z $funcstack ]] && funcstack="${funcstack[1]}"
    DEBUGF_MSG="\033[36m** [DEBUGF]: $funcstack -- $@\033[0m";
    # Echo to screen.
    [[ $DEBUGF == 1 ]] && echo $DEBUGF_MSG >&2
    # Log to file.
    [[ $DEBUGF_LOG == 1 ]] &&  zb_logger "DEBUGF" 0 "$@"; 
}

function _debugf_status () { echo "\$DEBUGF = $DEBUGF" }
function debugf () {    
    if [[ $1 == on ]]; then
        export DEBUGF="1"
        _debugf_status
    elif [[ $1 == off ]]; then
        export DEBUGF="0"
        _debugf_status
    else
        [[ $DEBUGF == 1 ]] && { export DEBUGF="0"; _debugf_status; return 0; }
        [[ $DEBUGF == 0 ]] && { export DEBUGF="1"; _debugf_status; return 0; }  
        export DEBUGF="0"
        echo "Debugging was never set, setting to 0"          
    fi
}

_debug_load () { 
    local MESSAGE="Loading $funcstack"
    local DEBUG_LOAD_MSG="\033[36m** [DEBUG_LOAD]: $MESSAGE \033[0m";
    # Echo to screen.
    [[ $DEBUGF == 1 ]] && echo $DEBUG_LOAD_MSG
    # Log to file.
    [[ $DEBUGF_LOG == 1 ]] &&  zb_logger "DEBUGF" 0 "$MESSAGE"
}

# ================================================
# -- zbdebug
# ================================================
zbdebug () {
    local function=$1
    shift
    export DEBUGF="1"
    "$function" "$@"
    export DEBUGF="0"
}

# -- _debug_all instead of _debug_function
_debug_all () {
        _debug "--------------------------"
        _debug "arguments - $@ | funcstack - $funcstack"
        _debug "ZSH_ARGZERO - $ZSH_ARGZERO | SCRIPT_DIR - $SCRIPT_DIR"
        _debug "--------------------------"
}


# -- Logging errors and Warnings
# TODO - Allow color in logs while still being able to grep for errors
ZSH_VERBOSE="0"
LOG_MSG=""
[[ -f $ZSHBOP_ROOT/.verbose ]] && export ZSH_VERBOSE=1 || export ZSH_VERBOSE=0 # -- zshbop verbose logging
_log () { zb_logger "LOG" 0 "$@" }
_error () { zb_logger "ERROR" 1 "$@" }
_warning () { zb_logger "WARNING" 1 "$@" }
_warning_log () { zb_logger "WARNING" 0 "$@" }
_alert () { zb_logger "ALERT" 1 "$@" }
_notice () { zb_logger "NOTICE" 1 "$@" }
# -- Log to both. # TODO Why?
_dlog () { _log "${*}"; _debug "${*}" }
_elog () { _log "${*}"; _error "${*}" }

# --------------------------------------------------
# -- zb_logger $LOG_TYPE, $LOG_ECHO, $LOG_MSG
# -- args: 
# LOG_TYPE - LOG, ERROR, WARNING, ALERT, NOTICE, DEBUG
# LOG_ECHO - 1 or 0 to echo the message
# LOG_MSG - Message to log
# --------------------------------------------------
function zb_logger () {
    local LOG_TYPE="${1:=LOG}" LOG_ECHO=${2:=1} LOG_MSG="${3}"
    local DEBUG_LOG="$ZB_LOG"
    
    function zb_echo () { echo "$LOG_OUTPUT"; }
    function zb_log () { echo "[$LOG_TYPE] $LOG_MSG" >> "$DEBUG_LOG"; }
    function zb_log_echo () { zb_echo; zb_log; }
    
    # -- Log Types
    [[ $LOG_TYPE == "LOG" ]] && LOG_OUTPUT="[${LOG_TYPE}] ${LOG_MSG}"
    [[ $LOG_TYPE == "ERROR" ]] && LOG_OUTPUT="$fg[red][${LOG_TYPE}] ${LOG_MSG}${RSC}"
    [[ $LOG_TYPE == "WARNING" ]] && LOG_OUTPUT="$fg[yellow][${LOG_TYPE}] ${LOG_MSG}${RSC}"
    [[ $LOG_TYPE == "ALERT" ]] && LOG_OUTPUT="$bg[red] $fg[yellow][${LOG_TYPE}] ${LOG_MSG}${RSC}"
    [[ $LOG_TYPE == "NOTICE" ]] && LOG_OUTPUT="$fg[blue][${LOG_TYPE}] ${LOG_MSG}${RSC}"
    [[ $LOG_TYPE == "DEBUG" ]] && LOG_OUTPUT="$fg[cyan][${LOG_TYPE}] ${LOG_MSG}${RSC}"
    [[ $LOG_TYPE == "DEBUGF" ]] && LOG_OUTPUT="$fg[cyan][${LOG_TYPE}] ${LOG_MSG}${RSC}"    

    if [[ $LOG_TYPE == "LOG" ]]; then
        if [[ $ZSH_VERBOSE == 1 ]]; then
            zb_log_echo            
        fi
    elif [[ $LOG_ECHO == 1 ]]; then
        zb_echo
    fi
    
    # -- Log startup
    if [[ $ZB_LOG_STATUS == "1" ]]; then
        zb_log
    fi
}

# =========================================================
# -- Execution time tracking (for boot and runtime)
# =========================================================
# Load zsh/datetime module for EPOCHREALTIME (microsecond precision)
zmodload zsh/datetime

typeset -gA ZSHBOP_EXEC_TIMES
typeset -gA ZSHBOP_EXEC_START_TIME
typeset -g ZSHBOP_BOOT_START=0

# -- Generic execution time tracking function
# Usage: _track_execution "label" "context" start_time
# - label: descriptive name (e.g., "os-common.zsh", "init_core")
# - context: optional parent context (e.g., "init_os", "")
# - start_time: start time from $EPOCHREALTIME
function _track_execution() {
    local label="${1}"
    local context="${2:-}"
    local start_time="${3}"
    local end_time=$EPOCHREALTIME
    local elapsed=$(printf "%.6f" $((end_time - start_time)))
    
    # Store the time
    local key="${context:+${context}:}${label}"
    ZSHBOP_EXEC_TIMES[$key]=$elapsed
    
    # Format the message
    local msg
    if [[ -n $context ]]; then
        msg="Execution time: ${context}: ${label} took ${elapsed}s"
        local log_msg="[EXEC_TIME]   ${context}: ${label} took ${elapsed}s"
    else
        msg="Execution time: ${label} took ${elapsed}s"
        local log_msg="[EXEC_TIME] ${label} took ${elapsed}s"
    fi
    
    # Log to both debug and file
    _debug "$msg"
    echo "$log_msg" >> "$ZB_LOG"
}

# -- Start tracking execution time
# Usage: _start_execution_timer "label"
function _start_execution_timer() {
    local label="${1}"
    ZSHBOP_EXEC_START_TIME[$label]=$EPOCHREALTIME
}

# -- Simplified wrapper for tracking a step within a function
# Usage: _time_step "description" "parent_function" command args...
# Example: _time_step "os-common.zsh" "init_os" source $ZSHBOP_ROOT/cmds/os-common.zsh
function _time_step() {
    local description="${1}"
    local context="${2}"
    shift 2
    
    local start_time=$EPOCHREALTIME
    "$@"
    local exit_code=$?
    _track_execution "$description" "$context" "$start_time"
    return $exit_code
}

# Backward compatibility aliases for boot time tracking
typeset -gA ZSHBOP_BOOT_TIMES
alias _start_boot_timer='_start_execution_timer'
function _track_boot_time() {
    # Maintain backward compatibility
    local component="${1}"
    local start_time="${2}"
    _track_execution "$component" "" "$start_time"
    # Also store in old format for boot summary
    ZSHBOP_BOOT_TIMES[$component]=${ZSHBOP_EXEC_TIMES[$component]}
}

# ---------------
# -- Source files
# ---------------
source ${ZSHBOP_ROOT}/lib/init.zsh # -- include init
source ${ZSHBOP_ROOT}/lib/help.zsh # -- include help functions
source ${ZSHBOP_ROOT}/lib/kb.zsh # -- Built in Knolwedgeecc Base
