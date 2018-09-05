# Variables
export UNAME=$(uname -s)
case "${UNAME}" in
    Linux*)     MACHINE=Linux;;
    Darwin*)    MACHINE=Mac;;
    CYGWIN*)    MACHINE=Cygwin;;
    MINGW*)     MACHINE=MinGw;;
    *)          MACHINE="UNKNOWN:${unameOut}"
esac
echo "Running in ${MACHINE}"

# Include OS Specific configuration
if [[ $MACHINE == "Mac" ]] then
	source $GIT_ROOT/mac.zshrc
elif [[ $MACHINE = "Linux" ]] then
	soruce $GIT_ROOT/linux.zshrc
fi

# -- Paths
export PATH=$PATH:~/.antigen/bundles/so-fancy/diff-so-fancy
# -- Source
# - fzf keybindings
[ -f $ZSH_CUSTOM/.fzf-key-bindings.zsh ] && source $ZSH_CUSTOM/.fzf-key-bindings.zsh;echo "Enabled FZF keybindgs"

# -- General Settings
zmodload zsh/mapfile
export HISTSIZE=5000
export PAGER='less -Q -j16'
export EDITOR='joe'
export BLOCKSIZE='K'
export bgnotify_threshold='6' # https://github.com/robbyrussell/oh-my-zsh/tree/master/plugins/bgnotify

# -- Plugin Configuration
# AUTO_LS
AUTO_LS_COMMANDS=('color' git-status)
auto-ls-color () {
	ls;echo "\n";
}

# -- General Aliases
alias joe="joe --wordwrap -nobackups"
alias rld="source ~/.zshrc"
alias jp="joe -wordwrap -nobackups ~/.personal.zshrc"
alias jz="joe -wordwrap -nobackups ~/.zshrc"
alias sbin="cd /usr/local/sbin"
alias cpu="lscpu | grep -E '^Thread|^Core|^Socket|^CPU\('"
alias which="which -a"
alias randpass="randpass -n 15 -f"
alias zcc="rm ~/.zcompdump*"
alias diff-so-fancy="~/.antigen/bundles/so-fancy/diff-so-fancy/diff-so-fancy"
