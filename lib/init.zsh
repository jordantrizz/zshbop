#!/usr/bin/env zsh
# -----------------------------------------------------------------------------------
# -- zshbop functions -- This file contains all the functions for initializing zshbop
# -----------------------------------------------------------------------------------
_debug_load
source ${ZSHBOP_ROOT}/lib/colors.zsh # -- colors first!
source ${ZSHBOP_ROOT}/lib/functions-core.zsh # -- core functions
source ${ZSHBOP_ROOT}/lib/functions.zsh # -- zshbop functions
source ${ZSHBOP_ROOT}/lib/aliases.zsh # -- include aliases

# ==============================================
# -- init_path - setup all the required paths.
# ==============================================
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
	
	
	# Repos - Needs to be updated to find repos installed and add them to $PATH @@ISSUE
	_log "Finding local \$HOME/bin and \$HOME/git and adding to \$PATH"
	#init_add_path $ZSHBOP_ROOT/repos
	init_add_path $HOME/bin
	init_add_path $HOME/git
	init_add_path $ZSHBOP_ROOT/repos
	
	# Golang Path?
	export PATH=$PATH:$HOME/go/bin
	
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

    # -- Check for WSL and set as MACHINE_OS
    if [[ $(uname -r) =~ "Microsoft" || $(uname -r) =~ "microsoft" ]]; then
        MACHINE_OS="wsl"
    fi

    # -- Check for synology and set as MACHINE_OS
    if [[ $(uname -a) =~ "synology" ]]; then
        MACHINE_OS="synology"
    fi
    
    # -- Detect OS flavour
    if [[ -e /etc/redhat-release ]] && grep -q -i -e "Red Hat" -e "CentOS" /etc/redhat-release; then
        MACHINE_OS_FLAVOUR="redhat"        
    elif [[ -e /etc/os-release ]] && grep -q -i -e "debian" -e "ubuntu" /etc/os-release; then
        MACHINE_OS_FLAVOUR="debian"
    else
        MACHINE_OS_FLAVOUR="unknown"
    fi
}

