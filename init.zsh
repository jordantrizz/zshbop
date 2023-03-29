#!/usr/bin/env zsh
# shellcheck disable=SC1090
# -------------------
# -- zshbop functions
# -------------------
# This file contains all the functions for initializing zshbop

_debug "Loading mypath=${0:a}"

# -- init_path - setup all the required paths.
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
	_loading "Finding local \$HOME/bin and \$HOME/git and adding to \$PATH"
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

# -- init_add_path
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
	        _success " Found $i folders and added them to \$PATH"
		fi
	else
		_debug "Can't find $DIR"
	fi
}

# -- init_detectos -- detect the OS running
init_detectos () {
        # -- Detect operating system
        _loading "Detecting Operating System"
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

        _loading_grey "Running in ${MACHINE_OS}"
}

# -- Initialize oh-my-zsh plugins
init_omz_plugins () {
	_loading "Loading OMZ plugins"
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
	WW_PLUGINS=$(echo $plugins | fmt)
	_loading_grey "OMZ - $WW_PLUGINS"
	
	# omz plugin config
	export GIT_AUTO_FETCH_INTERVAL=1200
	
	# aliases
	alias genpass="genpass-apple"
}

# -- powerlevel10k customizations
init_p10k () {
	_loading "Loading powerlevel10k configuration"
	# shellcheck source=./.p10k.zsh
	source $ZSH_ROOT/.p10k.zsh
	export POWERLEVEL9K_VCS_MAX_SYNC_LATENCY_SECONDS=0 # Don't wait for Git status even for a millisecond, so that prompt always updates
	export POWERLEVEL9K_DISK_USAGE_ONLY_WARNING="true"
	export POWERLEVEL9K_DISK_USAGE_WARNING_LEVEL="90"
}

# -- fzf
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

# -- Initialize plugins
init_plugins () {
	_loading "Loading Plugin Manager, \$ZSHBOP_PLUGIN_MANAGER = $ZSHBOP_PLUGIN_MANAGER"
	if [[ -z ${ZSHBOP_PLUGIN_MANAGER} ]]; then
		init_antigen	
	else
		eval ${ZSHBOP_PLUGIN_MANAGER}
	fi
}

# -- Initialize antidote plugin manager
init_antidote () {
	# -- plugin config
	export AUTO_LS_CHPWD="false"
	
	# -- load antidote
	_loading "Loading antidote"
	zstyle ':antidote:bundle' use-friendly-names 'yes' # remove slashes and user friendly names
	zstyle ':antidote:bundle' file "${ZBR}/.zsh_plugins.txt"
	export ANTIDOTE_DIR="${ZBR}/antidote"
	export ANTIDOTE_PLUGINS="${ZBR}/.zsh_plugins.txt"
	export ANTIDOTE_STATIC="${ZSHBOP_CACHE_DIR}/.zsh_plugins.zsh"
	_debug "ANTIDOTE_PLUGINS: $ANTIDOTE_PLUGINS ANTIDOTE_STATIC:$ANTIDOTE_STATIC"
	
  # shellcheck source=./antidote/antidote.zsh
  source $ANTIDOTE_DIR/antidote.zsh
	_loading2 "Generate antidote static file $ANTIDOTE_STATIC"
  antidote bundle < $ANTIDOTE_PLUGINS > $ANTIDOTE_STATIC
  _loading2 "Sourcing antidote static file $ANTIDOTE_STATIC"
  source $ANTIDOTE_STATIC
}

# -- Initialize antigen plugin manager
init_antigen () {
	_debug "Loading antigen"
	_loading "Loading antigen"
    if [[ -e $ZSHBOP_ROOT/antigen.zsh ]]; then
  _debug "- Loading antigen from $ZSHBOP_ROOT/antigen.zsh"
  # shellcheck source=./antigen.zsh
  source ${ZSHBOP_ROOT}/antigen.zsh >/dev/null 2>&1
  antigen init ${ZSHBOP_ROOT}/.antigenrc >/dev/null 2>&1
else
  _echo "	- Couldn't load antigen.."
fi
}

