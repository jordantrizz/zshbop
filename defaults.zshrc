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
# -- Evnrionment
setup_environment () {
       apt install python-pip npm aptitude mtr dnstracer wamerican
       pip install apt-select
       npm install -g gnomon
}
# -- Ultimate Linux Tool Box
ultb_path () {
        if [[ -a $GIT_ROOT/ultimate-linux-tool-box/path.zshrc ]]; then
                echo "- Including Ultimate Linux Tool Box Paths"
                source $GIT_ROOT/ultimate-linux-tool-box/path.zshrc
        fi
}

# -- Update
update () {
	git -C $GIT_ROOT pull --recurse-submodules
	git -C $GIT_ROOT submodule update --init --recursive
	git -C $GIT_ROOT submodule update --recursive --remote
	rld
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
alias toc="gh-md-toc --nobackup-insert README.md"
alias joe4="joe --wordwrap -nobackups -tab 4"
alias pk="cat ~/.ssh/id_rsa.pub"

# -- web stuff
alias ttfb='curl -o /dev/null -w "Connect: %{time_connect} TTFB: %{time_starttransfer} Total time: %{time_total} \n" $1'
alias ab_quick="ab -c 5 -n 100 $1"
alias phpinfo="echo '<?php phpinfo() ?>' > phpinfo.php"
alias dhparam="openssl dhparam -out dhparam.pem 2048"

# -- git
alias gp="git submodule foreach git pull origin master"
alias gs="git submodule update --init --recursive;git submodule update --recursive --remote"
alias gr="cd ~/git;"