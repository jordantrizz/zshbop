# =========================================================
# =========================================================
# -- include.zsh -- zshbop include file
# =========================================================
# =========================================================

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
export EDITOR='joe-wrapper'
export BLOCKSIZE='K'

# Language
export LC_TIME="C.UTF-8"
export LANG=en_US.UTF-8
export LANGUAGE=en_US.UTF-8
export LANG="C.UTF-8"

# -- zsh sepcific
export ZDOTDIR="${ZSHBOP_HOME}" # -- Set the ZDOTDIR to $HOME this fixes system wide installs not being able to generate .zwc files for caching

# -- zshbop specific
export ZSHBOP_NAME="zshbop" # -- Current zshbop branch
export SCRIPT_DIR=${0:a:h} # -- Current working directory
export ZSHBOP_CACHE_DIR="${ZSHBOP_HOME}/.zshbop_cache"
export ZSHBOP_PLUGIN_MANAGER="init_antidote"
export ZSH_ROOT="${ZSHBOP_ROOT}" # -- Converting from ZSH_ROOT to ZSHBOP_ROOT
export ZBR="${ZSHBOP_ROOT}" # -- Short hand $ZSHBOP_ROOT
export KB="${ZSHBOP_ROOT}/kb"
export GIT_HOME="${HOME}/git"
export REPOS_DIR="$ZSHBOP_ROOT/repos"
export RUN_REPORT="0"
export ZSHBOP_RELOAD="0"
typeset -a ZSHBOP_UPDATE_GIT=()
export ZSHBOP_REPO="jordantrizz/zshbop" # -- Github repository 
typeset -a ZSHBOP_LOAD=()
export ZSHBOP_TEMP="$HOME/tmp"
export SSHK="${ZSHBOP_HOME}/.ssh"
export TMP="${ZSHBOP_HOME}/tmp"


# -- Software specific
GIT_CONFIG="${ZSHBOP_HOME}/.gitconfig"
export bgnotify_threshold='6' # https://github.com/robbyrussell/oh-my-zsh/tree/master/plugins/bgnotify # -- ohmyzsh specific environment variables

# -- Required Software
REQUIRED_SOFTWARE=('git' 'zsh' 'wget' 'curl' 'sudo')

# -- Optional Software
OPTIONAL_SOFTWARE=('jq' 'curl' 'zsh' 'git' 'sudo' 'screen' 'wget' 'joe')
OPTIONAL_SOFTWARE+=('dnsutils' 'net-tools' 'dmidecode' 'virt-what' 'wget')
OPTIONAL_SOFTWARE+=('unzip' 'zip' 'bc' 'whois' 'telnet' 'lynx' 'ncdu')
OPTIONAL_SOFTWARE+=('traceroute' 'tree' 'mtr' 'ncdu' 'fpart' 'md5sum')
OPTIONAL_SOFTWARE+=('pwgen' 'tree' 'htop' 'iftop' 'iotop' 'lsof')

# -- Extra Software
EXTRA_SOFTWARE=('fzf' 'shellcheck' 'npm' 'golang-go' 'aspell-en' 'ngxtop')
EXTRA_SOFTWARE+=('apt-select' 'semgrep' 'mosh' 'keychain' 'gh' 'pwgen')
EXTRA_SOFTWARE+=('python3' 'python3-pip' 'php-cli')

# -- Take $EDITOR run it through alias and strip it down
EDITOR_RUN=${${$(alias $EDITOR)#joe=\'}%\'}

# -- fzf keybindings, enable if fzf is available @@ISSUE
#[ -f $ZSH_CUSTOM/.fzf-key-bindings.zsh ] && source $ZSH_CUSTOM/.fzf-key-bindings.zsh;echo "Enabled FZF keybindgs"
####-- diff-so-fancy
# git config --global core.pager "diff-so-fancy | less --tabs=4 -RFX"

# -- OMZ History Plugin
setopt extended_history       # record timestamp of command in HISTFILE
setopt hist_expire_dups_first # delete duplicates first when HISTFILE size exceeds HISTSIZE
setopt hist_ignore_dups       # ignore duplicated commands history list
setopt hist_ignore_space      # ignore commands that start with space
setopt hist_verify            # show command with history expansion to user before running it
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
    echo -e "\e[1;30;40m[$(date)]\e[0m \e[0;35;40m[DEBUG]\e[0m \e[1;30;40m> $SCRIPT_NAME ${funcstack[0]}\e[0m" > "$ZB_LOG"
}
export STARTLOG

# -- Stop log
function STOPLOG() {
 SCRIPT_NAME=$(basename "$0")
 SCRIPT_NAME="${SCRIPT_NAME%.*}"
 export ZB_LOG_STATUS="0"
 echo -e "\e[1;30;40m[$(date)]\e[0m \e[0;35;40m[DEBUG]\e[0m \e[1;30;40m< $SCRIPT_NAME ${funcstack[0]}\e[0m" >> "$ZB_LOG"
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
#_debug () { DEBUG_MSG="\033[36m[DEBUG]: $@\033[0m"; [[ $ZSH_DEBUG == 1 ]] && { echo "$DEBUG_MSG" | tee -a "$ZB_LOG"; } || { echo "$DEBUG_MSG" >> "$ZB_LOG"; } } # -- debug for core
_debug () { [[ $ZSH_DEBUG == 1 ]] && { zb_logger "DEBUG" 1 "$@"; } || { zb_logger "DEBUG" 0 "$@" } } # -- debug for core
_debugf () { DEBUGF_MSG="\033[36m** [DEBUG]: $@\033[0m"; [[ $DEBUGF == 1 ]] && { echo $DEBUGF_MSG | tee -a "$ZB_LOG" >&2; } || { echo "$DEBUGF_MSG" >> "$ZB_LOG"; } } # -- debugf for debugging third party scripts
_debug_load () { _debug "Loading $funcstack" | tee >(sed 's/^/[LOAD] /' >> ${ZB_LOG}) } # -- debug load

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
ZSHBOP_LOGS=""
LOG_MSG=""
[[ -f $ZSHBOP_ROOT/.verbose ]] && export ZSH_VERBOSE=1 || export ZSH_VERBOSE=0 # -- zshbop verbose logging
_log () { zb_logger "LOG" 1 "$@" }
_error () { zb_logger "ERROR" 1 "$@" }
_error2 () { zb_logger "ERROR" 1 "$@" }
_warning () { zb_logger "WARNING" 1 "$@" }
_alert () { zb_logger "ALERT" 1 "$@" }
_notice () { zb_logger "NOTICE" 1 "$@" }
# -- Log to both. # TODO Why?
_dlog () { _log "${*}"; _debug "${*}" }
_elog () { _log "${*}"; _error "${*}" }

# --------------------------------------------------
# -- zshbop_log
# -- args: $1 = LOG_TYPE, $2 - LOG_ECHO = 1, $3 - LOG_MSG
# --------------------------------------------------
function zb_logger() {
    local LOG_TYPE="${1:=LOG}" LOG_ECHO=${2:=1} LOG_MSG="${3}"
    
    function zb_echo () { echo "$LOG_OUTPUT"; }
    function zb_log () { echo "[$LOG_TYPE] $LOG_MSG" >> "$ZB_LOG"; }
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

# ---------------
# -- Source files
# ---------------
source ${ZSHBOP_ROOT}/lib/init.zsh # -- include init
source ${ZSHBOP_ROOT}/lib/help.zsh # -- include help functions
source ${ZSHBOP_ROOT}/lib/kb.zsh # -- Built in Knolwedge Base
