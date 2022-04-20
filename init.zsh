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
        
    	# Extra software
    	export PATH=$PATH:$ZSHBOP_ROOT/bin/cloudflare-cli # https://github.com/bAndie91/cloudflare-cli
		export PATH=$PATH:$ZSHBOP_ROOT/bin/clustergit # https://github.com/mnagel/clustergit
		export PATH=$PATH:$ZSHBOP_ROOT/bin/MySQLTuner-perl # https://github.com/major/MySQLTuner-perl
		export PATH=$PATH:$ZSHBOP_ROOT/bin/parsyncfp # https://github.com/hjmangalam/parsyncfp
		export PATH=$PATH:$ZSHBOP_ROOT/bin/httpstat # https://github.com/reorx/httpstat
	
	# Repos - Needs to be updated to find repos installed and add them to $PATH @@ISSUE
	if [ "$(find "$ZSHBOP_ROOT/repos" -mindepth 1 -maxdepth 1 -not -name '.*')" ]; then
		_debug "Found repos, adding to \$PATH"
		for name in $ZSHBOP_ROOT/repos/*; do
			_debug "$funcstack[1] - found repo $name, adding to \$PATH"
			export PATH=$PATH:$name
		done
	fi
	
	export PATH=$PATH:$ZSHBOP_ROOT/repos/gp-tools
	
	# Golang Path?
	export PATH=$PATH:$HOME/go/bin
}

# -- Initialize oh-my-zsh plugins
init_omz_plugins () {
	_echo "-- Loading OMZ plugins"
	plugins=( git z )
	_echo " - $plugins"
}

# -- Initialize Antigen
init_antigen () {
	_echo "-- Loading Antigen"
        if [[ -a $ZSHBOP_ROOT/antigen.zsh ]]; then
                _debug "- Loading antigen from $ZSHBOP_ROOT/antigen.zsh";
		source $ZSHBOP_ROOT/antigen.zsh > /dev/null 2>&1
		antigen init $ZSHBOP_ROOT/.antigenrc > /dev/null 2>&1
        else
                _echo "	- Couldn't load antigen..";
        fi
}

# -- Load default zsh scripts
init_defaults () {
	_debug_function
	# Include OS Specific configuration
	if [[ $MACHINE_OS == "Mac" ]] then
        	echo "- Loading cmds/os-mac.zsh"
	        source $ZSHBOP_ROOT/cmds/os-mac.zsh
	elif [[ $MACHINE_OS = "Linux" ]] then
                        source $ZSHBOP_ROOT/cmds/os-linux.zsh
                        echo "- Loading cmds/os-linux.zsh"
	elif [[ $MACHINE_OS = "WSL" ]]; then
                	echo "- Loading cmds/os-wsl.zsh"
	                source $ZSHBOP_ROOT/cmds/os-wsl.zsh
	fi

	# --- Include custom configuration
	_debug "Detecting custom .zshbop configuration"
	if [ -f $HOME/.zshbop.zshrc ]; then
        	echo " -- Loading custom configuration $HOME/.zshbop.zshrc"
	        source $HOME/.zshbop.zshrc
	else
		echo " -- No custom configuration found"
	fi
}

# -- Load default SSH keys into keychain
init_sshkeys () {
		_debug_function
		_echo "-- Loading SSH keys into keychain"
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
			_echo " - Command keychain doesn't exist, please install for SSH keys to work"
		fi
}

# -- init_pkg_manager
init_pkg_manager () {
	_debug_function
	_debug "Running on $MACHINE_OS"
	
	if [[ $MACHINE_OS == "Linux" ]] || [[ $MACHINE_OS == "WSL" ]]; then
		_debug "Checking for Linux package manager"
			if [[ $(_cexists apt-get ) ]]; then
				_debug "Found apt-get setting \$PKG_MANAGER to apt-get"
				PKG_MANAGER="sudo apt-get"
			else
				_debug "Didn't find apt-get"
			fi
	elif [[ $MACHINE_OS == "Mac" ]]; then
		_debug "Checking for Mac package manager"
			if [[ $(_cexists brew) ]]; then
				_debug "Found brew setting \$PKG_MANAGER to apt-get"
				PKG_MANAGER="brew"
			fi		
	fi
}

# -- init_motd - initial scripts to run on login
init_motd () {
		# -- Start motd
		_debug_function
		
		# -- set .joe location
		_joe_ftyperc
        
		# -- run neofetch
		neofetch
		
		# -- check for old instances
        zshbop_migrate-check
        zshbop_previous-version-check
        
		# -- Show screen sessions
		echo "-- Screen Sessions --"
		if _cexists screen; then
			screen -list
		else
			echo "** Screen not installed"
		fi
        
		# -- General message
		echo "---- Run checkenv to make sure you have all the right tools! ----"
        echo ""
}

# -- Init
init_zshbop () {
		# -- Start init
		_debug_function
		_echo "-- Starting init"
        _debug "\$ZSHBOP_ROOT = $ZSHBOP_ROOT"
        
        # -- Detect operating system
		_echo "-- Detecting Operating System"
        export UNAME=$(uname -s)
        case "${UNAME}" in
            Linux*)     MACHINE_OS=Linux;;
            Darwin*)    MACHINE_OS=Mac;;
            CYGWIN*)    MACHINE_OS=Cygwin;;
            MINGW*)     MACHINE_OS=MinGw;;
            *)          MACHINE_OS="UNKNOWN:${unameOut}"
        esac

		# -- Check for WSL and set as MACHINE_OS
        if [[ $(uname -r) =~ "Microsoft" || $(uname -r) =~ "microsoft" ]]; then
        	MACHINE_OS="WSL"
        fi
        echo "	-- Running in ${MACHINE_OS}"

		# -- Set paths
    	init_path

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
        init_defaults

		# -- Skip when running rld
		_debug "\$funcstack = $funcstack"
		if [[ $funcstack[3] != "zshbop_reload" ]]; then
			init_sshkeys
			init_motd
		else
			echo " -- Skipped some scripts due to running rld"
		fi

		# -- Print zshbop version information
		zshbop_version
		echo ""
}

