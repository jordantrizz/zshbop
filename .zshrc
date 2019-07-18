# We use $ZSH_ROOT to know our working directory.
if [ -z "$ZSH_ROOT" ]; then
      echo "\$ZSH_ROOT empty so using \$HOME/zsh"
      export ZSH_ROOT=$HOME/zsh
fi
# If you come from bash you might have to change your $PATH.
export PATH=$PATH:$HOME/bin:/usr/local/bin:$ZSH_ROOT
export TERM="xterm-256color"
# Localtion of git repository

# Initialize antigen
if [[ -a $ZSH_ROOT/antigen.zsh ]]; then
        echo "Loading antigen from $ZSH_ROOT/antigen.zsh";
        source $ZSH_ROOT/antigen.zsh

	# Use oh-my-zsh
	# ZSH plugins
	plugins=( git osx bgnotify mysql-colorize extract history z cloudapp )
        # oh-my-zsh Custom directory
        export ZSH_CUSTOM="$ZSH_ROOT/custom"
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

# -- External Plugins
source ~/.antigen/bundles/zsh-users/zsh-autosuggestions/zsh-autosuggestions.zsh
#. $ZSH/plugins/z/z.sh - broken

# Default ZSH aliases and other functions
source $ZSH_ROOT/defaults.zshrc

# Check for SSH_KEY and run keychain
echo "Checking for \$SSH_KEY and loading keychain"
if [[ -v SSH_KEY ]]; then
	echo " - FOUND: $SSH_KEY"
	eval `keychain --eval --agents ssh $SSH_KEY`
fi

# Personal Config outside of git repo
echo "Loading personal ZSH config...";
if [[ -a $ZSH_ROOT/zsh-personal/.zshrc || -L $ZSH_ROOT/zsh-personal/.zshrc ]]; then 
	echo "- Loaded \$ZSH_ROOT/zsh-personal/.zshrc";
        source $ZSH_ROOT/zsh-personal/.zshrc
else
        echo " - No personal ZSH config loaded";
fi

function options() {
    PLUGIN_PATH="$HOME/.oh-my-zsh/plugins/"
    for plugin in $plugins; do
        echo "\n\nPlugin: $plugin"; grep -r "^function \w*" $PLUGIN_PATH$plugin | awk '{print $2}' | sed 's/()//'| tr '\n' ', '; grep -r "^alias" $PLUGIN_PATH$plugin | awk '{print $2}' | sed 's/=.*//' |  tr '\n' ', '
    done
}