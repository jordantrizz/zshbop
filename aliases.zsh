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
alias pk="cat ~/.ssh/*.pub"
alias fdcount="tree | grep directories"
alias whatismyip='dig @resolver1.opendns.com A myip.opendns.com +short -4;dig @resolver1.opendns.com AAAA myip.opendns.com +short -6'

# - Shell Aliases
#alias mtime="find . -type f -printf "\n%TD %TT %p" | sort -k1.8n -k1.1nr -k1 | less"
alias mtime="find . -type f -printf "%TY-%Tm-%Td %TT %p\n" | sort -r | less"
alias path='echo $PATH | tr ":" "\n"'

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

# -- NGiNX
nginx-inc () { cat $1; grep '^.*[^#]include' $1 | awk {'print $2'} | sed 's/;\+$//' | xargs cat }

# -- Exim
eximcq () { exim -bp | exiqgrep -i | xargs exim -Mrm }

# -- WSL Specific Aliases
alias wsl-screen="sudo /etc/init.d/screen-cleanup start"

# Ubuntu Specific
alias netselect='netselect -v -s10 -t20 `wget -q -O- https://launchpad.net/ubuntu/+archivemirrors | grep -P -B8 "statusUP|statusSIX" | grep -o -P "(f|ht)tp://[^\"]*"`'
