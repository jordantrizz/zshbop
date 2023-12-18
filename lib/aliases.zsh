#!/usr/bin/env zsh
# -----------------------------------------------------------------------------------
# -- aliases.zsh -- This file contains all the aliases for zshbop
# -----------------------------------------------------------------------------------
_debug_load

# -----------------
# -- Common aliases
# -----------------

alias joe="joe --wordwrap -nobackups -tab 4"
function joe-wrapper { joe --wordwrap -nobackups -tab 4 $@ }
alias sbin="cd /usr/local/sbin"
alias which="which -a"
alias randpass="pwgen -s 5 1;pwgen -s 15 1;pwgen -s 20 1;pwgen -sy 20 1"
alias zcc="rm ~/.zcompdump*"
alias error_log="find . | grep error_log | xargs tail | less"
alias rm_error_log="find . | grep error_log | xargs -pl rm"
alias cg="clustergit"
alias toc="gh-md-toc --insert README.md"
alias joe4="joe --wordwrap -nobackups -tab 4"
alias fdcount="tree | grep directories"
alias lessn="less -N"

# - Shell Aliases
#alias mtime="find . -type f -printf "\n%TD %TT %p" | sort -k1.8n -k1.1nr -k1 | less"
alias mtime="find . -type f -printf "%TY-%Tm-%Td %TT %p\n" | sort -r | less"
alias path='echo $PATH | tr ":" "\n"'

# -- Web Aliases
alias ab_quick="ab -c 5 -n 100 $1"
alias dhparam="openssl dhparam -out dhparam.pem 2048"
alias lynx="lynx  -accept_all_cookies $@"

# -- GIT configuration and aliases
alias gitp="git submodule foreach git pull origin master"
alias gits="git submodule update --init --recursive;git submodule update --recursive --remote"
alias gitr="cd ~/git;"

# -- Ubuntu Specific
alias wsl-screen="sudo /etc/init.d/screen-cleanup start"

# -- Software
alias yabs='yabs.sh'
alias mysqltuner='mysqltuner.pl'

# - ssh
alias sshc="ssh-connect"
function sshr { ssh root@$1 }
alias ssh-keygen="ssh-keygen -t ed25519"

# -- zsh
alias checkzsh="init_checkzsh"