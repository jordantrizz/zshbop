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