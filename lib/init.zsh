#!/usr/bin/env zsh
# =================================================================================================
# -- init.zsh - zshbop functions 
# =================================================================================================

# =========================================================
# -- debug_load
# =========================================================
_debug_load
function init_log () {
    local ZSBBOP_FUNC_LOADING="${funcstack[2]}"

    # Check if $ZSBBOP_FUNC_LOADING is already in $ZSHBOP_LOAD
    if [[ " ${ZSHBOP_LOAD[@]} " =~ " ${ZSBBOP_FUNC_LOADING} " ]]; then
        _debug "Already loaded $ZSBBOP_FUNC_LOADING"
    else
        _debug "Loading $ZSBBOP_FUNC_LOADING"
        ZSHBOP_LOAD+=($ZSBBOP_FUNC_LOADING)
    fi
    
    # Track execution time for this component
    if [[ -n ${ZSHBOP_EXEC_START_TIME[$ZSBBOP_FUNC_LOADING]} ]]; then
        local start_time=${ZSHBOP_EXEC_START_TIME[$ZSBBOP_FUNC_LOADING]}
        _track_execution "$ZSBBOP_FUNC_LOADING" "" "$start_time"
        
        # Also populate ZSHBOP_BOOT_TIMES for boot summary
        ZSHBOP_BOOT_TIMES[$ZSBBOP_FUNC_LOADING]=${ZSHBOP_EXEC_TIMES[$ZSBBOP_FUNC_LOADING]}
        
        # Clear the start time
        unset "ZSHBOP_EXEC_START_TIME[$ZSBBOP_FUNC_LOADING]"
    fi
}

# =========================================================
# -- init_core - core functions
# =========================================================
init_core () {
    _debug_all
    _debug "Loading zshbop core"
    export ZSHBOP_BRANCH=$(git --git-dir=$ZSHBOP_ROOT/.git --work-tree=$ZSHBOP_ROOT rev-parse --abbrev-ref HEAD) # -- current branch
    export ZSHBOP_COMMIT=$(git --git-dir=$ZSHBOP_ROOT/.git --work-tree=$ZSHBOP_ROOT rev-parse HEAD) # -- current commit
    source ${ZSHBOP_ROOT}/lib/colors.zsh # -- colors first!
    source ${ZSHBOP_ROOT}/lib/function-overrides.zsh # -- variables
    source ${ZSHBOP_ROOT}/lib/functions-internal.zsh # -- core functions
    init_log
    
}
init_core

# =========================================================
# -- init_include - include files
# =========================================================
init_include () {
    source ${ZSHBOP_ROOT}/lib/functions.zsh # -- zshbop functions
    source ${ZSHBOP_ROOT}/lib/aliases.zsh # -- include aliases
    init_log
}
init_include

# =========================================================
# -- init_path - setup all the required paths.
# =========================================================
init_path () {
	_debug_all

	# Default paths to look for
    init_add_path $HOME/bin:/usr/local/bin:$ZSHBOP_ROOT:$ZSHBOP_ROOT/bin
    init_add_path $HOME/.local/bin
    init_add_path $HOME/.cargo/bin
    init_add_path $HOME/go/bin

	# Extra software
    init_add_path /usr/local/lsws/bin/
    init_add_path /root/.acme.sh/
    init_add_path /opt/netdata/bin

	# Repos - Needs to be updated to find repos installed and add them to $PATH @@ISSUE
	_log "Finding local \$HOME/bin and \$HOME/git and adding to \$PATH"
	init_add_path_dirs $HOME/bin
	init_add_path_dirs $HOME/git
    init_add_path_dirs $ZSHBOP_ROOT/bin
	init_add_path_dirs $ZSHBOP_ROOT/repos

    init_add_path /snap/bin
	
    # -- Add npm global bin path
    init_add_path $HOME/.npm-global/bin
    init_fix_path
    init_log

    # -- Python pyenv
    init_add_path $HOME/.pyenv/bin:$PATH

}

