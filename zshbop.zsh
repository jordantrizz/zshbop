#!/usr/bin/env zsh
# =========================================================
# -- zshbop.zsh -- zshbop main file
# -- 
# =========================================================

# ---------------------------
# -- Initilize zshbop
# ---------------------------

# -- Potential zshbop paths, including old zsh path, left over from .zshrc removal
ZSHBOP_PATHS=("$HOME/zshbop" "$HOME/zsh" "$HOME/git/zshbop" "$HOME/git/zsh" "/usr/local/sbin/zshbop" "/usr/local/sbin/zsh")
export ZSHBOP_ROOT=${0:a:h}
export ZSHBOP_VERSION=$(cat ${ZSHBOP_ROOT}/version) # -- Current version installed

# ---------------------------
# ---- Variables
# ---------------------------

# -- autoload
autoload -Uz compinit compdef
compinit

# -- Help arrays
typeset -gA help_files
typeset -gA help_files_description
typeset -gA help_corefunc
typeset -gA help_zshbop

# -- System settings
umask 022
export TERM="xterm-256color"
export LANG="C.UTF-8"
export HISTSIZE=5000
export PAGER='less -Q -j16'
export EDITOR='joe'
export BLOCKSIZE='K'
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8
export LANGUAGE=en_US.UTF-8
export TERM="xterm-256color"
export LANG="C.UTF-8"
export bgnotify_threshold='6' # https://github.com/robbyrussell/oh-my-zsh/tree/master/plugins/bgnotify # -- ohmyzsh specific environment variables
export SSHK="$HOME/.ssh"
export TMP="$HOME/tmp"

# -- zsh sepcific
export ZDOTDIR="${HOME}" # -- Set the ZDOTDIR to $HOME this fixes system wide installs not being able to generate .zwc files for caching

# -- zshbop specific
export ZSHBOP_NAME="zshbop" # -- Current zshbop branch
export SCRIPT_DIR=${0:a:h} # -- Current working directory
export ZSHBOP_CACHE_DIR="${HOME}/.zshbop_cache"
export ZSHBOP_PLUGIN_MANAGER="init_antidote"
export ZSH_ROOT="${ZSHBOP_ROOT}" # -- Converting from ZSH_ROOT to ZSHBOP_ROOT
export ZBR="${ZSHBOP_ROOT}" # -- Short hand $ZSHBOP_ROOT
export KB="${ZSHBOP_ROOT}/kb"
export GIT_HOME="${HOME}/git"
export REPOS_DIR="$ZSHBOP_ROOT/repos"
export RUN_REPORT="0"
export ZSHBOP_RELOAD="0"
typeset -a ZSHBOP_UPDATE_GIT=()

# -- zshbop git
export ZSHBOP_BRANCH=$(git --git-dir=$ZSHBOP_ROOT/.git --work-tree=$ZSHBOP_ROOT rev-parse --abbrev-ref HEAD) # -- current branch
export ZSHBOP_COMMIT=$(git --git-dir=$ZSHBOP_ROOT/.git --work-tree=$ZSHBOP_ROOT rev-parse HEAD) # -- current commit
export ZSHBOP_REPO="jordantrizz/zshbop" # -- Github repository

# -- Associative Arrays
typeset -gA help_custom # -- Set help_custom for custom help files

# -- Required Tools
REQUIRED_SOFTWARE=('jq' 'curl' 'zsh' 'git' 'md5sum' 'sudo' 'screen' 'git' 'joe' 'dnsutils' 
    'net-tools' 'dmidecode' 'virt-what' 'wget' 'unzip' 'zip' 'python3' 'python3-pip'
    'bc' 'whois' 'telnet' 'lynx' 'traceroute' 'mtr' 'mosh' 'tree' 'ncdu' 'fpart'
    'jq')               

