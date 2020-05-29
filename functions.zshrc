#### - Functions
# This file contains all the required functions for the main .zshrc script.

####-- Echo wrapper
_echo () {
	echo "$@"
}

####-- Print to debug
_debug () {
	if [[ $ZSH_DEBUG == 1 ]]; then
		echo "** DEBUG: $@"
	fi
}

####-- Check to see if command exists and then return true or false
_cexists () {
        if (( $+commands[$@] )); then
                if [[ $ZSH_DEBUG == 1 ]]; then
                        _debug "$@ is installed";
                fi
                return 0
        else
                return 1
        fi
}

####-- Init
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

### -- PATHS!
init_path () {
        export PATH=$PATH:$HOME/bin:/usr/local/bin:$ZSH_ROOT
        export PATH=$PATH:$HOME/.local/bin
}

#### -- Initialize oh-my-zsh plugins
init_omz_plugins () {
	_echo "-- Loading OMZ plugins"
	plugins=( git z )
	_echo " - $plugins"
}

#### -- Initialize Antigen
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

####-- Load default zsh scripts
init_defaults () {
	_echo "-- Loading defaults"
        source $ZSH_ROOT/defaults.zshrc

        # Include Personal Configuration if present.
        printf " - Loading personal ZSH config...\n"
        if [[ -a $ZSH_ROOT/zsh-personal/.zshrc || -L $ZSH_ROOT/zsh-personal/.zshrc ]]; then
                _debug " - Loaded $ZSH_ROOT/zsh-personal/.zshrc"
                source $ZSH_ROOT/zsh-personal/.zshrc
        elif [[ -a git/zsh-personal/.zshrc || -L git/zsh-personal/.zshrc ]]; then
                _debug " - Loaded git/zsh-personal/.zshrc"
                source git/zsh-personal/.zshrc
        elif [[ -a $HOME/.personal.zshrc || -L $HOME/.personal.zshrc ]]; then
               _debug " - Loaded $HOME/.personal.zshrc"
               source $HOME/.personal.zshrc
	else
                printf " - No personal ZSH config loaded\n"
        fi
}

####-- Load default SSH keys into keychain
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
		eval `keychain -q --eval --agents ssh $HOME/.ssh/id_rsa*`
	else
		_echo " - Command keychain doesn't exist, please install for SSH keys to work"
	fi
}

####-- Ultimate Linux Tool Box
init_ultb () {
        if [[ -a $ZSH_ROOT/ultimate-linux-tool-box/.zshrc ]]; then
                _echo "-- Including Ultimate Linux Tool Box Paths"
                source $ZSH_ROOT/ultimate-linux-tool-box/.zshrc
	fi
       	export PATH=$PATH:$ZSH_ROOT/ultimate-linux-tool-box
}

####-- Ultimate WordPress Tools
init_uwt () {
        if [[ -a $ZSH_ROOT/ultimate-wordpress-tools/.zshrc ]]; then
                _echo "-- Including Ultimate WordPress Tools"
                source $ZSH_ROOT/ultimate-wordpress-tools/.zshrc
	fi
	export PATH=$PATH:$ZSH_ROOT/ultimate-wordpress-tools
}

####-- Clear Cache
clear_cache () {
	antigen reset
}

####-- Setup Environment
setup_environment () {
	sudo apt install keychain mosh traceroute mtr keychain pwgen tree ncdu fpart whois
	#sudo apt install python-pip npm # Skipping python dependencies
	#sudo pip install apt-select # Skipping python dependencies
       	#sudo npm install -g gnomon # Skipping node dependencies
}

####-- Update
update () {
	cd $ZSH_ROOT
	git pull
        git -C $ZSH_ROOT pull --recurse-submodules
        git -C $ZSH_ROOT submodule update --init --recursive
        git -C $ZSH_ROOT submodule update --recursive --remote
        init_defaults
}

####-- List current functions available to zsh
function options() {
    PLUGIN_PATH="$HOME/.oh-my-zsh/plugins/"
    for plugin in $plugins; do
        _echo "\n\nPlugin: $plugin"; grep -r "^function \w*" $PLUGIN_PATH$plugin | awk '{print $2}' | sed 's/()//'| tr '\n' ', '; grep -r "^alias" $PLUGIN_PATH$plugin | awk '{print $2}' | sed 's/=.*//' |  tr '\n' ', '
    done
}

#### -- Copy Windows Terminal Config
cp_wtconfig () {
	cp /mnt/c/Users/$USER/AppData/Local/Packages/Microsoft.WindowsTerminal_*/LocalState/profiles.json  $ZSH_ROOT/windows_terminal.json
}

#### -- Configure git
git_config () {
	vared -p "Name? " -c GIT_NAME
	vared -p "Email? " -c GIT_EMAIL
	git config --global user.email $GIT_EMAIL
	git config --global user.name $GIT_NAME
	git config --global --get user.email
	git config --global --get user.name
}

#### -- Install required software
install_pkgs () {
    apt-get install pwgen
}

#### -- Help


help () { 
	doc=$1
	if _cexists mdv; then md_reader=mdv; else md_reader=cat  fi
        if [ -z $doc ]; then
		$mdv_reader $ZSH_ROOT/help/$1.md
        fi
        if [ $mdv_reader = "cat" ]
                echo "\n\n\n"
                echo "---------------------------------------"
                echo "mdv not avaialble failing back to cat"
                echo "you should install mdv, pip install mdv"
        fi
}