# ==============================================
# -- init_add_path_dirs
# ==============================================
init_add_path_dirs () {
	DIR="$@"
	if [[ -d $DIR ]]; then
		if [ "$(find "$DIR" -mindepth 1 -maxdepth 1 -not -name '.*')" ]; then
        _debug "Adding $DIR to \$PATH"
            i=0
            for NAME in $DIR/*; do
                _debug "$funcstack[1] - found $NAME, adding to \$PATH"
                    init_add_path $NAME
                i=$((i+1))
            done
            _log " Found $i folders and added them to \$PATH"
		fi
	else
		_debug "Can't find $DIR"
	fi
    init_log
}

# =========================================================
# -- init_add_path
# =========================================================
init_add_path () {
    _debug_all
    _debugf "Adding $1 to \$PATH"

    local PATH_ENTRY
    for PATH_ENTRY in ${(s/:/)1}; do
        [[ -z "$PATH_ENTRY" ]] && continue

        if (( ${path[(Ie)$PATH_ENTRY]} )); then
            _debugf "Error - $PATH_ENTRY already in \$PATH"
        else
            path+=("$PATH_ENTRY")
            _debugf "Success - Added $PATH_ENTRY to \$PATH"
        fi
    done

    typeset -gU path PATH
    _debugf "PATH has ${#path[@]} paths"
    init_log
}

# =========================================================
# -- init_fix_path
# -- Go through $PATH and unique it and remove any duplicates
# =========================================================
init_fix_path () {
    _debug_all
    _debugf "Fixing \$PATH"
    typeset -gU path PATH
    path=("${(@s/:/)PATH}")
    _debugf "Fixed \$PATH"
    init_log
}

# =========================================================
# -- init_dirs - setup all the required directories for ZSHBOP
# =========================================================
init_dirs () {
	# Creating $HOME/tmp
	_debug "Creating \$HOME/tmp folder"
	if [[ ! -d $HOME/tmp ]]; then
		mkdir $HOME/tmp > /dev/null
	fi	

	# Creating $ZSHBOP_CACHE_DIR
	_debug "Creating \$ZSHBOP_CACHE_DIR folder"
	if [[ ! -d $ZSHBOP_CACHE_DIR ]]; then
		mkdir $ZSHBOP_CACHE_DIR > /dev/null
	fi
    init_log
}

# ==============================================
# -- init_detectos -- detect the OS running
# ==============================================
init_detectos () {
    # -- Detect operating system        
    export UNAME=$(uname -s)
    case "${UNAME}" in
        Linux*)     MACHINE_OS=linux;;
        Darwin*)    MACHINE_OS=mac;;
        CYGWIN*)    MACHINE_OS=cygwin;;
        MINGW*)     MACHINE_OS=mingw;;
        *)          MACHINE_OS="UNKNOWN:${UNAME}"
    esac


    # -- Check if intel or arm for mac
    if [[ $MACHINE_OS == "mac" ]]; then
        if [[ $(uname -m) == "arm64" ]]; then
            MACHINE_OS2="mac-arm"
        else
            MACHINE_OS2="mac-intel"
        fi
    fi

    # -- Check for WSL and set as MACHINE_OS2
    if [[ $(uname -r) =~ "Microsoft" || $(uname -r) =~ "microsoft" ]]; then
        MACHINE_OS2="wsl"
    fi

    # -- Check for synology and set as MACHINE_OS
    if [[ $(uname -a) =~ "synology" ]]; then
        MACHINE_OS="synology"
    fi
    
    # -- Detect OS Flavour and Version    
    if [[ -e /etc/os-release ]]; then
        source /etc/os-release
        MACHINE_OS_FLAVOUR=$ID
        MACHINE_OS_VERSION=$VERSION_ID
    else
        MACHINE_OS_FLAVOUR="unknown"
    fi

    # -- Install Date
    if [[ $MACHINE_OS == "mac" ]]; then
        OS_INSTALL_DATE=$(stat -f "%Sm" -t "%Y-%m-%d" /var/db/.AppleSetupDone)
        OS_INSTALL_METHOD="macOS stat /var/db/.AppleSetupDone"
    elif [[ $MACHINE_OS == "linux" ]]; then        
        _get-os-install-date 0
    fi
    init_log
}

# ==============================================
# -- Initialize oh-my-zsh plugins
# ==============================================
init_omz_plugins () {
	_debug "Loading OMZ plugins"
	# omz plugin config
    export GIT_AUTO_FETCH_INTERVAL=1200

	# load plugins
	plugins+=(
		aliases
		z
		colored-man-pages
		command-not-found
		encode64
		colorize
		catimg
		dirhistory
		docker
		extract
		genpass
		git-auto-fetch
		history
		mosh
		nmap
		perms
		transfer
		systemadmin
		svn
		screen
		rsync
#		zsh-navigation-tools
		zbell
		wp-cli
		web-search
		urltools
		ufw
		ubuntu        
	)
	export OMZ_PLUGINS=$(echo $plugins | fmt)
	_debug "OMZ plugins - $OMZ_PLUGINS"
	
	# omz plugin config
	export GIT_AUTO_FETCH_INTERVAL=1200
	
	# aliases
	alias genpass="genpass-apple"
    init_log
}

# ==============================================
# -- init_zsh_sweep
# ==============================================
function init_zsh_sweep () {
    [[ "$ZSH_EVAL_CONTEXT" == "toplevel" ]] && DEBUG="1"

    if [[ -d $REPOS_DIR/zsh-sweep ]]; then
        _debug "$REPOS_DIR/zsh-sweep exists, loading"
        export zs_set_path=1 # add to $PATH
        source "${REPOS_DIR}/zsh-sweep/zsh-sweep.plugin.zsh" # Include script
    else
        _debug "There is no $REPOS_DIR/zsh-sweep, run repos pull zsh-sweep"
    fi
    [[ "$ZSH_EVAL_CONTEXT" == "toplevel" ]] && DEBUG="0"
    init_log
}


# ==============================================
# -- powerlevel10k customizations
# ==============================================
function init_p10k () {
	_log "Loading powerlevel10k configuration"
	# shellcheck source=./.p10k.zsh
	source $ZSH_ROOT/.p10k.zsh
	export POWERLEVEL9K_VCS_MAX_SYNC_LATENCY_SECONDS="0" # Don't wait for Git status even for a millisecond, so that prompt always updates
	export POWERLEVEL9K_DISK_USAGE_ONLY_WARNING="true"
	export POWERLEVEL9K_DISK_USAGE_WARNING_LEVEL="90"
    init_log
}

# ==============================================
# -- fzf
# ==============================================
# TODO need to fix
function init_fzf () {
	if _cmd_exists fzf; then
	    _debug "fzf is installed"
	    antigen bundle andrewferrier/fzf-z
	    antigen bundle wfxr/forgit
	    # shellcheck source=./custom/.fzf-key-bindings.zsh
	    source $ZSH_CUSTOM/.fzf-key-bindings.zsh
	else
	    _debug "fzf is not installed, consider it"
	fi
    init_log
}

# ==============================================
# -- Initialize ZSH plugins
# ==============================================
function init_plugins () {
	_log "Loading Plugin Manager, \$ZSHBOP_PLUGIN_MANAGER = $ZSHBOP_PLUGIN_MANAGER"
	if [[ -z ${ZSHBOP_PLUGIN_MANAGER} ]]; then
		init_antigen	
	else
		eval ${ZSHBOP_PLUGIN_MANAGER}
	fi
    init_log
}

# ==============================================
# -- Initialize antidote plugin manager
# ==============================================
function init_antidote () {
	# -- plugin config
	export AUTO_LS_CHPWD="false"

    local antidote_plugins_source="${ZBR}/.zsh_plugins.txt"
    local antidote_plugins_effective="${ZSHBOP_CACHE_DIR}/.zsh_plugins.effective.txt"
    local antidote_plugins_tmp="${ZSHBOP_CACHE_DIR}/.zsh_plugins.tmp.txt"

    cp "${antidote_plugins_source}" "${antidote_plugins_effective}"

    if [[ "${ZSHBOP_PLUGIN_ZSH_AI_ENABLE}" == "1" ]]; then
        _log "Antidote: enabling matheusml/zsh-ai"
    else
        _log "Antidote: disabling matheusml/zsh-ai (set ZSHBOP_PLUGIN_ZSH_AI_ENABLE=1 to enable)"
        awk '!/^[[:space:]]*matheusml\/zsh-ai([[:space:]]|$)/ { print }' "${antidote_plugins_effective}" > "${antidote_plugins_tmp}"
        mv "${antidote_plugins_tmp}" "${antidote_plugins_effective}"
    fi

    if [[ "${ZSHBOP_PLUGIN_ZSH_AUTOCOMPLETE_ENABLE}" == "1" ]]; then
        _log "Antidote: enabling marlonrichert/zsh-autocomplete"
        awk '
            BEGIN { found = 0 }
            /^[[:space:]]*#[[:space:]]*marlonrichert\/zsh-autocomplete([[:space:]]|$)/ {
                print "marlonrichert/zsh-autocomplete"
                found = 1
                next
            }
            /^[[:space:]]*marlonrichert\/zsh-autocomplete([[:space:]]|$)/ {
                print "marlonrichert/zsh-autocomplete"
                found = 1
                next
            }
            { print }
            END {
                if (found == 0) {
                    print "marlonrichert/zsh-autocomplete"
                }
            }
        ' "${antidote_plugins_effective}" > "${antidote_plugins_tmp}"
        mv "${antidote_plugins_tmp}" "${antidote_plugins_effective}"
    else
        _log "Antidote: disabling marlonrichert/zsh-autocomplete (set ZSHBOP_PLUGIN_ZSH_AUTOCOMPLETE_ENABLE=1 to enable)"
        awk '!/^[[:space:]]*marlonrichert\/zsh-autocomplete([[:space:]]|$)/ { print }' "${antidote_plugins_effective}" > "${antidote_plugins_tmp}"
        mv "${antidote_plugins_tmp}" "${antidote_plugins_effective}"
    fi
	
	# -- load antidote
	_log "Loading antidote"
	zstyle ':antidote:bundle' use-friendly-names 'yes' # remove slashes and user friendly names
    zstyle ':antidote:bundle' file "${antidote_plugins_effective}"

    # for H-S-MW
    zstyle :plugin:history-search-multi-word reset-prompt-protect 1
    zstyle ":history-search-multi-word" page-size "8"

	export ANTIDOTE_DIR="${ZBR}/antidote"
    export ANTIDOTE_PLUGINS="${antidote_plugins_effective}"
	export ANTIDOTE_STATIC="${ZSHBOP_CACHE_DIR}/.zsh_plugins.zsh"
    export ANTIDOTE_HOME="${ZSHBOP_HOME}/antidote"
	_debug "ANTIDOTE_PLUGINS: $ANTIDOTE_PLUGINS ANTIDOTE_STATIC:$ANTIDOTE_STATIC"

    # Ensure NVM lazy loads
    export NVM_COMPLETION=true

    # Load antidote
    source $ANTIDOTE_DIR/antidote.zsh
	_log "Generate antidote static file $ANTIDOTE_STATIC"
    antidote bundle < $ANTIDOTE_PLUGINS > $ANTIDOTE_STATIC
    _log "Sourcing antidote static file $ANTIDOTE_STATIC"
    source $ANTIDOTE_STATIC
    init_log
}

# ==============================================
# -- Initialize antigen plugin manager
# ==============================================
function init_antigen () {
	_debug "Loading antigen"
	_loading "Loading antigen"
    if [[ -e $ZSHBOP_ROOT/lib/antigen.zsh ]]; then
        _debug "- Loading antigen from $ZSHBOP_ROOT/lib/antigen.zsh"
        # shellcheck source=./antigen.zsh
        source ${ZSHBOP_ROOT}/lib/antigen.zsh >/dev/null 2>&1
        antigen init ${ZSHBOP_ROOT}/.antigenrc >/dev/null 2>&1
    else
        _echo "	- Couldn't load antigen.."
    fi
init_log
}

# ==============================================
# -- Load os zsh scripts
# ==============================================
function init_os () {
	_debug_all
    _log "Loading OS specific configuration"
    
    # Track timing for common OS configuration using new reusable function
    _time_step "os-common.zsh" "init_os" source $ZSHBOP_ROOT/cmds/os-common.zsh

	# Include OS Specific configuration	
	# -- Mac
	if [[ $MACHINE_OS == "mac" ]] then
        _log "Loading OS Configuration cmds/os-mac.zsh"
        _time_step "os-mac.zsh" "init_os" source $ZSHBOP_ROOT/cmds/os-mac.zsh
    # -- WSL Linux
    elif [[ $MACHINE_OS2 = "wsl" ]]; then
        _log "Loading cmds/os-linux.zsh and cmds/os-wsl.zsh"
        
        _time_step "os-linux.zsh (WSL)" "init_os" source $ZSHBOP_ROOT/cmds/os-linux.zsh
        _time_step "os-wsl.zsh" "init_os" source $ZSHBOP_ROOT/cmds/os-wsl.zsh
        _time_step "init_wsl" "init_os" init_wsl
	# -- Linux
    elif [[ $MACHINE_OS = "linux" ]] then
		_log "Loading cmds/os-linux.zsh"
        _time_step "os-linux.zsh" "init_os" source $ZSHBOP_ROOT/cmds/os-linux.zsh
    elif [[ $MACHINE_OS = "synology" ]] then
		_log "Loading cmds/os-linux.zsh (Synology)"
        _time_step "os-linux.zsh (Synology)" "init_os" source $ZSHBOP_ROOT/cmds/os-linux.zsh
	else
        _log "No OS specific configuration found for MACHINE_OS=$MACHINE_OS"
    fi
    init_log
}

# ==============================================
# -- Load default SSH keys into keychain
# ==============================================
function init_sshkeys () {
    _loading2 "Loading SSH keys"
    _debug_all

    # -- Load SSH keys into keychain
    _dlog "** - init_sskeys - run"

    # -- Check if keychain is installed
    if (( $+commands[keychain] )); then
        _dlog "keychain installed"
        # -- Load default SSH key
        _dlog "- Loading default SSH key into keychain via $HOME/.ssh/id_rsa"
        if [[ -a $HOME/.ssh/id_rsa || -L $HOME/.ssh/id_rsa ]]; then
                _dlog "-- FOUND: $HOME/.ssh/id_rsa"
                eval `keychain -q --eval --agents ssh $HOME/.ssh/id_rsa`
        else
                _dlog "-- NOTFOUND: $HOME/.ssh/id_rsa"
        fi

        # -- Check and load custom SSH key
        _dlog "Loading custom SSH keys into keychain via \$CUSTOM_SSH_KEY"
        if [[ ! -z "${CUSTOM_SSH_KEYS[@]}" ]]; then
            _dlog "- Found \$CUSTOM_SSH_KEYS: ${CUSTOM_SSH_KEYS[@]}"
            for SSH_KEY in ${CUSTOM_SSH_KEYS[@]}; do
                if [[ -f $SSH_KEY ]]; then
                    _dlog "-- Loading -- $SSH_KEY"
                    eval `keychain -q --eval --agents ssh $SSH_KEY`
                    if [[ $? -ne 0 ]]; then
                        _error "-- Can't load $SSH_KEY"
                    fi
                else
                    _error "-- Can't find $SSH_KEY, please check your CUSTOM_SSH_KEY array in .zshbop.conf" 0
                fi
            done
        else
                _dlog "- NOTFOUND: $CUSTOM_SSH_KEYS not set."
        fi

        # Load any id_rsa* keys @@ISSUE
        # TODO figure out why this is @@ISSUE
        _log "Load any id_rsa* keys"
        if [[ $ENABLE_ALL_SSH_KEYS == 1 ]]; then
            eval `keychain -q --eval --agents ssh $HOME/.ssh/id_rsa*`
            eval `keychain -q --eval --agents ssh $HOME/.ssh/client*`
        fi
    else
        _warning_log "Command keychain doesn't exist, please install for SSH keys to work"
    fi
    init_log
}

# ==============================================
# -- init_pkg_manager
# ==============================================
function init_pkg_manager () {
	_debug_all
	_debug "Running on $MACHINE_OS"

    # -- Check for package manager on Linux
	if [[ $MACHINE_OS == "linux" ]] || [[ $MACHINE_OS == "wsl" ]]; then
        # -- Check for apt-get
    	_debug "Checking for Linux package manager apt-get"
        _cmd_exists apt-get
        [[ $? == "0" ]] && _debug "Found apt-get setting \$PKG_MANAGER to apt-get" && export PKG_MANAGER="sudo apt-get" || _debug "apt-get not found"

        # -- Check for yum
        _debug "Checking for Linux package manager yum"
        _cmd_exists yum
        [[ $? == "0" ]] && _debug "Found yum setting \$PKG_MANAGER to yum" && export PKG_MANAGER="sudo yum" || _debug "yum not found"

    # -- Check for package manage on macos
	elif [[ $MACHINE_OS == "mac" ]]; then
		_debug "Checking for Mac package manager"
        # -- Check for brew
        _cmd_exists brew
        if [[ $? == "0" ]]; then
            _debug "Found brew setting \$PKG_MANAGER to brew"
            export PKG_MANAGER="brew"
        fi

        # -- Check for macports
        _cmd_exists port
        if [[ $? == "0" ]]; then
            _debug "Found port setting \$PKG_MANAGER to port"
            export PKG_MANAGER="port"
        fi
	fi
    init_log
}

# ==============================================
# -- init-app-config - set some application configuration
# ==============================================
init-app-config () {    
	_log "Setting application configuration"
	# -- git
    _log "Setting git configuration"
	git config --global init.defaultBranch main 
    init_log
}

# ==============================================
# -- init_zbr_cmds
# ==============================================
function init_zbr_cmds () {
    _log "Loading zshbop cmds...."
   	for CMD_FILE in "${ZSHBOP_ROOT}/cmds/"cmds-*.zsh; do
	  source $CMD_FILE
	done
    init_log
}

# ==============================================
# -- init_app_config
# ==============================================
function init_app_config () {
    _debug_all
    _log "Setting application configuration"
    # git
    git config --global init.defaultBranch main

     # -- set .joe location
    _joe_ftyperc
    init_log
}

# ==============================================
# -- init_checklist - Check services and software
# ==============================================
init_check_software () {
	# -- check if atop is installed
    if _cmd_exists atop; then 
        # -- check if atop is running using ps and pgrep
        pgrep atop >> /dev/null && _success "atop installed and running" 0 || _warning "atop installed but not running, if this is a server install it" 0
    else
        _warning "atop not installed, if this is a server install it" 0
    fi

    # -- check if broot is installed
    check_broot
    init_log
}

# ===============================================
# -- init_check_oom - Check for OOM killer
# ===============================================
function init_check_oom () {
    # -- OOM killer is Linux-specific, skip on other OS
    if [[ $MACHINE_OS != "linux" ]]; then
        _debug "Skipping OOM check on $MACHINE_OS"
        return 0
    fi
    
    # -- Check if OOM killer is running
    local OOM_COUNT
    	# Check if journalctl is installed
	_cmd_exists journalctl
	if [[ $? == 0 ]]; then		
		OOM_COUNT=$(journalctl -k | grep -i 'Out of memory: Killed process' | wc -l)
	elif [[ -f /var/log/syslog ]]; then		
		OOM_COUNT=$(grep -i 'Out of memory: Killed process' /var/log/syslog | wc -l)
		return 1
	else
        _warning "Can't detect OOM killer events"
        return 1
    fi
    
    # -- Check if OOM killer has killed any processes
    if [[ $OOM_COUNT -gt 0 ]]; then
        _warning "OOM killer has killed $OOM_COUNT processes"
    else
        _success "No OOM killer events found"
    fi
    init_log
}

# ==============================================
# -- init_check_services
# ==============================================
function init_check_services () {
    # -- Check system software versions
    _log "Checking system software versions"
    # -- Create an array of commands and versions
    typeset -A check_services
    check_services=(
        # -- system
        [pveversion]="pveversion 2>/dev/null"        
        [mongod]="mongod --version | head -1"
        [nginx]="nginx -v 2>&1"
        [litespeed]="litespeed -v"
        [redis-server]="redis-server --version"
        
    )

    # -- Commands that we want to warn about if installed
    typeset -A warn_commands
    warn_commands=(
        [cloudflared]="cloudflared -v"        
    )


    # -- Check if each command is installed and print version
    for cmd in "${(k)check_services[@]}"; do
        if command -v $cmd &>/dev/null; then
            _success "$cmd: $(eval ${check_services[$cmd]})"
        else
            _log "$cmd not installed"
        fi
    done

    # -- Check for commands that should have warnings
    for cmd in "${(k)warn_commands[@]}"; do
        if command -v $cmd &>/dev/null; then
            _warning "WARNING: ${warn_commands[$cmd]}"
        fi
    done

    # -- mysql
    if command -v mysqld &>/dev/null; then    
        _log "MySQL Server installed"
        _success "MySQL: $(mysqld --version 2> /dev/null)"
    else
        _log "MySQL Server not installed"
        _warning "MySQL not installed, but could be using remote database"
    fi

	# - Netdata    
    if [[ -f /opt/netdata/bin/netdata ]]; then
        export NETDATA_HOME="/opt/netdata/etc/netdata"
    	_success "Netdata: located at /opt/netdata/bin and config at /opt/netdata/etc/netdata"
    elif [[ -f /usr/sbin/netdata ]]; then
        export NETDATA_HOME="/etc/netdata"
    	_success "Netdata: located at /usr/sbin/netdata and config at /etc/netdata"
    else
    	_warning "Netdata not installed"
    fi

    # -- cyberpanel
    if (( $+commands[cyberpanel] )) && _success "Cyberpanel Installed." || _log "Cyberpanel not installed"

    # -- Check custom services if function exists
    if whence -f zb_init_check_services_custom > /dev/null; then
        _debug "zb_init_check_services_custom is defined"
        zb_init_check_services_custom
    else
        _debug "zb_init_check_services_custom is not defined"
    fi

    # -- Docker
    docker-checks
    init_log
}

# ==============================================
# -- init_home_bin - Make sure $ZSHBOP_HOME/bin exists
# ==============================================
function init_home_bin () {
    # -- check if home bin exists
    if [[ -d $ZSHBOP_HOME/bin ]]; then
        _debug "Home bin exists"
    else
        _loading2 "\$ZSHBOP_HOME/bin does not exist...creating home bin"
        mkdir $ZSHBOP_HOME/bin
    fi
    init_log
}

# ==============================================
# -- init_checks
# ==============================================
function init_checks () {
    # Source checks
    typeset -gA help_checks
    for CHECK_FILE in "${ZSHBOP_ROOT}/checks/"checks-*; do
	    source $CHECK_FILE
	done
    
    # Detect OS and run checks.
    if [[ $MACHINE_OS == "mac" ]]; then
        _loading "Running Mac Checks"
        mac-checks        
    fi

    # Detect if VM
    vm-check-detect   
    init_log
}

# ==============================================
# -- init_kb
# ==============================================
function init_kb () {
    local KB_COUNT KB_TOTAL_OUT
    typeset -A kb_totals        
    source "${ZSHBOP_ROOT}/lib/kb.zsh"
    kb_init_topics
    kb_init_aliases
    
    # -- Count how many kb articles there are from array kb_topics
    KB_COUNT="$(echo $kb_topics | wc -w)"
    KB_COUNT=${KB_COUNT##*( )}
    KB_COUNT=${KB_COUNT%%*( )}
    KB_TOTAL_OUT+="Found $KB_COUNT KB articles | "
    
    # -- Count unique tags and print    
    for TAG in $kb_topics_tag; do
        # -- Count unique flags into vars
        kb_totals[$TAG]=$(($kb_totals[$TAG]+1))        
    done

    # -- Print out totals
    for TAG in ${(k)kb_totals}; do
        KB_TOTAL_OUT+="$TAG - $kb_totals[$TAG] | "
    done
    # strip all new lines
    _log "Loading Knowledge Base: $KB_TOTAL_OUT"
    init_log
}

# ==============================================
# -- init_detect_install_type
# ==============================================
function init_detect_install_type () {
    # -- Where am I installed? system? user? git?
    if [[ $ZSHBOP_ROOT == "/usr/local/sbin/zshbop" ]]; then
        _log "Installed in system"
        export ZSHBOP_INSTALL_TYPE="system"
        export ZSHBOP_SOFTWARE_PATH="/usr/local/sbin"
    elif [[ $ZSHBOP_ROOT == "$HOME/zshbop" ]]; then
        _log "Installed in user"
        export ZSHBOP_INSTALL_TYPE="user"
        export ZSHBOP_SOFTWARE_PATH="$HOME/bin"
    elif [[ $ZSHBOP_ROOT == "$HOME/git/zshbop" ]]; then
        _log "Installed in git"
        export ZSHBOP_INSTALL_TYPE="git"
        export ZSHBOP_SOFTWARE_PATH="$HOME/bin"
    else
        _log "Installed in unknown location"
        export ZSHBOP_INSTALL_TYPE="unknown"
        export ZSHBOP_SOFTWARE_PATH="$HOME/bin"
    fi
    init_log
}

# ==============================================
# -- init_completion
# ==============================================
function init_completion () {
    _debug_all
    _log "Loading completion"
    # -- Load completion
    fpath+=($ZSHBOP_ROOT/completion $fpath)
    autoload -U compinit
    compinit
    init_log
}
# ==============================================
# -- init_software
# ==============================================
function init_software () {
    _debug_all    
    _log "Loading software from software/*.zsh"
    source ${ZSHBOP_ROOT}/software/_init.zsh
   	for SOFTWARE_FILE in "${ZSHBOP_ROOT}/software/"*.zsh; do
        # If starts with an _ skip
        if [[ $(basename "$SOFTWARE_FILE") == _* ]]; then
            _debug "Skipping $SOFTWARE_FILE"
        else
            _debug "Loading $SOFTWARE_FILE"
            source $SOFTWARE_FILE
        fi
	done
    init_log
}

# ==============================================
# -- init_last
# ==============================================
function init_last () {
    _debug_all
    _log "Running last commands"
    
    # Debugging: Print the PATH variable
    _debugf "Current PATH: $PATH"

    # -- Check if INIT_LAST_CORE array has any commands
    if [[ -n $INIT_LAST_CORE ]]; then
        _log "Running \$INIT_LAST_CORE functions"
        for CMD in $INIT_LAST_CORE; do
            _debugf "Running $CMD"
            $CMD
        done
    else
        _debugf "No \$INIT_LAST_CORE commands"
    fi
    
    # -- Check if INIT_LAST_CUSTOM array has any commands
    if [[ -n $INIT_LAST_CUSTOM ]]; then
        _log "Running \$INIT_LAST_CUSTOM functions"
        for CMD in $INIT_LAST_CUSTOM; do
            _debug "Running $CMD"
            $CMD
        done
    else
        _debug "No \$INIT_LAST_CUSTOM commands"
    fi

    init_log
}

###########################################################
###########################################################
# ---- Leave this at the bottom. Do not move above. ------
###########################################################
###########################################################

# ==============================================
# -- init_mise - activate mise runtime manager if present
# ==============================================
function init_mise () {
    _debug_all

    # Allow disabling via environment variable
    if [[ -n "$ZSHBOP_MISE_DISABLE" ]]; then
        _debug "mise disabled via $ZSHBOP_MISE_DISABLE"
        init_log
        return 0
    fi

    local mise_bin
    if command -v mise >/dev/null 2>&1; then
        mise_bin="$(command -v mise)"
    elif [[ -x "$HOME/.local/bin/mise" ]]; then
        mise_bin="$HOME/.local/bin/mise"
    else
        _debug "mise not found; skipping activation"
        init_log
        return 0
    fi

    _log "Activating mise from $mise_bin"
    local activate_out
    activate_out="$($mise_bin activate zsh 2>/dev/null)"
    if [[ $? -eq 0 && -n "$activate_out" ]]; then
        eval "$activate_out"
        _success "mise activated"
    else
        _warning "mise activation failed"
    fi
    init_log
}

# ==============================================
# -- init_nvm - activate NVM (Node Version Manager) if enabled
# ==============================================
function init_nvm () {
    _debug_all

    # NVM is disabled by default - must be explicitly enabled
    if [[ -z "$ZSHBOP_NVM_ENABLE" ]]; then
        _debug "NVM not enabled (set ZSHBOP_NVM_ENABLE=1 to enable)"
        init_log
        return 0
    fi

    export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"

    if [[ ! -d "$NVM_DIR" ]]; then
        _debug "NVM directory not found at $NVM_DIR; skipping"
        init_log
        return 0
    fi

    # Lazy loading is the default when enabled (better performance)
    if [[ -z "$ZSHBOP_NVM_LAZY" || "$ZSHBOP_NVM_LAZY" == "1" ]]; then
        _log "Setting up NVM lazy loading from $NVM_DIR"
        _nvm_lazy_load
        _success "NVM lazy loading configured (loads on first use of nvm/node/npm/npx)"
    else
        _log "Loading NVM immediately from $NVM_DIR"
        _nvm_load_now
    fi
    init_log
}

# Helper: Load NVM immediately
function _nvm_load_now () {
    if [[ -s "$NVM_DIR/nvm.sh" ]]; then
        source "$NVM_DIR/nvm.sh"
        _debug "NVM loaded"
    else
        _warning "nvm.sh not found in $NVM_DIR"
        return 1
    fi

    # Load NVM bash completion (works in zsh too)
    if [[ -s "$NVM_DIR/bash_completion" ]]; then
        source "$NVM_DIR/bash_completion"
        _debug "NVM bash_completion loaded"
    fi
}

# Helper: Setup lazy loading for NVM
function _nvm_lazy_load () {
    # Create wrapper functions that load NVM on first use
    function nvm () {
        unfunction nvm node npm npx 2>/dev/null
        _nvm_load_now
        nvm "$@"
    }

    function node () {
        unfunction nvm node npm npx 2>/dev/null
        _nvm_load_now
        node "$@"
    }

    function npm () {
        unfunction nvm node npm npx 2>/dev/null
        _nvm_load_now
        npm "$@"
    }

    function npx () {
        unfunction nvm node npm npx 2>/dev/null
        _nvm_load_now
        npx "$@"
    }
}

# ==============================================
# -- init_basher - activate Basher package manager if present
# ==============================================
function init_basher () {
    _debug_all

    # Allow disabling via environment variable
    if [[ -n "$ZSHBOP_BASHER_DISABLE" ]]; then
        _debug "Basher disabled via ZSHBOP_BASHER_DISABLE"
        init_log
        return 0
    fi

    # Check for basher in standard location or XDG location
    local basher_root
    if [[ -d "$HOME/.basher" ]]; then
        basher_root="$HOME/.basher"
    elif [[ -d "${XDG_DATA_HOME:-$HOME/.local/share}/basher" ]]; then
        basher_root="${XDG_DATA_HOME:-$HOME/.local/share}/basher"
    else
        _debug "Basher not found; skipping"
        init_log
        return 0
    fi

    export BASHER_ROOT="$basher_root"

    # Add basher bin to PATH if not already there
    if [[ ":$PATH:" != *":$basher_root/bin:"* ]]; then
        export PATH="$basher_root/bin:$PATH"
    fi

    # Initialize basher
    if [[ -x "$basher_root/bin/basher" ]]; then
        _log "Activating Basher from $basher_root"
        eval "$("$basher_root/bin/basher" init - zsh)"
        _success "Basher activated"
    else
        _warning "Basher directory found but basher binary not executable"
    fi
    init_log
}

# ==============================================
# -- init_motd - initial scripts to run on login
# ==============================================
init_motd () {
	# -- Start motd
    _debug_all    
    system

    # -- Check System
    _loading "Checking System"    
	init_check_services
    init_check_software
    init_check_oom
    software-raid-check
    screen-sessions
    init_detect_install_type
    init_completion
    echo ""

    # -- Load motd
    source "${ZSHBOP_ROOT}/motd/motd.zsh"

	# -- Environment check
	_loading3 "Run 'zshbop check' for system checks or 'zshbop report' for a system report"

    # -- last echo to keep motd clean
    echo ""
    init_log
}



# ==============================================
# -- init_zshbop -- initialize zshbop
# ==============================================
function init_zshbop () {
    # Load user overrides early (once) so flags (e.g., ZSHBOP_DISABLE_VSCODE_SHELL) are available
    if [[ -z "$ZSHBOP_CONF_LOADED" && -f $HOME/.zshbop.conf ]]; then
        source $HOME/.zshbop.conf
        export ZSHBOP_CONF_LOADED=1
    fi

    # VS Code terminals often inherit ZSHBOP_INITIALIZED=1 from the parent; force a reload there
    if [[ "$TERM_PROGRAM" == "vscode" || -n "$VSCODE_IPC_HOOK_CLI" ]]; then
        export ZSHBOP_RELOAD="1"
    fi

    # Prevent double initialization (can happen with VS Code shell integration)
    # Allow re-init if ZSHBOP_RELOAD is set
    if [[ -n "$ZSHBOP_INITIALIZED" && "$ZSHBOP_RELOAD" != "1" ]]; then
        _debug "init_zshbop: Already initialized, skipping (set ZSHBOP_RELOAD=1 to force)"
        return 0
    fi
    
    # Capture reload state then immediately reset to prevent double init
    # if something re-sources .zshrc during initialization
    local IS_RELOAD="$ZSHBOP_RELOAD"
    export ZSHBOP_RELOAD="0"
    
    # Start overall boot timer
    ZSHBOP_BOOT_START=$EPOCHREALTIME
    
    _log "${funcstack[1]}:start"
    echo "[BOOT_TIME] Starting zshbop initialization" >> "$ZB_LOG"
    echo "[BOOT_TIME] Boot times are recorded with microsecond precision (format: X.XXXXXXs)" >> "$ZB_LOG"

    # --------------------------------------------------
	# -- Start init
    # --------------------------------------------------
	_debug_all
    echo "$bg[yellow]$fg[black] * Initializing zshbop${RSC} - $(zshbop_version) - $ZSHBOP_ROOT"
	_debug "\$ZSHBOP_ROOT = $ZSHBOP_ROOT"

    # --------------------------------------------------
    # -- Init zshbop
    # --------------------------------------------------    
    _start_boot_timer "init_core"; init_core # -- Init core functionality    
    if [[ $IS_RELOAD == "1" ]]; then
        _loading3 "Loading includes...." 
        _start_boot_timer "init_include"; init_include        # -- Include files
    fi
    _start_boot_timer "init_path"; init_path            # -- Set paths
    _start_boot_timer "init_mise"; init_mise            # -- Activate mise runtime (if installed)
    _start_boot_timer "init_nvm"; init_nvm              # -- Activate NVM (if enabled)
    _start_boot_timer "init_basher"; init_basher        # -- Activate Basher (if installed)
    _start_boot_timer "init_dirs"; init_dirs            # -- Set directories 
    _start_boot_timer "init_detectos"; init_detectos        # -- Detect operating system
    _start_boot_timer "init_zbr_cmds"; init_zbr_cmds        # -- Include commands
    _start_boot_timer "init_software"; init_software        # -- Include software
    _start_boot_timer "init_help"; init_help            # -- Load help
    # --------------------------------------------------
    # -- Include Commands First as a dependency for all below commands.
    # --------------------------------------------------    
    _start_boot_timer "init_checks"; init_checks          # -- Init checks
    _start_boot_timer "zsh-check-version"; zsh-check-version    # -- Check zsh    
    _start_boot_timer "init_home_bin"; init_home_bin        # -- Check if home bin exists	
    _start_boot_timer "init_pkg_manager"; init_pkg_manager     # -- Init package manager     
    _start_boot_timer "init-app-config"; init-app-config      # -- Common application configuration
    _start_boot_timer "zshbop_custom-load"; zshbop_custom-load   # -- Init custom zshbop  
  	if [[ $IS_RELOAD == "0" ]]; then
        _start_boot_timer "init_omz_plugins"; init_omz_plugins     # -- Init OhMyZSH plugins
    fi
    _start_boot_timer "init_plugins"; init_plugins         # -- Init plugins (needed for p10k prompt)
    _start_boot_timer "init_os"; init_os              # -- Init os defaults # TODO Needs to be refactored    
    _start_boot_timer "init_p10k"; init_p10k            # -- Init powerlevel10k
    _start_boot_timer "init_app_config"; init_app_config      # -- Init config
    _start_boot_timer "init_zsh_sweep"; init_zsh_sweep       # -- Init zsh-sweep if installed

    # -- Print out what loaded
    _log "Loaded zshbop functions: $ZSHBOP_LOAD"
    echo ""
     
    # -- Load custom then commands dependant on custom    
    _start_boot_timer "init_sshkeys"; init_sshkeys         # -- Init ssh keys
    _start_boot_timer "init_kb"; init_kb              # -- Init Knowledge Base

    # -- Check if init_custom_startup is defined as a function and then execute it    
    _debug "Checking if init_custom_startup is defined as a function"
    if whence -f init_custom_startup > /dev/null; then
        _debug "init_custom_startup is defined"
        _start_boot_timer "init_custom_startup"; init_custom_startup
    else
        _debug "init_custom_startup is not defined"
    fi
    
    _debug "init_zshbop: \$funcstack = $funcstack"
    if [[ $IS_RELOAD == "1" ]]; then
        _loading2 "Not loading init_motd, init_sshkeys on Reload"
    else
        _start_boot_timer "init_motd"; init_motd           # -- Init motd
    fi

    # -- Run last commands
    _start_boot_timer "init_last"; init_last

    # -- End init
    _log "${funcstack[1]}:end"
    
    # Calculate total boot time
    local total_time=$(printf "%.6f" $((EPOCHREALTIME - ZSHBOP_BOOT_START)))
    
    # Log boot time summary
    echo "" >> "$ZB_LOG"
    echo "[BOOT_TIME] ========================================" >> "$ZB_LOG"
    echo "[BOOT_TIME] zshbop Boot Time Summary" >> "$ZB_LOG"
    echo "[BOOT_TIME] ========================================" >> "$ZB_LOG"
    echo "[BOOT_TIME] Total boot time: ${total_time}s" >> "$ZB_LOG"
    echo "[BOOT_TIME] Component breakdown:" >> "$ZB_LOG"
    
    # Sort and display component times
    for component in ${(k)ZSHBOP_BOOT_TIMES}; do
        echo "[BOOT_TIME]   ${component}: ${ZSHBOP_BOOT_TIMES[$component]}s" >> "$ZB_LOG"
    done
    
    echo "[BOOT_TIME] ========================================" >> "$ZB_LOG"
    echo "" >> "$ZB_LOG"
    
    # Also log to debug if enabled
    _debug "========================================="
    _debug "zshbop Boot Time Summary"
    _debug "========================================="
    _debug "Total boot time: ${total_time}s"
    _debug "Component breakdown:"
    for component in ${(k)ZSHBOP_BOOT_TIMES}; do
        _debug "  ${component}: ${ZSHBOP_BOOT_TIMES[$component]}s"
    done
    _debug "========================================="
    
    # Mark as initialized to prevent double init
    export ZSHBOP_INITIALIZED=1
    
    init_log
}