# -- Default tools.
DEFAULT_TOOLS=('mosh' 'traceroute' 'mtr' 'pwgen' 'tree' 'ncdu' 'fpart' 'whois' 'pwgen' 'python3-pip' 'joe' )
DEFAULT_TOOLS+=('keychain' 'dnsutils' 'whois' 'gh' 'php-cli' 'telnet' 'lynx' 'jq' 'shellcheck' 'sudo' 'fzf')
EXTRA_TOOLS=('pip' 'npm' 'golang-go' 'net-tools' 'aspell-en')
pip_install=('ngxtop' 'apt-select' 'semgrep')

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


###########################################################
# ---- Debugging and Logging
###########################################################

# --------------------------------
# -- Logging
# --------------------------------
# -- Logging variables for path and file
SCRIPT_LOG_PATH="$HOME" # -- Default log path
SCRIPT_LOG_FILE=".zshbop.log" # -- Default log file
SCRIPT_LOG=${SCRIPT_LOG_PATH}/${SCRIPT_LOG_FILE} # -- Default log path and file

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
# TODO - Allow color in logs while still being able to grep for errors
ZSH_VERBOSE="0"
ZSHBOP_LOGS=""
LOG_MSG=""
[[ -f $ZSHBOP_ROOT/.verbose ]] && export ZSH_VERBOSE=1 || export ZSH_VERBOSE=0 # -- zshbop verbose logging
_log () { LOG_MSG="[LOG] ${1}"; [[ -z $2 ]] && { [[ $ZSH_VERBOSE == 1 ]] && { echo "$LOG_MSG" | tee -a "$SCRIPT_LOG"; } } || { echo "$LOG_MSG" >> "$SCRIPT_LOG"; } } # -- log for core
_error () { ERROR_MSG="$fg[red][ERROR] ${1} ${RSC}"; [[ -z $2 ]] && { echo $ERROR_MSG; echo "[ERROR] $1" >> "$SCRIPT_LOG" } || echo "[ERROR] $1" >> "$SCRIPT_LOG" }
_error2 () { ERROR_MSG="$bg[red][ERROR] ${1} ${RSC}"; [[ -z $2 ]] && { echo $ERROR_MSG; echo "[ERROR] $1" >> "$SCRIPT_LOG" } || echo "[ERROR] $1" >> "$SCRIPT_LOG" }
_warning () { WARN_MSG="$fg[yellow][WARNING] ${1} ${RSC}"; [[ -z $2 ]] && { echo $WARN_MSG; echo "[WARNING] $1" >> "$SCRIPT_LOG" } || echo "[WARNING] $1" >> "$SCRIPT_LOG" }
_alert () { ALERT_MSG="$bg[red] $fg[yellow][ALERT] ${1} ${RSC}"; [[ -z $2 ]] && { echo $ALERT_MSG; echo "[ALERT] $1" >> "$SCRIPT_LOG" } || echo "[ALERT] $1" >> "$SCRIPT_LOG" }
_notice () { NOTICE_MSG="$fg[blue][NOTICE]${1} ${RSC}"; [[ -z $2 ]] && { echo $NOTICE_MSG; echo "[NOTICE] $1" >> "$SCRIPT_LOG" } || echo "[NOTICE] $1" >> "$SCRIPT_LOG" }
_dlog () { _log "${*}"; _debug "${*}" }
_elog () { _log "${*}"; _error "${*}" }

###########################################################
# --- Start zshbop
###########################################################
STARTLOG

# ---------------
# -- Source files
# ---------------
source ${ZSHBOP_ROOT}/lib/init.zsh # -- include init
source ${ZSHBOP_ROOT}/lib/help.zsh # -- include help functions
source ${ZSHBOP_ROOT}/lib/kb.zsh # -- Built in Knolwedge Base

# -- Check for old bits
zshbop_cleanup

###########################################################
###########################################################
# --- DON'T PUT ANYTHING BELOW THIS LINE ---
# -------------------------
# -- Initialize ZSHBOP
# -------------------------
init_zshbop

# -- Check if git-check-exit is set
_log "Checking if \$ZSHBOP_GIT_CHECK is set"
if [[ $ZSHBOP_GIT_CHECK == "1" ]]; then
    _log "Running git-check-exit on logout to check for git changes"
    trap "git-check-exit" EXIT
fi 

STOPLOG
