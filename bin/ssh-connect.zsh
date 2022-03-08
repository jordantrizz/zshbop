#!/bin/zsh
ssh_history=$(cat ~/.zsh_history | grep -E "(^|;)ssh\s[-0-9A-Za-z]" | grep -v "\--" | sed -e 's/\s*$//' | sed -e 's/:\s[0-9]*:[0-9]*;//' | sort | uniq -c | sort -nr | sed -e 's/^\s*[0-9]*\s//' | head -20 )
echo $ssh_history
hist=$(echo $ssh_history | tr '\n' '|')
echo $hist

res=$(listbox -t "Connect:" -o "$hist" | tee /dev/tty | tail -n 1)
echo ""
eval "$res"