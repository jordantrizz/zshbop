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

# - General Aliases
alias rld="source $ZSH_ROOT/.zshrc"
alias joe="joe --wordwrap -nobackups"
alias jp="joe --wordwrap -nobackups ~/.personal.zshrc"
alias jz="joe --wordwrap -nobackups $ZSH_ROOT/.zshrc"
alias jd="joe --wordwrap -nobackups $ZSH_ROOT/defaults.zshrc"
alias jm="joe --wordwrap -nobackups $ZSH_ROOT/mac.zshrc"
alias sbin="cd /usr/local/sbin"
alias cpu="lscpu | grep -E '^Thread|^Core|^Socket|^CPU\('"
alias which="which -a"
alias randpass="pwgen -s 5 1;pwgen -s 15 1;pwgen -s 20 1;pwgen -sy 20 1"
alias zcc="rm ~/.zcompdump*"
alias error_log="find . | grep error_log | xargs tail | less"
alias rm_error_log="find . | grep error_log | xargs -pl rm"
alias cg="clustergit"
alias toc="gh-md-toc --nobackup-insert README.md"
alias joe4="joe --wordwrap -nobackups -tab 4"
alias pk="cat ~/.ssh/id_rsa.pub"
alias fdcount="tree | grep directories"
alias whatsmyip='dig @resolver1.opendns.com A myip.opendns.com +short -4;dig @resolver1.opendns.com AAAA myip.opendns.com +short -6'

# -- Web Aliases
alias ttfb='curl -s -o /dev/null -w "Connect: %{time_connect} TTFB: %{time_starttransfer} Total time: %{time_total} \n" $1'
alias ab_quick="ab -c 5 -n 100 $1"
alias phpinfo="echo '<?php phpinfo() ?>' > phpinfo.php"
alias dhparam="openssl dhparam -out dhparam.pem 2048"
alias dnst="dnstracer -o -s b.root-servers.net -4 -r 1"

# -- GIT configuration and aliases
alias gp="git submodule foreach git pull origin master"
alias gs="git submodule update --init --recursive;git submodule update --recursive --remote"
alias gr="cd ~/git;"

####-- diff-so-fancy
git config --global core.pager "diff-so-fancy | less --tabs=4 -RFX"