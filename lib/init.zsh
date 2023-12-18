#!/usr/bin/env zsh
# *********************************************************
# *********************************************************
# -- init.zsh - zshbop functions 
# *********************************************************
# *********************************************************

# =========================================================
# -- debug_load
# =========================================================
_debug_load
function init_log () {
    # -- Logging function that called init_log
    ZSHBOP_LOAD+=(${funcstack[2]})
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
    source ${ZSHBOP_ROOT}/lib/functions-core.zsh # -- core functions
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
	export PATH=$PATH:$HOME/bin:/usr/local/bin:$ZSHBOP_ROOT:$ZSHBOP_ROOT/bin
	export PATH=$PATH:$HOME/.local/bin
	export PATH=$PATH:$HOME/.cargo/bin
        
	# Extra software
	export PATH=$PATH:$ZSHBOP_ROOT/bin/cloudflare-cli # https://github.com/bAndie91/cloudflare-cli
	export PATH=$PATH:$ZSHBOP_ROOT/bin/clustergit # https://github.com/mnagel/clustergit
	export PATH=$PATH:$ZSHBOP_ROOT/bin/MySQLTuner-perl # https://github.com/major/MySQLTuner-perl
	export PATH=$PATH:$ZSHBOP_ROOT/bin/parsyncfp # https://github.com/hjmangalam/parsyncfp
	export PATH=$PATH:$ZSHBOP_ROOT/bin/httpstat # https://github.com/reorx/httpstat
	export PATH=$PATH:$HOME/bin/aws-cli # aws-cli https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html
	export PATH=$PATH:$ZSHBOP_ROOT/bin/exa # exa a replacement for ls
	export PATH=$PATH:/usr/local/lsws/bin/ # General path for Litespeed/Openlitespeed
	export PATH=$PATH:$ZSHBOP_ROOT/bin/btop/bin # btop
    export PATH=$PATH:/root/.acme.sh/ # acme.sh
    export PATH=$PATH:/opt/netdata/bin # netdata alternative path
	
	# Repos - Needs to be updated to find repos installed and add them to $PATH @@ISSUE
	_log "Finding local \$HOME/bin and \$HOME/git and adding to \$PATH"
	#init_add_path $ZSHBOP_ROOT/repos
	init_add_path $HOME/bin
	init_add_path $HOME/git
	init_add_path $ZSHBOP_ROOT/repos
	
	# Golang Path?
	export PATH=$PATH:$HOME/go/bin
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
# -- init_add_path
# ==============================================
init_add_path () {
	DIR="$@"
	if [[ -d $DIR ]]; then
		if [ "$(find "$DIR" -mindepth 1 -maxdepth 1 -not -name '.*')" ]; then
	    _debug "Adding $DIR to \$PATH"
	        i=0
	        for NAME in $DIR/*; do
	            _debug "$funcstack[1] - found $NAME, adding to \$PATH"
	                export PATH=$PATH:$NAME
	            i=$((i+1))
	        done
	        _log " Found $i folders and added them to \$PATH"
		fi
	else
		_debug "Can't find $DIR"
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
	_loading3 "Loading Plugin Manager, \$ZSHBOP_PLUGIN_MANAGER = $ZSHBOP_PLUGIN_MANAGER"
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
	
	# -- load antidote
	_log "Loading antidote"
	zstyle ':antidote:bundle' use-friendly-names 'yes' # remove slashes and user friendly names
	zstyle ':antidote:bundle' file "${ZBR}/.zsh_plugins.txt"
	export ANTIDOTE_DIR="${ZBR}/antidote"
	export ANTIDOTE_PLUGINS="${ZBR}/.zsh_plugins.txt"
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
	# -- Include common OS configuration
	_log "Loading $ZSHBOP_ROOT/cmds/os-common.zsh"
	source $ZSHBOP_ROOT/cmds/os-common.zsh

	# Include OS Specific configuration	
	# -- Mac
	if [[ $MACHINE_OS == "mac" ]] then
        _loading3 "Loaded OS Configuration cmds/os-mac.zsh"
        source $ZSHBOP_ROOT/cmds/os-mac.zsh   
    # -- WSL Linux
    elif [[ $MACHINE_OS2 = "wsl" ]]; then				
        _loading3 "Loading cmds/os-linux.zsh and cmds/os-wsl.zsh"
        source $ZSHBOP_ROOT/cmds/os-linux.zsh       	
        source $ZSHBOP_ROOT/cmds/os-wsl.zsh
        init_wsl
	# -- Linux
    elif [[ $MACHINE_OS = "linux" ]] then
		_loading3 "Loading cmds/os-linux.zsh"
        source $ZSHBOP_ROOT/cmds/os-linux.zsh
    elif [[ $MACHINE_OS = "synology" ]] then
		_loading3 "Loading cmds/os-linux.zsh"
        source $ZSHBOP_ROOT/cmds/os-linux.zsh
	else
        _loading3 "No OS specific configuration found"
    fi
    init_log
}

# ==============================================
# -- Load default SSH keys into keychain
# ==============================================
function init_sshkeys () {
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
        _warning "Command keychain doesn't exist, please install for SSH keys to work"
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

# ==============================================
# -- init_check_services
# ==============================================
function init_check_services () {
    # -- Check system software versions

    # -- cloudflared
    if (( $+commands[cloudflared] )) && _alert "cloudflared: $(cloudflared -v)" || _log "cloudflared Server not installed"

    # -- proxmox 
    if (( $+commands[pveversion] )) && _success "Proxmox: $(pveversion 2>/dev/null)" || _log "Proxmox Server not installed"
 
	# - mysql	    
	if (( $+commands[mysqld] )) && _success "MySQL: $(mysqld --version)" || { _log "MySQL Server not installed";_warning "MySQL not installed, but could be using remote database" }

    # -- mongodb
    if (( $+commands[mongod] )) && _success "MongoDB: $(mongod --version | head 1)" || _log "MongoDB Server not installed"
	
	# - nginx
	if (( $+commands[nginx] )) && _success "Nginx: $(nginx -v 2>&1 >/dev/null)" || _log "Nginx not installed"	
	
	# - litespeed
	if (( $+commands[litespeed] )) && _success "Litespeed: $(litespeed -v)" || _log "Litespeed not installed"
		
	# - Redis
	if (( $+commands[redis-server] )) && _success "Redis: $(redis-server --version)" || _log "Redis not installed"

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
    _loading "Loading completion"
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
    _loading "Loading software"
    _log "Loading zshbop cmds...."
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

###########################################################
###########################################################
# ---- Leave this at the bottom. Do not move above. ------
###########################################################
###########################################################

# ==============================================
# -- init_motd - initial scripts to run on login
# ==============================================
init_motd () {
	# -- Start motd
    _debug_all
    _loading "System Information"

    # -- OS specific motd
    _loading3 $(os-short)   

    # -- system details
    sysfetch-motd

    # -- sysinfo
    _loading3 $(cpu 0 1)    
    _loading3 $(mem)
    zshbop_check-system
    echo ""
    
    # -- Check System
    _loading "Checking System"    
	init_check_services
    init_check_software      
    software-raid-check
    screen-sessions
    init_detect_install_type
    init_completion
    echo ""

    # -- Load motd
    source "${ZSHBOP_ROOT}/motd/motd.zsh"

	# -- Environment check
	_loading2  "Run zshbop check or system-specs."
    #env-install to install default and extra tools. Run system-specs for more system details."
    # TODO - add system-specs
    echo ""
	
    # -- run report after exec zsh
    if [[ $RUN_REPORT == "1" ]]; then
        zshbop_report
        export RUN_REPORT=0
    else
        zshbop_report faults
    fi
    
    # -- last echo to keep motd clean
    echo ""
    init_log
}

# ==============================================
# -- init_zshbop -- initialize zshbop
# ==============================================
function init_zshbop () {
    _log "${funcstack[1]}:start"

    # --------------------------------------------------
	# -- Start init
    # --------------------------------------------------
	_debug_all
    echo "$bg[yellow]$fg[black] * Initializing zshbop${RSC}"
    echo "$(zshbop_version) - $ZSHBOP_ROOT"
	_debug "\$ZSHBOP_ROOT = $ZSHBOP_ROOT"

    # --------------------------------------------------
    # -- Init zshbop
    # --------------------------------------------------    
    init_core # -- Init core functionality    
    if [[ $ZSHBOP_RELOAD == "1" ]]; then
        _loading3 "Loading includes...." 
        init_include        # -- Include files
    fi
    init_path            # -- Set paths
    init_dirs            # -- Set directories 
    init_detectos        # -- Detect operating system
    init_zbr_cmds        # -- Include commands
    init_software        # -- Include software
    init_help            # -- Load help
    # --------------------------------------------------
    # -- Include Commands First as a dependency for all below commands.
    # --------------------------------------------------    
    init_checks          # -- Init checks
    zsh-check-version    # -- Check zsh    
    init_home_bin        # -- Check if home bin exists	
	init_pkg_manager     # -- Init package manager     
    init-app-config      # -- Common application configuration
    zshbop_custom-load   # -- Init custom zshbop  
  	if [[ $ZSHBOP_RELOAD == "0" ]]; then
        init_omz_plugins     # -- Init OhMyZSH plugins
  	    init_plugins         # -- Init plugins
    fi
    init_os              # -- Init os defaults # TODO Needs to be refactored    
    init_p10k            # -- Init powerlevel10k
  	init_app_config      # -- Init config
    init_zsh_sweep       # -- Init zsh-sweep if installed

    # -- Print out what loaded
    _loading3 "Loaded: $ZSHBOP_LOAD"
    echo ""
     
    # -- Load custom then commands dependant on custom    
    init_sshkeys         # -- Init ssh keys
    init_kb              # -- Init Knowledge Base

    # -- Check if init_custom_startup is defined as a function and then execute it    
    _debug "Checking if init_custom_startup is defined as a function"
    if whence -f init_custom_startup > /dev/null; then
        _debug "init_custom_startup is defined"
        init_custom_startup
    else
        _debug "init_custom_startup is not defined"
    fi
    
    _debug "init_zshbop: \$funcstack = $funcstack"
    if [[ $ZSHBOP_RELOAD == "1" ]]; then
        _loading2 "Not loading init_motd, init_sshkeys on Reload"
        ZSHBOP_RELOAD="0"
    else
        init_motd           # -- Init motd
    fi

	# Remove Duplicates in $PATH
	_debug "Removing duplicates in \$PATH"
	typeset -U PATH
}