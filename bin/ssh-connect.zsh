#!env /bin/zsh
SSH_HOSTS_CLEANUP=$(cat ~/.zsh_history | grep -E "(^|;)ssh\s[-0-9A-Za-z]" | grep -v "\--" | sed -e 's/\s*$//' | sed -e 's/:\s[0-9]*:[0-9]*;//')
[[ -z $SSH_HOSTS_CLEANUP ]] && echo "No data in \$SSH_HISTORY" || echo "Got data in \$SSH_HISTORY"

SSH_HOSTS_TOP=$(echo $SSH_HOSTS_CLEANUP | sort | uniq -c | sort -nr | sed -e 's/^\s*[0-9]*\s//' | head -10 | tr '\n' '|')
SSH_HOSTS_LAST=$(echo $SSH_HOSTS_CLEANUP | tail -15 | tr '\n' '|')
SSH_HOSTS=$SSH_HOSTS_LAST


res=$(listbox -t "Last 10 SSH Connections" -o "$SSH_HOSTS" | tee /dev/tty | tail -n 1)
$(expr "$res")
