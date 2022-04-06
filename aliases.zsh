#!/usr/bin/env zsh
# ------------------------
# -- zshbop aliases file
# -------------------------
# This file contains all the aliases for zshbop

_debug "Loading mypath=${0:a}"

# -----------------
# -- Common aliases
# -----------------

alias joe="joe --wordwrap -nobackups"
alias sbin="cd /usr/local/sbin"
alias cpu="lscpu | grep -E '^Thread|^Core|^Socket|^CPU\('"
alias which="which -a"
alias randpass="pwgen -s 5 1;pwgen -s 15 1;pwgen -s 20 1;pwgen -sy 20 1"
alias zcc="rm ~/.zcompdump*"
alias error_log="find . | grep error_log | xargs tail | less"
alias rm_error_log="find . | grep error_log | xargs -pl rm"
alias cg="clustergit"
alias toc="gh-md-toc --insert README.md"
alias joe4="joe --wordwrap -nobackups -tab 4"
#alias pk="ls -1 ~/.ssh/*.pub | xargs -L 1 -I {} sh -c 'cat {};echo "\n-----------------------------"'"
alias fdcount="tree | grep directories"
alias whatismyip='dig @resolver1.opendns.com A myip.opendns.com +short -4;dig @resolver1.opendns.com AAAA myip.opendns.com +short -6'
alias listen='netstat -anp | grep LISTEN'
alias lessn="less -N"
alias highcpu="ps aux | sort -nrk 3,3 | head -n 5"

# - Shell Aliases
#alias mtime="find . -type f -printf "\n%TD %TT %p" | sort -k1.8n -k1.1nr -k1 | less"
alias mtime="find . -type f -printf "%TY-%Tm-%Td %TT %p\n" | sort -r | less"
alias path='echo $PATH | tr ":" "\n"'

# -- Web Aliases
alias ttfb='curl -s -o /dev/null -w "Connect: %{time_connect} TTFB: %{time_starttransfer} Total time: %{time_total} \n" $1'
alias ab_quick="ab -c 5 -n 100 $1"
alias dhparam="openssl dhparam -out dhparam.pem 2048"
alias lynx="lynx  -accept_all_cookies $@"

# -- GIT configuration and aliases
alias gitp="git submodule foreach git pull origin master"
alias gits="git submodule update --init --recursive;git submodule update --recursive --remote"
alias gitr="cd ~/git;"

# -- Ubuntu Specific
alias netselect='netselect -v -s10 -t20 `wget -q -O- https://launchpad.net/ubuntu/+archivemirrors | grep -P -B8 "statusUP|statusSIX" | grep -o -P "(f|ht)tp://[^\"]*"`'
alias wsl-screen="sudo /etc/init.d/screen-cleanup start"

# -- Software
alias yabs='yabs.sh'

# -- Screen
alias screen="screen -c $ZSH_ROOT/.screenrc"
alias screens="screen -list"

# - ssh
alias sshc="ssh-connect"
