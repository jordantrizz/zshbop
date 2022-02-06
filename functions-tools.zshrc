# ----------------------------
# -- Functions that are Tools!
# ----------------------------

# -- Linux Specific
findswap () { find /proc -maxdepth 2 -path "/proc/[0-9]*/status" -readable -exec awk -v FS=":" '{process[$1]=$2;sub(/^[ \t]+/,"",process[$1]);} END {if(process["VmSwap"] && process["VmSwap"] != "0 kB") printf "%10s %-30s %20s\n",process["Pid"],process["Name"],process["VmSwap"]}' '{}' \; | awk '{print $(NF-1),$0}' | sort -h | cut -d " " -f2- }

# -- Nginx
nginx-inc () { cat $1; grep '^.*[^#]include' $1 | awk {'print $2'} | sed 's/;\+$//' | xargs cat }
alias ngx404log="$ZSH_ROOT/bin/ngx404log.sh"

# -- Exim
eximcq () { exim -bp | exiqgrep -i | xargs exim -Mrm }

# -- curl
vh () { vh_run=$(curl --header "Host: $1" $2 --insecure -i | head -50);echo $vh_run }

# -- SSL
check_ssl () { echo | openssl s_client -showcerts -servername $1 -connect $1:443 2>/dev/null | openssl x509 -inform pem -noout -text }
