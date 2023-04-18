#!/usr/bin/env zsh
# -----------------------------------------------------------------------------------
# -- zshbop functions -- This file contains all the functions for initializing zshbop
# -----------------------------------------------------------------------------------
_debug_load
_debug_load

# ==============================================
# -- init_path - setup all the required paths.
# ==============================================
init_path () {
	_debug_function

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

        _loading_grey "Detecting Operating System - Running in ${MACHINE_OS}"
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
init_p10k () {
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
init_fzf () {
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
init_plugins () {
	_loading2 "Loading Plugin Manager, \$ZSHBOP_PLUGIN_MANAGER = $ZSHBOP_PLUGIN_MANAGER"
	if [[ -z ${ZSHBOP_PLUGIN_MANAGER} ]]; then
		init_antigen	
	else
		eval ${ZSHBOP_PLUGIN_MANAGER}
	fi
}

# ==============================================
# -- Initialize antidote plugin manager
# ==============================================
init_antidote () {
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
init_antigen () {
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
init_os () {
	_debug_function
	# -- Loading os defaults
	_debug "Loading OS configuration"

	# -- Include common OS configuration
	_log "Loading $ZSHBOP_ROOT/cmds/os-common.zsh"
	source $ZSHBOP_ROOT/cmds/os-common.zsh

	# Include OS Specific configuration
	
	# -- Mac
	if [[ $MACHINE_OS == "mac" ]] then
        	_loading2 "Loaded OS Configuration cmds/os-mac.zsh"
	        source $ZSHBOP_ROOT/cmds/os-mac.zsh
	# -- Linux
	elif [[ $MACHINE_OS = "linux" ]] then
		_loading2 "Loading cmds/os-linux.zsh"
    	source $ZSHBOP_ROOT/cmds/os-linux.zsh
	# -- WSL Linux
	elif [[ $MACHINE_OS = "wsl" ]]; then				
	    _loading2 "Loading cmds/os-linux.zsh and cmds/os-wsl.zsh"
        source $ZSHBOP_ROOT/cmds/os-linux.zsh       	
	    source $ZSHBOP_ROOT/cmds/os-wsl.zsh
	fi
}

# ==============================================
# -- Load default SSH keys into keychain
# ==============================================
init_sshkeys () {
		_debug_function
		_log "Loading SSH keys into keychain"
		if (( $+commands[keychain] )); then
            # Load default SSH key
            _log "Load default SSH key"
            _debug " - Check for default SSH key $HOME/.ssh/id_rsa and load keychain"
            if [[ -a $HOME/.ssh/id_rsa || -L $HOME/.ssh/id_rsa ]]; then
                    _debug  " - FOUND: $HOME/.ssh/id_rsa"
                    eval `keychain -q --eval --agents ssh $HOME/.ssh/id_rsa`
            else
                    _debug " - NOTFOUND: $HOME/.ssh/id_rsa"
            fi

            # Check and load custom SSH key
            _log "Loading custom SSH keys."
            _debug " - Check for custom SSH key via $CUSTOM_SSH_KEY and load keychain"
                            
            if [[ ! -z "${CUSTOM_SSH_KEYS[@]}" ]]; then
                _debug " - FOUND: $CUSTOM_SSH_KEYS"
                for key in ${CUSTOM_SSH_KEYS[@]}; do
                    _log "Loading -- $key"
                    eval `keychain -q --eval --agents ssh $key`
                done
            else
                    _debug " - NOTFOUND: $CUSTOM_SSH_KEYS not set."
            fi

			# Load any id_rsa* keys @@ISSUE
            # TODO figure out why this is @@ISSUE
			_log "Load any id_rsa* keys"
			if [[ $ENABLE_ALL_SSH_KEYS == 1 ]]; then
				eval `keychain -q --eval --agents ssh $HOME/.ssh/id_rsa*`
			fi
			# Load any client-* keys
			if [[ $ENABLE_ALL_SSH_KEYS == 1 ]]; then
            	eval `keychain -q --eval --agents ssh $HOME/.ssh/client*`
            fi
		else
			_error "Command keychain doesn't exist, please install for SSH keys to work"
		fi
}

# ==============================================
# -- init_pkg_manager
# ==============================================
init_pkg_manager () {
	_debug_function
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
			_cexists brew
			if [[ $? == "0" ]]; then
				_debug "Found brew setting \$PKG_MANAGER to apt-get"
				export PKG_MANAGER="brew"
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
init_cmds () {
   	for CMD_FILE in "${ZSHBOP_ROOT}/cmds/"cmds-*; do
	  source $CMD_FILE
	done
}

# ==============================================
# -- init_zshbop -- initialize zshbop
# ==============================================
init_zshbop () {
	# -- Start init
	_debug_function
	_loading "Starting init"
    zshbop_version
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
    init_zsh_sweep       # -- Init zsh-sweep if installed
    init_systemcheck     # -- Init systemcheck to confirm system status.
        
  	# -- Init antigen
    [[ $funcstack[3] != "zshbop_reload" ]] && init_plugins || _loading_grey "Not loading Plugin Manager on Reload"

	# -- Skip when running rld
	_debug "\$funcstack = $funcstack"
	if [[ $funcstack[3] != "zshbop_reload" ]]; then
		init_sshkeys
		init_motd
    echo ""
	else
	    _loading_grey "Skipped some scripts due to running rld"
	    zshbop_version
	fi

	# Remove Duplicates in $PATH
	_debug "Removing duplicates in \$PATH"
	typeset -U PATH
}

# ==============================================
# -- init_checklist
# ==============================================
init_check_software () {
	# -- Check services and software
	_banner_yellow "-- Checking Software"
    _cexists atop
    if [[ $? == "1" ]]; then
        _error "atop not installed, if this is a server install it"
    else
        _success "atop installed"
        # @@ISSUE check if atop is running
    fi
    check_broot
}

# ==============================================
# -- init_check_services
# ==============================================
init_check_services () {
    # -- Check system software versions
    _banner_yellow "-- Checking Service Versions"

	# - mysql	    
	if (( $+commands[mysqld] )) && _success "MySQL: $(mysqld --version)" || _log "MySQL Server not installed"
	
	# - nginx
	if (( $+commands[nginx] )) && _success "Nginx: $(nginx -v 2>&1 >/dev/null)" || _log "Nginx not installed"	
	
	# - litespeed
	if (( $+commands[litespeed] )) && _success "Litespeed: $(litespeed -v)" || _log "Litespeed not installed"
		
	# - Redis
	if (( $+commands[redis-server] )) && _success "Redis: $(redis-server --version)" || _log "Redis not installed"

	# - Netdata    
    if [[ -f /opt/netdata/bin/netdata ]]; then
    	_success "Netdata: located at /opt/netdata/bin and config at /opt/netdata/etc/netdata"
    elif [[ -f /usr/sbin/netdata ]]; then
    	_success "Netdata: located at /usr/sbin/netdata and config at /etc/netdata"
    else
    	_log "Netdata not installed"
    fi
    	
}

# ==============================================
# -- system_check - check usualy system stuff
# ==============================================
init_systemcheck () {
	# -- start
	_debug_function
	_loading2 "System check on $MACHINE_OS"
		
	check_diskspace # -- check disk space
	check_blockdevices 	# -- check block devices
}

# ==============================================
# -- init_motd - initial scripts to run on login
# ==============================================
init_motd () {
	# -- Start motd
    _debug_function

    # -- set .joe location
    _joe_ftyperc

    # -- check for old instances
    _debug "Old Instance Check"
    zshbop_migrate-check
    zshbop_previous-version-check

    # -- system details
    _loading "System details"
	sysfetch | _pipe_separate 3

    # -- Show screen sessions
    _loading "Screen Sessions"
    _cexists screen
    [[ $? == "0" ]] && _success "$(screen -list)" || _error "Screen not installed"

    # -- Running system checklist
	init_check_software
	echo ""
	
	# -- Check service software versions        
	init_check_services
	echo ""
	
    # -- Load motd
    source "${ZSHBOP_ROOT}/motd/motd.zsh"

	# -- env-install
	_loading "Run env-install to install default and extra tools. Run system-specs for more system details."
	
    # -- last echo to keep motd clean
    echo ""
}

# -- check zsh version
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