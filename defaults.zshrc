# ------------
# -- Variables
# ------------
export UNAME=$(uname -s)
case "${UNAME}" in
    Linux*)     MACHINE=Linux;;
    Darwin*)    MACHINE=Mac;;
    CYGWIN*)    MACHINE=Cygwin;;
    MINGW*)     MACHINE=MinGw;;
    *)          MACHINE="UNKNOWN:${unameOut}"
esac
echo "- Running in ${MACHINE}"

# Colors
autoload colors
if [[ "$terminfo[colors]" -gt 8 ]]; then
    colors
fi
for COLOR in RED GREEN YELLOW BLUE MAGENTA CYAN BLACK WHITE; do
    eval $COLOR='$fg_no_bold[${(L)COLOR}]'
    eval BOLD_$COLOR='$fg_bold[${(L)COLOR}]'
done
eval RESET='$reset_color'
eval BGRED='$bg[red]'
eval BGGREEN='$bg[green]'

# Default tools
default_tools=('mosh' 'traceroute' 'mtr' 'pwgen' 'tree' 'ncdu' 'fpart' 'whois' 'pwgen')

# ----------
# -- Exports
# ----------
zmodload zsh/mapfile
export HISTSIZE=5000
export PAGER='less -Q -j16'
export EDITOR='joe'
export BLOCKSIZE='K'
export bgnotify_threshold='6' # https://github.com/robbyrussell/oh-my-zsh/tree/master/plugins/bgnotify
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8
export LANGUAGE=en_US.UTF-8


# -----------------------------------
# - Include OS Specific configuration
# -----------------------------------
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

# ------------------
# -- fzf keybindings
# ------------------
# Need to enable if fzf is available
#[ -f $ZSH_CUSTOM/.fzf-key-bindings.zsh ] && source $ZSH_CUSTOM/.fzf-key-bindings.zsh;echo "Enabled FZF keybindgs"
####-- diff-so-fancy
git config --global core.pager "diff-so-fancy | less --tabs=4 -RFX"