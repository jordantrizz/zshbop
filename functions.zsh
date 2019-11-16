####
#- Functions
# This file contains all the required functions for the main .zshrc script.
####

####
#-- Initialize oh-my-zsh plugins
####
init_omz_plugins () {
	echo "-- Loading OMZ plugins"
	plugins=( git osx bgnotify mysql-colorize extract history z cloudapp )
	echo " - $plugins"
}

####
#-- Initialize Antigen
####
init_antigen () {
        # Initialize antigen
        if [[ -a $ZSH_ROOT/antigen/bin/antigen.zsh ]]; then
                echo "-- Loading antigen from $ZSH_ROOT/antigen/bin/antigen.zsh";
		source $ZSH_ROOT/antigen/bin/antigen.zsh
		antigen init $ZSH_ROOT/.antigenrc

		#- External Plugins
		#source ~/.antigen/bundles/zsh-users/zsh-autosuggestions/zsh-autosuggestions.zsh # broken
		# $ZSH/plugins/z/z.sh # broken

        else
                echo " - Couldn't load antigen..";
        fi
}

####
#-- Load default zsh scripts
####

init_defaults () {
        # Default ZSH aliases and other functions
        source $ZSH_ROOT/defaults.zshrc

        # Include Personal Configuration if present.
        printf "Loading personal ZSH config...\n"
        if [[ -a $ZSH_ROOT/zsh-personal/.zshrc || -L $ZSH_ROOT/zsh-personal/.zshrc ]]; then
                printf "- Loaded %s/zsh-personal/.zshrc\n" $ZSH_ROOT
                source $ZSH_ROOT/zsh-personal/.zshrc
        else
                printf " - No personal ZSH config loaded\n"
        fi
}

####
#-- Load default SSH keys into keychain
####

sshkeys () {
        # Load default SSH key
        printf "Check for default SSH key %s/.ssh/id_rsa and load keychain\n" $HOME
        if [[ -a $HOME/.ssh/id_rsa || -L $HOME/.ssh/id_rsa ]]; then
                printf " - FOUND: %s\n" $HOME/.ssh/id_rsa
                eval `keychain -q --eval --agents ssh $HOME/.ssh/id_rsa`
        else
                printf " - NOTFOUND: %s\n" $HOME/.ssh/id_rsa
        fi

        # Check and load custom SSH key
        printf "Check for custom SSH key via \$SSH_KEY and load keychain\n"
        if [ ! -z "${SSH_KEY+1}" ]; then
                printf " - FOUND: %s\n" $SSH_KEY
                eval `keychain -q --eval --agents ssh $SSH_KEY`
        else
                printf " - NOTFOUND: %s not set.\n" $SSH_KEY
        fi
}

####
#-- Clear Cache
####

clear_cache () {
	antigen reset
}

####
#-- Init Reload
####
init_reload () {
       #- Include functions file
       source $ZSH_ROOT/functions.zsh
       init_antigen
       init_defaults
       sshkeys
}

####
#-- Setup Environment
####
setup_environment () {
       sudo apt install python-pip npm aptitude mtr dnstracer wamerican fpart tree keychain mosh pwgen
       sudo pip install apt-select
       sudo npm install -g gnomon
}

####
#-- Ultimate Linux Tool Box
####
ultb_path () {
        if [[ -a $ZSH_ROOT/ultimate-linux-tool-box/path.zshrc ]]; then
                echo "- Including Ultimate Linux Tool Box Paths"
                source $ZSH_ROOT/ultimate-linux-tool-box/path.zshrc
        fi
}

####
#-- Update
####
update () {
	cd $ZSH_ROOT
	git pull
        git -C $ZSH_ROOT pull --recurse-submodules
        git -C $ZSH_ROOT submodule update --init --recursive
        git -C $ZSH_ROOT submodule update --recursive --remote
        init_defaults
}

####
#-- List current functions available to zsh
####
function options() {
    PLUGIN_PATH="$HOME/.oh-my-zsh/plugins/"
    for plugin in $plugins; do
        echo "\n\nPlugin: $plugin"; grep -r "^function \w*" $PLUGIN_PATH$plugin | awk '{print $2}' | sed 's/()//'| tr '\n' ', '; grep -r "^alias" $PLUGIN_PATH$plugin | awk '{print $2}' | sed 's/=.*//' |  tr '\n' ', '
    done
}
