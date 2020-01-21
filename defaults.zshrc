# - Variables
export UNAME=$(uname -s)
case "${UNAME}" in
    Linux*)     MACHINE=Linux;;
    Darwin*)    MACHINE=Mac;;
    CYGWIN*)    MACHINE=Cygwin;;
    MINGW*)     MACHINE=MinGw;;
    *)          MACHINE="UNKNOWN:${unameOut}"
esac
echo "- Running in ${MACHINE}"
zmodload zsh/mapfile
export HISTSIZE=5000
export PAGER='less -Q -j16'
export EDITOR='joe'
export BLOCKSIZE='K'
export bgnotify_threshold='6' # https://github.com/robbyrussell/oh-my-zsh/tree/master/plugins/bgnotify
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8
export LANGUAGE=en_US.UTF-8


# - One Line Functions
# Needs to include help and checking if $1 and $2 exist
msds () { zgrep "INSERT INTO \`$2\`" $1 |  sed "s/),/),\n/g" }

# - Include OS Specific configuration
if [[ $MACHINE == "Mac" ]] then
        echo "- Loading mac.zshrc"
        source $ZSH_ROOT/mac.zshrc
elif [[ $MACHINE = "Linux" ]] then
	if [[ $(uname -r) == "Microsoft" ]] then
		echo "Microsoft WSL"
	else
        	source $ZSH_ROOT/linux.zshrc
        fi
fi
# - Paths

# -- fzf keybindings
# Need to enable if fzf is available
#[ -f $ZSH_CUSTOM/.fzf-key-bindings.zsh ] && source $ZSH_CUSTOM/.fzf-key-bindings.zsh;echo "Enabled FZF keybindgs"
####-- diff-so-fancy
git config --global core.pager "diff-so-fancy | less --tabs=4 -RFX"