# --------------
# -- Init
# --------------
# This is the initilization for jtzsh

# -----------------------
# -- One line functions
# -----------------------

# -- Init
init () {
        #- Include functions file
        _echo "-- Starting init"
        source $ZSH_ROOT/functions.zshrc
        source $ZSH_ROOT/aliases.zsh
        init_path
        init_omz_plugins
        init_antigen
        init_defaults
        init_sshkeys
        if [[ $ENABLE_ULTB == 1 ]]; then init_ultb; fi
        if [[ $ENABLE_UWT == 1 ]]; then init_uwt; fi
}

# -- PATHS!
init_path () {
        export PATH=$PATH:$HOME/bin:/usr/local/bin:$ZSH_ROOT
        export PATH=$PATH:$HOME/.local/bin
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
        if [[ -a $ZSH_ROOT/antigen.zsh ]]; then
                _debug "- Loading antigen from $ZSH_ROOT/antigen.zsh";
		source $ZSH_ROOT/antigen.zsh
		antigen init $ZSH_ROOT/.antigenrc
        else
                _echo "	- Couldn't load antigen..";
        fi
}

# -- Load default zsh scripts
init_defaults () {
        _echo "-- Loading default scripts"
        source $ZSH_ROOT/defaults.zshrc
        source $ZSH_ROOT/w10.zshrc

        # Find out if we have personal ZSH scripts.
        printf "-- Loading personal ZSH scripts...\n"
        if [[ -a $ZSH_ROOT/zsh-personal/.zshrc || -L $ZSH_ROOT/zsh-personal/.zshrc ]]; then
                ZSH_PERSONAL_DIR=$ZSH_ROOT/zsh-personal
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
}

# -- Load default SSH keys into keychain
init_sshkeys () {
	_echo "-- Loading SSH keychain"
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
        	_debug " - Check for custom SSH key via $SSH_KEY and load keychain"
	        if [ ! -z "${SSH_KEY+1}" ]; then
        	        _debug " - FOUND: $SSH_KEY"
                	eval `keychain -q --eval --agents ssh $SSH_KEY`
	        else
        	        _debug " - NOTFOUND: $SSH_KEY not set."
	        fi

		# Load any id_rsa* keys
		if [[ $ENABLE_ALL_SSH_KEYS == 1 ]]; then
			eval `keychain -q --eval --agents ssh $HOME/.ssh/id_rsa*`
		fi
	else
		_echo " - Command keychain doesn't exist, please install for SSH keys to work"
	fi
}

# -- Ultimate Linux Tool Box
init_ultb () {
        if [[ -a $ZSH_ROOT/ultimate-linux-tool-box/.zshrc ]]; then
                _echo "-- Including Ultimate Linux Tool Box Paths"
                source $ZSH_ROOT/ultimate-linux-tool-box/.zshrc
	fi
       	export PATH=$PATH:$ZSH_ROOT/ultimate-linux-tool-box
}

# -- Ultimate WordPress Tools
init_uwt () {
        if [[ -a $ZSH_ROOT/ultimate-wordpress-tools/.zshrc ]]; then
                _echo "-- Including Ultimate WordPress Tools"
                source $ZSH_ROOT/ultimate-wordpress-tools/.zshrc
	fi
	export PATH=$PATH:$ZSH_ROOT/ultimate-wordpress-tools
}