# ==============================================
# -- Initialize oh-my-zsh plugins
# ==============================================
init_omz_plugins () {
	_debug "Loading OMZ plugins"
	# omz plugin config
    export GIT_AUTO_FETCH_INTERVAL=1200

	# load plugins
	plugins=(
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
}

# ==============================================
# -- fzf
# ==============================================
# TODO need to fix
function init_fzf () {
	if _cexists fzf; then
	    _debug "fzf is installed"
	    antigen bundle andrewferrier/fzf-z
	    antigen bundle wfxr/forgit
	    # shellcheck source=./custom/.fzf-key-bindings.zsh
	    source $ZSH_CUSTOM/.fzf-key-bindings.zsh
	else
	    _debug "fzf is not installed, consider it"
	fi
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
	_debug "ANTIDOTE_PLUGINS: $ANTIDOTE_PLUGINS ANTIDOTE_STATIC:$ANTIDOTE_STATIC"
	
    # shellcheck source=./antidote/antidote.zsh
    source $ANTIDOTE_DIR/antidote.zsh
	_log "Generate antidote static file $ANTIDOTE_STATIC"
    antidote bundle < $ANTIDOTE_PLUGINS > $ANTIDOTE_STATIC
    _log "Sourcing antidote static file $ANTIDOTE_STATIC"
    source $ANTIDOTE_STATIC
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
}

# ==============================================
# -- Load os zsh scripts
# ==============================================
function init_os () {
	_debug_all
	# -- Loading os defaults
	_debug "Loading OS configuration"

	# -- Include common OS configuration
	_log "Loading $ZSHBOP_ROOT/cmds/os-common.zsh"
	source $ZSHBOP_ROOT/cmds/os-common.zsh

	# Include OS Specific configuration
	
	# -- Mac
	if [[ $MACHINE_OS == "mac" ]] then
        	_loading3 "Loaded OS Configuration cmds/os-mac.zsh"
	        source $ZSHBOP_ROOT/cmds/os-mac.zsh
	# -- Linux
	elif [[ $MACHINE_OS = "linux" ]] then
		_loading3 "Loading cmds/os-linux.zsh"
    	source $ZSHBOP_ROOT/cmds/os-linux.zsh
	# -- WSL Linux
	elif [[ $MACHINE_OS = "wsl" ]]; then				
	    _loading3 "Loading cmds/os-linux.zsh and cmds/os-wsl.zsh"
        source $ZSHBOP_ROOT/cmds/os-linux.zsh       	
	    source $ZSHBOP_ROOT/cmds/os-wsl.zsh
	fi
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
                    _elog "-- Can't find $SSH_KEY, please check your CUSTOM_SSH_KEY array in .zshbop.conf"
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
        _error "Command keychain doesn't exist, please install for SSH keys to work"
    fi
}

# ==============================================
# -- init_pkg_manager
# ==============================================
function init_pkg_manager () {
	_debug_all
	_debug "Running on $MACHINE_OS"
	
	if [[ $MACHINE_OS == "linux" ]] || [[ $MACHINE_OS == "wsl" ]]; then
		_debug "Checking for Linux package manager"
        _cexists apt-get
        if [[ $? == "0" ]]; then
            _debug "Found apt-get setting \$PKG_MANAGER to apt-get"
            export PKG_MANAGER="sudo apt-get"
        else
            _debug "Didn't find apt-get"
        fi
	elif [[ $MACHINE_OS == "mac" ]]; then
		_debug "Checking for Mac package manager"
        # -- Check for brew
        _cexists brew
        if [[ $? == "0" ]]; then
            _debug "Found brew setting \$PKG_MANAGER to brew"
            export PKG_MANAGER="brew"
        fi

        # -- Check for macports
        _cexists port
        if [[ $? == "0" ]]; then
            _debug "Found port setting \$PKG_MANAGER to port"
            export PKG_MANAGER="port"
        fi
	fi	
}

# ==============================================
# -- init-app-config - set some application configuration
# ==============================================
init-app-config () {
    
	_log "Setting application configuration"
	# git
	git config --global init.defaultBranch main
}

# ==============================================
# -- init_cmds
# ==============================================
function init_cmds () {
   	for CMD_FILE in "${ZSHBOP_ROOT}/cmds/"cmds-*; do
	  source $CMD_FILE
	done
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
}

# ==============================================
# -- init_checklist
# ==============================================
init_check_software () {
	# -- Check services and software
	_loading "Checking Software"

    # -- check if atop is installed
    if _cexists atop; then 
        # -- check if atop is running using ps and pgrep
        pgrep atop >> /dev/null && _success "atop installed and running" || _warning "atop installed but not running, if this is a server install it"
    else
        _warning "atop not installed, if this is a server install it" 
    fi

    # -- check if broot is installed
    check_broot
}

# ==============================================
# -- init_check_services
# ==============================================
function init_check_services () {
    # -- Check system software versions
    _loading "Checking Service Versions"

    # -- cloudflared
    if (( $+commands[cloudflared] )) && _alert "cloudflared: $(cloudflared -v)" || _log "cloudflared Server not installed"

    # -- proxmox 
    if (( $+commands[pveversion] )) && _success "Proxmox: $(pveversion 2>/dev/null)" || _log "Proxmox Server not installed"
 
	# - mysql	    
	if (( $+commands[mysqld] )) && _success "MySQL: $(mysqld --version)" || { _log "MySQL Server not installed";_warning "MySQL not installed, but could be using remote database" }
	
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
    	_log "Netdata not installed"
    fi
}

# ==============================================
# -- check zsh version
# ==============================================

function init_checkzsh () {
	# -- Check zsh version - https://scriptingosx.com/2019/11/comparing-version-strings-in-zsh/
	_log "Running ZSH $ZSH_VERSION - Latest version is 5.9 as per https://zsh.sourceforge.io/News/"
	autoload is-at-least
	if ! is-at-least 5.7 $ZSH_VERSION; then
		_warning "Running older ZSH Version, please upgrade https://github.com/lmtca/zsh-installs"
	else
    	_log "Running close to latest ZSH"
	fi
}

# ==============================================
# -- check if in virtual environment
# ==============================================

function init_check_vm () {
    _debug "Checking if in virtual environment"

    [[ $MACHINE_OS == "mac" ]] && { _success "VM: Running on Mac...no need to check"; return 0 }

    # -- check if virt-what exists
    _cexists virt-what
    if [[ $? == "0" ]]; then
        _debug "virt-what installed"
        VM=$(virt-what)
        if [[ -n $VM ]]; then
            _warning "VM-virt-what: Running on $VM"
            _debug "virt-what returned $VM"
        else
            _notice "Not running in a VM"
            _debug "virt-what returned $VM"
        fi
    else
        _notice "Unable to determine if in virtual environment, please install virt-what"
    fi
    }

# ==============================================
# -- check if in virtual environment secondary method
# ==============================================

function init_check_vm_2 () {
    _debug "Checking if in virtual environment"
    if [[ -d /sys/devices/virtual ]] || [[ -f /proc/vz ]] || [[ -d /proc/xen ]]; then
        _alert "You are in a virtual machine."
    else
        _alert "You are not in a virtual machine."
    fi
}

###########################################################
# ---- Leave this at the bottom. Do not move above. ------
###########################################################

# ==============================================
# -- init_motd - initial scripts to run on login
# ==============================================
init_motd () {
	# -- Start motd
    _debug_all

    # -- OS specific motd
    _loading3 "Operating System - ${MACHINE_OS} - ${MACHINE_OS_FLAVOUR}"

    # -- check for old instances
    _debug "Old Instance Check"
    zshbop_migrate-check
    zshbop_previous-version-check
    echo ""

    # -- system details
    _loading "System details"
	sysfetch | _pipe_separate 2 | sed 's/^/  /'
    echo ""
    
    _loading "System check on $MACHINE_OS"
    zshbop_systemcheck
    init_check_vm
    echo ""

    # -- Show screen sessions
    _loading "Screen Sessions"
    _cexists screen && _success "$(screen -list)" || _error "Screen not installed"

    # -- Running system checklist
	init_check_software
	echo ""
	
	# -- Check service software versions        
	init_check_services
    echo ""

    # -- Load motd
    source "${ZSHBOP_ROOT}/motd/motd.zsh"

	# -- Environment check
	_loading2  "Run zshbop check or system-specs."
    #env-install to install default and extra tools. Run system-specs for more system details."
    # TODO - add system-specs
	
    # -- run report after exec zsh
    if [[ $RUN_REPORT == "1" ]]; then
        zshbop_report
        export RUN_REPORT=0
    fi
    
    # -- last echo to keep motd clean
    echo ""
}

# ==============================================
# -- init_zshbop -- initialize zshbop
# ==============================================
function init_zshbop () {
    _log "${funcstack[1]}:start"
	# -- Start init
	_debug_all
    echo "$bg[yellow]$fg[black] * Initilizing zshbop${RSC} - $(zshbop_version)"
	_debug "\$ZSHBOP_ROOT = $ZSHBOP_ROOT"

    # -- Init zshbop
    init_checkzsh        # -- Check zsh
    init_path            # -- Set paths
	init_detectos        # -- Detect operating system	
	init_pkg_manager     # -- Init package manager
    init_cmds            # -- Include commands
    init-app-config      # -- Common application configuration
  	init_omz_plugins     # -- Init OhMyZSH plugins
  	init_p10k            # -- Init powerlevel10k
  	zshbop_load_custom   # -- Init custom zshbop  	
    init_os              # -- Init os defaults # TODO Needs to be refactored
    init_app_config      # -- Init config
    init_zsh_sweep       # -- Init zsh-sweep if installed
    init_plugins         # -- Init plugins
    init_sshkeys         # -- Init ssh keys
    
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