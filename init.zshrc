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
zmodload zsh/mapfile
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

# -- zshbop specific environment variables


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
autoload colors
if [[ "$terminfo[colors]" -gt 8 ]]; then
    colors
fi

# -- Don't think this is needed
#for COLOR in RED GREEN YELLOW BLUE MAGENTA CYAN BLACK WHITE; do
#    eval $COLOR='$fg_no_bold[${(L)COLOR}]'
#    eval BOLD_$COLOR='$fg_bold[${(L)COLOR}]'
#done
#eval RESET='$reset_color'
#eval BGRED='$bg[red]'
#eval BGGREEN='$bg[green]'

# -- Unsorted stuff.
# Default tools to install
default_tools=('mosh' 'traceroute' 'mtr' 'pwgen' 'tree' 'ncdu' 'fpart' 'whois' 'pwgen' 'python3-pip' 'joe' 'keychain' 'dnsutils' 'whois' 'gh' 'php-cli' 'telnet' 'lynx' 'jq' 'shellcheck' )
extra_tools=('pip' 'npm')
pip_install=('ngxtop' 'apt-select')

# -- fzf keybindings
# Need to enable if fzf is available
#[ -f $ZSH_CUSTOM/.fzf-key-bindings.zsh ] && source $ZSH_CUSTOM/.fzf-key-bindings.zsh;echo "Enabled FZF keybindgs"
####-- diff-so-fancy
git config --global core.pager "diff-so-fancy | less --tabs=4 -RFX"

# ------------
# -- Functions
# ------------

# -- init_path - setup all the required paths.
init_path () {
	# Default paths to look for
        export PATH=$PATH:$HOME/bin:/usr/local/bin:$ZSHBOP_ROOT:$ZSHBOP_ROOT/bin
        export PATH=$PATH:$HOME/.local/bin
        
        # Extra software
        export PATH=$PATH:$ZSHBOP_ROOT/bin/cloudflare-cli # https://github.com/bAndie91/cloudflare-cli
	export PATH=$PATH:$ZSHBOP_ROOT/bin/clustergit # https://github.com/mnagel/clustergit
	export PATH=$PATH:$ZSHBOP_ROOT/bin/MySQLTuner-perl # https://github.com/major/MySQLTuner-perl
	export PATH=$PATH:$ZSHBOP_ROOT/bin/parsyncfp # https://github.com/hjmangalam/parsyncfp
	export PATH=$PATH:$ZSHBOP_ROOT/bin/httpstat # https://github.com/reorx/httpstat
	
	# Repos - Needs to be updated to find repos installed and add them to $PATH
	export PATH=$PATH:$ZSHBOP_ROOT/repos/gp-tools
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
        # Find out if we have personal ZSH scripts.
        printf "-- Loading personal ZSH scripts...\n"
        if [[ -a $ZSHBOP_ROOT/zsh-personal/.zshrc || -L $ZSHBOP_ROOT/zsh-personal/.zshrc ]]; then
                ZSH_PERSONAL_DIR=$ZSHBOP_ROOT/zsh-personal
        elif [[ -a $HOME/git/zsh-personal/.zshrc || -L $HOME/git/zsh-personal/.zshrc ]]; then
                ZSH_PERSONAL_DIR=$HOME/git/zsh-personal
        elif [[ -a $HOME/.personal.zshrc || -L $HOME/.personal.zshrc ]]; then
                ZSH_PERSONAL_SCRIPT=$HOME/.personal.zshrc
        fi

        # Source personal configuration
        if [ ! -z $ZSH_PERSONAL_DIR ]; then
                echo " - Loading $ZSH_PERSONAL_DIR/.zshrc"
                source $ZSH_PERSONAL_DIR/.zshrc
        elif [ ! -z $ZSH_PERSONAL_SCRIPT]; then
                echo " - Loading $ZSH_PERSONAL_SCRIPT"
                source $ZSH_PERSONAL_SCRIPT
        else
                printf " - No personal ZSH config loaded\n"
        fi
        
	# Include OS Specific configuration
	if [[ $MACHINE_OS == "Mac" ]] then
        	echo "- Loading os/mac.zshrc"
	        source $ZSHBOP_ROOT/os/mac.zshrc
	elif [[ $MACHINE_OS = "Linux" ]] then
        	if [[ $(uname -r) =~ "Microsoft" || $(uname -r) =~ "microsoft" ]] then
                	echo "- Loading os/wsl.zshrc"
	                source $ZSHBOP_ROOT/os/wsl.zshrc
	        else
	                source $ZSHBOP_ROOT/os/linux.zshrc
        	        echo "- Loading os/linux.zshrc"
	        fi
	fi

	# --- Include custom configuration
	if [ -f $HOME/.zshbop ]; then
        	echo " -- Loading custom configuration"
	        source $HOME/.zshbop
	fi
}

# -- Load default SSH keys into keychain
init_sshkeys () {
	
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
        echo "	-- Running in ${MACHINE_OS}"

	# -- Init paths
        init_path
	source $ZSHBOP_ROOT/help.zshrc # help command

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
	_debug "\$funcstack is $funcstack"
	if [[ $funcstack[4] != "zshbop_reload" ]]; then
		init_sshkeys
		startup_motd
	else
		echo " -- Skipped some scripts due to running rld"
	fi
}

# -- startup_motd - initial scripts to run on login
startup_motd () {
	echo ""
        neofetch
        zshbop
        zshbop_check-migrate
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
