# We use $ZSH_ROOT to know our working directory.
if [ -z "$ZSH_ROOT" ]; then
      echo "-- \$ZSH_ROOT empty so using \$HOME/zsh"
      export ZSH_ROOT=$HOME/zsh
fi
# If you come from bash you might have to change your $PATH.
export PATH=$PATH:$HOME/bin:/usr/local/bin:$ZSH_ROOT
export PATH=$PATH:.local/bin
export TERM="xterm-256color"
export LANG="C.UTF-8"
export ZSH_CUSTOM="$ZSH_ROOT/custom"

init_antigen () {
	# Initialize antigen
	if [[ -a $ZSH_ROOT/antigen.zsh ]]; then
	        echo "-- Loading antigen from $ZSH_ROOT/antigen.zsh";
	        source $ZSH_ROOT/antigen.zsh

		# ZSH plugins
		plugins=( git osx bgnotify mysql-colorize extract history z cloudapp )

		# Load oh-my-zsh
		antigen use oh-my-zsh
		
	        # Set oh-my-zsh theme to load default is ZSH_THEME="robbyrussell"
		antigen theme bhilburn/powerlevel9k powerlevel9k
	        # Load Powerlevel 9k Customizations
	        source $ZSH_ROOT/powerlevel9k.zshrc
	
		# Continue with loading antigen bundles
	        antigen bundle zsh-users/zsh-syntax-highlighting
	        antigen bundle command-not-found
	        antigen bundle wfxr/forgit
	        antigen bundle andrewferrier/fzf-z
	        source $ZSH_CUSTOM/.fzf-key-bindings.zsh
	        antigen bundle djui/alias-tips
	        #antigen bundle desyncr/auto-ls
	        #antigen bundle MikeDacre/careful_rm
	        antigen bundle viasite-ansible/zsh-ansible-server
	        antigen bundle micha/resty
	        antigen bundle zpm-zsh/mysql-colorize
	        #antigen bundle so-fancy/diff-so-fancy
		#git config --global core.pager "diff-so-fancy | less --tabs=4 -RFX"
		antigen bundle zsh-users/zsh-autosuggestions
	        antigen apply
	else
	        echo " - Couldn't load antigen..";
	fi
}

# -- External Plugins
source ~/.antigen/bundles/zsh-users/zsh-autosuggestions/zsh-autosuggestions.zsh
#. $ZSH/plugins/z/z.sh - broken

sshkeys () {
	# Load default SSH key
	printf "Check for default SSH key %s/.ssh/id_rsa and load keychain\n" $HOME
	if [[ -a $HOME/.ssh/id_rsa || -L $HOME/.ssh/id_rsa ]]; then
		printf " - FOUND: %s\n" $HOME/.ssh/id_rsa
		eval `keychain --eval --agents ssh $HOME/.ssh/id_rsa`
	else
		printf " - NOTFOUND: %s\n" $HOME/.ssh/id_rsa
	fi

	# Check and load custom SSH key
	printf "Check for custom SSH key via \$SSH_KEY and load keychain\n"
	if [ ! -z "${SSH_KEY+1}" ]; then
	        printf " - FOUND: %s\n" $SSH_KEY
	        eval `keychain --eval --agents ssh $SSH_KEY`
	else
		printf " - NOTFOUND: %s not set.\n" $SSH_KEY
	fi
}
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
init_antigen
init_defaults
sshkeys