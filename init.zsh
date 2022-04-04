# --------------
# -- zshbop Init
# --------------
# This is the initilization for zsbhop

# Use colors, but only if connected to a terminal
# and that terminal supports them.

# ------------------------
# -- Environment Variables
# ------------------------

# - Set umask
umask 022

# -- zsh and environment settings
if [[ $(_cexists nala ) ]]; then
	_debug "nala installed - running zsh completions"
	source /usr/share/bash-completion/completions/nala
fi


# -- environment variables
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

# -- zshbop debugging
if [ -f $ZSHBOP_ROOT/.debug ]; then
        export ZSH_DEBUG=1
elif [ ! -f $ZSHBOP_ROOT/.debug ]; then
        export ZSH_DEBUG=0
fi

# -- ohmyzsh specific environment variables
export bgnotify_threshold='6' # https://github.com/robbyrussell/oh-my-zsh/tree/master/plugins/bgnotify

# ------------
# -- Variables
# ------------

# -- colors
# $fg[blue]
# $fg[red]
# $fg[yellow]
# $fg[green]
# $reset_color
autoload colors
if [[ "$terminfo[colors]" -gt 8 ]]; then
    colors
fi

# -- Unsorted stuff.
default_tools=('mosh' 'traceroute' 'mtr' 'pwgen' 'tree' 'ncdu' 'fpart' 'whois' 'pwgen' 'python3-pip' 'joe' 'keychain' 'dnsutils' 'whois' 'gh' 'php-cli' 'telnet' 'lynx' 'jq' 'shellcheck' 'sudo' 'fzf')
extra_tools=('pip' 'npm' 'golang-go')
pip_install=('ngxtop' 'apt-select')

# -- fzf keybindings
# Need to enable if fzf is available
#[ -f $ZSH_CUSTOM/.fzf-key-bindings.zsh ] && source $ZSH_CUSTOM/.fzf-key-bindings.zsh;echo "Enabled FZF keybindgs"
####-- diff-so-fancy
git config --global core.pager "diff-so-fancy | less --tabs=4 -RFX"

# -- Take $EDITOR run it through alias and strip it down
EDITOR_RUN=${${$(alias $EDITOR)#joe=\'}%\'}

# ------------
# -- Functions
# ------------

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
	# Include OS Specific configuration
	if [[ $MACHINE_OS == "Mac" ]] then
        	echo "- Loading cmds/os-mac.zshrc"
	        source $ZSHBOP_ROOT/cmds/os-mac.zshrc
	elif [[ $MACHINE_OS = "Linux" ]] then
                        source $ZSHBOP_ROOT/cmds/os-linux.zshrc
                        echo "- Loading cmds/os-linux.zshrc"
	elif [[ $MACHINE_OS = "WSL" ]]; then
                	echo "- Loading cmds/os-wsl.zshrc"
	                source $ZSHBOP_ROOT/cmds/os-wsl.zshrc
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
			fi				
	elif [[ $MACHINE_OS == "Mac" ]]; then
		_debug "Checking for Mac package manager"
			if [[ $(_cexists brew) ]]; then
				_debug "Found brew setting \$PKG_MANAGER to apt-get"
				PKG_MANAGER="brew"
			fi		
	fi
}

# -- Init
init () {
        _echo "-- Starting init"
        _debug "\$ZSHBOP_ROOT = $ZSHBOP_ROOT"
        
	_echo "-- Detecting Operating System"
        # -- Detect operating system
        export UNAME=$(uname -s)
        case "${UNAME}" in
            Linux*)     MACHINE_OS=Linux;;
            Darwin*)    MACHINE_OS=Mac;;
            CYGWIN*)    MACHINE_OS=Cygwin;;
            MINGW*)     MACHINE_OS=MinGw;;
            *)          MACHINE_OS="UNKNOWN:${unameOut}"
        esac

        if [[ $(uname -r) =~ "Microsoft" || $(uname -r) =~ "microsoft" ]]; then
        	MACHINE_OS="WSL"
        fi
        
        echo "	-- Running in ${MACHINE_OS}"

	# -- Init paths
        init_path
	source $ZSHBOP_ROOT/help.zshrc # help command

	# -- Init package manager
	init_pkg_manager
	
        # -- Include commands
        for file in "${ZSHBOP_ROOT}/cmds/"cmds-*; do
		source $file
        done

	# -- Include aliases @@ISSUE
        source $ZSHBOP_ROOT/aliases.zshrc

	# -- Init OhMyZSH plugins
        init_omz_plugins
        
        # -- Init antigen
        init_antigen
        
        # -- Init defaults @@ISSUE
        init_defaults

	# -- Skip when running rld
	_debug "\$funcstack = $funcstack"
	if [[ $funcstack[4] != "zshbop_reload" ]]; then
		init_sshkeys
		startup_motd
	else
		echo " -- Skipped some scripts due to running rld"
	fi
}

# -- startup_motd - initial scripts to run on login
startup_motd () {
	_debug_function
	echo ""
	_joe_ftyperc
        neofetch
        zshbop
        zshbop_check-migrate
        zshbop_previous-version-check
        echo "-- Screen Sessions --"
	if _cexists screen; then
		screen -list
	else
		echo "** Screen not installed"
	fi
        echo "---- Run checkenv to make sure you have all the right tools! ----"
        echo ""
        echo ""
}
