#!/usr/bin/env zsh
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
		mkdir $HOME/tmp
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

# -- Initialize oh-my-zsh plugins
init_omz_plugins () {
	_loading "Loading OMZ plugins"
	plugins=( git z )
	_loading_grey "OMZ - $plugins"
}

# -- Initialize Antigen
init_antigen () {
	_loading "Loading Antigen"
        if [[ -a $ZSHBOP_ROOT/antigen.zsh ]]; then
                _debug "- Loading antigen from $ZSHBOP_ROOT/antigen.zsh";
		source $ZSHBOP_ROOT/antigen.zsh > /dev/null 2>&1
		antigen init $ZSHBOP_ROOT/.antigenrc > /dev/null 2>&1
        else
                _echo "	- Couldn't load antigen..";
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
		        _debug " - Check for default SSH key $HOME/.ssh/id_rsa and load keychain"
        		if [[ -a $HOME/.ssh/id_rsa || -L $HOME/.ssh/id_rsa ]]; then
		                _debug  " - FOUND: $HOME/.ssh/id_rsa"
		                eval `keychain -q --eval --agents ssh $HOME/.ssh/id_rsa`
		        else
		                _debug " - NOTFOUND: $HOME/.ssh/id_rsa"
        		fi

		        # Check and load custom SSH key
        		_debug " - Check for custom SSH key via $CUSTOM_SSHKEY and load keychain"
		        if [ ! -z "${CUSTOM_SSHKEY+1}" ]; then
        		        _debug " - FOUND: $CUSTOM_SSHKEY"
                		eval `keychain -q --eval --agents ssh $CUSTOM_SSHKEY`
		        else
        		        _debug " - NOTFOUND: $CUSTOM_SSHKEY not set."
		        fi

			# Load any id_rsa* keys @@ISSUE
			if [[ $ENABLE_ALL_SSH_KEYS == 1 ]]; then
				eval `keychain -q --eval --agents ssh $HOME/.ssh/id_rsa*`
			fi
			# Load any client-* keys
			if [[ $ENABLE_ALL_SSH_KEYS == 1 ]]; then
                        	eval `keychain -q --eval --agents ssh $HOME/.ssh/clients*`
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
				PKG_MANAGER="sudo apt-get"
			else
				_debug "Didn't find apt-get"
			fi
	elif [[ $MACHINE_OS == "mac" ]]; then
		_debug "Checking for Mac package manager"
			_cexists brew
			if [[ $? == "0" ]]; then
				_debug "Found brew setting \$PKG_MANAGER to apt-get"
				PKG_MANAGER="brew"
			fi		
	fi	
}

init_detectos () {
        # -- Detect operating system
        _loading "Detecting Operating System"
        export UNAME=$(uname -s)
        case "${UNAME}" in
            Linux*)     MACHINE_OS=linux;;
            Darwin*)    MACHINE_OS=mac;;
            CYGWIN*)    MACHINE_OS=cygwin;;
            MINGW*)     MACHINE_OS=mingw;;
            *)          MACHINE_OS="UNKNOWN:${unameOut}"
        esac

        # -- Check for WSL and set as MACHINE_OS
        if [[ $(uname -r) =~ "Microsoft" || $(uname -r) =~ "microsoft" ]]; then
            MACHINE_OS="wsl"
        fi
        _loading_grey "Running in ${MACHINE_OS}"
}

# -- Init
init_zshbop () {
		# -- Start init
		_debug_function
		_loading "Starting init"
        _debug "\$ZSHBOP_ROOT = $ZSHBOP_ROOT"

        # -- Set paths
        init_path
        
        # -- Detect operating system
		init_detectos

		# -- Init package manager
		init_pkg_manager
	
        # -- Include commands
        for file in "${ZSHBOP_ROOT}/cmds/"cmds-*; do
			source $file
        done

		# -- Init OhMyZSH plugins
        init_omz_plugins
        
        # -- Init antigen
        init_antigen
        
        # -- Init defaults @@ISSUE
        init_os
        
        # -- Init custom
        zshbop_load_custom

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

    # --- system details
    _loading "System details"
	sysfetch

    # -- Show screen sessions
    _loading "Screen Sessions"
    _cexists screen
    if [[ $? == "0" ]]; then
    	_success $(screen -list)
    else
    	_error "** Screen not installed"
    fi

        # -- Checking system
        _banner_yellow "-- Checking System --"
        _success "Run checkenv to make sure you have all the right tools!"
        _cexists atop
        if [[ $? == "1" ]]; then
            _error "atop not installed, if this is a server install it"
        else
            _success "atop installed"
            # @ISSUE check if atop is running
        fi
        check_broot

        # -- load custom zshbop config
        zshbop_load_custom

        # -- last echo to keep motd clean
        echo ""
}