# -- Load os zsh scripts
init_os () {
	_debug_function
	# -- Loading os defaults
	_loading "Loading OS configuration"

	# -- Include common OS configuration
	_loading2 "Loading $ZSHBOP_ROOT/cmds/os-common.zsh"
	source $ZSHBOP_ROOT/cmds/os-common.zsh

	# Include OS Specific configuration
	
	# -- Mac
	if [[ $MACHINE_OS == "mac" ]] then
        	_loading2 "Loading cmds/os-mac.zsh"
	        source $ZSHBOP_ROOT/cmds/os-mac.zsh
	# -- Linux
	elif [[ $MACHINE_OS = "linux" ]] then
		_loading2 "Loading cmds/os-linux.zsh"
    	source $ZSHBOP_ROOT/cmds/os-linux.zsh
	# -- WSL Linux
	elif [[ $MACHINE_OS = "wsl" ]]; then				
	    _loading2 "Loading cmds/os-linux.zsh"
        source $ZSHBOP_ROOT/cmds/os-linux.zsh
       	_loading2 "Loading cmds/os-wsl.zsh"
	    source $ZSHBOP_ROOT/cmds/os-wsl.zsh
	fi
}

# -- Load default SSH keys into keychain
init_sshkeys () {
		_debug_function
		_loading "Loading SSH keys into keychain"
		if (( $+commands[keychain] )); then
		        # Load default SSH key
		        _loading2 "Load default SSH key"
		        _debug " - Check for default SSH key $HOME/.ssh/id_rsa and load keychain"
        		if [[ -a $HOME/.ssh/id_rsa || -L $HOME/.ssh/id_rsa ]]; then
		                _debug  " - FOUND: $HOME/.ssh/id_rsa"
		                eval `keychain -q --eval --agents ssh $HOME/.ssh/id_rsa`
		        else
		                _debug " - NOTFOUND: $HOME/.ssh/id_rsa"
        		fi

		        # Check and load custom SSH key
		        _loading2 "Loading custom SSH keys."
        		_debug " - Check for custom SSH key via $CUSTOM_SSH_KEY and load keychain"
        						
		        if [[ ! -z "${CUSTOM_SSH_KEYS[@]}" ]]; then
			        _debug " - FOUND: $CUSTOM_SSH_KEYS"
			        for key in ${CUSTOM_SSH_KEYS[@]}; do
						_loading3 "Loading -- $key"
                		eval `keychain -q --eval --agents ssh $key`
                	done
		        else
        		        _debug " - NOTFOUND: $CUSTOM_SSH_KEYS not set."
		        fi

			# Load any id_rsa* keys @@ISSUE
			_loading2 "Load any id_rsa* keys"
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

# -- init_pkg_manager
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

# -- init-app-config - set some application configuration
init-app-config () {
	_loading "Setting application configuration"
	# git
	git config --global init.defaultBranch main
}

# -- init_zshbop -- initialize zshbop
init_zshbop () {
	# -- Start init
	_debug_function
	_loading "Starting init"
	_debug "\$ZSHBOP_ROOT = $ZSHBOP_ROOT"

	# -- Check zsh version - https://scriptingosx.com/2019/11/comparing-version-strings-in-zsh/
	_loading "Running ZSH $ZSH_VERSION"
	autoload is-at-least
	if ! is-at-least 5.7 $ZSH_VERSION; then
		_warning "Running older ZSH Version, please upgrade https://github.com/lmtca/zsh-installs"
	else
    	_success "Running close to latest ZSH"
	fi

	# -- Set paths
	init_path
        
	# -- Detect operating system
	init_detectos

	# -- Init package manager
	init_pkg_manager
	
	# -- Include commands
	for CMD_FILE in "${ZSHBOP_ROOT}/cmds/"cmds-*; do
	  source $CMD_FILE
	done
        
	# -- Common application configuration
  	init-app-config

	# -- Init OhMyZSH plugins
  	init_omz_plugins
  	init_p10k

  	# -- Init custom zshbop
  	zshbop_load_custom
        
  	# -- Init antigen
	if [[ $funcstack[3] != "zshbop_reload" ]]; then
	  init_plugins
	else
	  _loading_grey "Not loading Plugin Manager on Reload"
	fi

  	# -- Init os defaults @@ISSUE
  	init_os

	# -- Skip when running rld
	_debug "\$funcstack = $funcstack"
	if [[ $funcstack[3] != "zshbop_reload" ]]; then
		init_sshkeys
		init_motd
		# -- Print zshbop version information
	  	zshbop_version
    echo ""
	else
	  _loading_grey "Skipped some scripts due to running rld"
	fi

	# Remove Duplicates in $PATH
	_debug "Removing duplicates in \$PATH"
	typeset -U PATH
}

# -- init_checklist
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

# -- init_check_services
init_check_services () {
    # -- Check system software versions
    _banner_yellow "-- Checking Service Versions"

	# - mysql	    
	if (( $+commands[mysqld] )); then
		_success "MySQL: $(mysqld --version)"
	else
		_error "MySQL Server not installed"
	fi
	
	# - nginx
	if (( $+commands[nginx] )); then
		_success "Nginx: $(nginx -v 2>&1 >/dev/null)"
	else
		_error "Nginx not installed"
	fi
	
	# - litespeed
	if (( $+commands[litespeed] )); then
		_success "Litespeed: $(litespeed -v)"
	else
		_error "Litespeed not installed"
	fi        	
	
	# - Redis
	if (( $+commands[redis-server] )); then
        _success "Redis: $(redis-server --version)"
    else
        _error "Redis not installed"
    fi

	# - Netdata    
    if [[ -f /opt/netdata/bin/netdata ]]; then
    	_success "Netdata: located at /opt/netdata/bin and config at /opt/netdata/etc/netdata"
    elif [[ -f /usr/sbin/netdata ]]; then
    	_success "Netdata: located at /usr/sbin/netdata and config at /etc/netdata"
    else
    	_error "Netdata not installed"
    fi
    	
}

# -- system_check - check usualy system stuff
system_check () {
	# -- start
	_debug_function
	_banner_yellow "System check"
	
    # -- network interfaces
    _loading "Network interfaces"
    interfaces

	# -- check swappiness
	_loading2 "Checking swappiness"
	if [[ -f /proc/sys/vm/swappiness ]]; then
		_notice "/proc/sys/vm/swappiness: $(cat /proc/sys/vm/swappiness)"
	else
		_error "Can't find swap"
	fi
	
	# -- check disk space
	_loading2 "Checking disk space on $MACHINE_OS"
	check_diskspace

	# -- check block devices
	_loading2 "Checking block devices"
	check_blockdevices
}	

# -- init_motd - initial scripts to run on login
init_motd () {
	# -- Start motd
    _debug_function

    # -- set .joe location
    _joe_ftyperc

    # -- check for old instances
    _loading "Old Instance Check"
    zshbop_migrate-check
    zshbop_previous-version-check

    # -- system details
    _loading "System details"
	sysfetch

    # -- System check
    system_check
    echo ""

    # -- Show screen sessions
    _loading "Screen Sessions"
    _cexists screen
    if [[ $? == "0" ]]; then
    	_success "$(screen -list)"
    else
    	_error "** Screen not installed"
    fi

    # -- Running system checklist
	init_check_software
	echo ""
	
	# -- Check service software versions        
	init_check_services
	echo ""
	
    # -- Load motd
    source "${ZBR}/motd.zsh"

	# -- env-install
	_loading "Run env-install to install default and extra tools"
	
    # -- last echo to keep motd clean
    echo ""
}