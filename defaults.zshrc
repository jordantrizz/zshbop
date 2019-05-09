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

# - Functions
ultb_path () {
        if [[ -a $GIT_ROOT/ultimate-linux-tool-box/path.zshrc ]]; then
                echo "- Including Ultimate Linux Tool Box Paths"
                source $GIT_ROOT/ultimate-linux-tool-box/path.zshrc
        fi
}

# - Update
update () {
	git -C $GIT_ROOT pull --recurse-submodules
	git submodule update --init --recursive
}

# Include OS Specific configuration
if [[ $MACHINE == "Mac" ]] then
	echo "- Loading mac.zshrc"
	source $GIT_ROOT/mac.zshrc
elif [[ $MACHINE = "Linux" ]] then
	source $GIT_ROOT/linux.zshrc
fi

# - Paths
# -- Diff so Fancy
export PATH=$PATH:~/.antigen/bundles/so-fancy/diff-so-fancy
# -- Ultimate Linux Tool Box via git submodule add
export PATH=$GIT_ROOT/ultimate-linux-tool-box/:$PATH
ultb_path

# - Source
# -- fzf keybindings
[ -f $ZSH_CUSTOM/.fzf-key-bindings.zsh ] && source $ZSH_CUSTOM/.fzf-key-bindings.zsh;echo "Enabled FZF keybindgs"

# - Plugin Configuration
# AUTO_LS
AUTO_LS_COMMANDS=('color' git-status)
auto-ls-color () {
	ls;echo "\n";
}

# - General Aliases
alias joe="joe --wordwrap -nobackups"
alias rld="source ~/.zshrc"
alias jp="joe --wordwrap -nobackups ~/.personal.zshrc"
alias jz="joe --wordwrap -nobackups $GIT_ROOT/.zshrc"
alias jd="joe --wordwrap -nobackups $GIT_ROOT/defaults.zshrc"
alias jm="joe --wordwrap -nobackups $GIT_ROOT/mac.zshrc"
alias sbin="cd /usr/local/sbin"
alias cpu="lscpu | grep -E '^Thread|^Core|^Socket|^CPU\('"
alias which="which -a"
alias randpass="randpass -n 15 -f"
alias zcc="rm ~/.zcompdump*"
alias diff-so-fancy="~/.antigen/bundles/so-fancy/diff-so-fancy/diff-so-fancy"
alias error_log="find . | grep error_log | xargs tail | less"
alias rm_error_log="find . | grep error_log | xargs -pl rm"
alias cg="clustergit"
alias ab_quick="ab -c 5 -n 100 $1"
alias toc="gh-md-toc --nobackup-insert README.md"
alias joe4="joe --wordwrap -nobackups -tab 4"

# -- git
alias gp="git pull --recurse-submodules"
alias gs="git submodule update --init --recursive"
