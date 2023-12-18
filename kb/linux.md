# Ubuntu 18
## /etc/resolve.conf
* Edit /run/systemd/resolve/resolv.conf
* ```sudo ln -sf /run/systemd/resolve/resolv.conf /etc/resolv.conf```
## Hostname Change
* Use the command hostnamectl
* You might need to update /etc/cloud/cloud.cfg and change "preserve_hostname" from "false" to "true".
```
hostnamectl set-hostname srv01.prod.bluinf.com
```

# Commands
## Network
### Get Ports from /etc/proc/net/tcp
```awk '$4 == "0A" { port=substr($2, index($2, ":")+1); print "Port:", strtonum("0x" port) }' /proc/net/tcp /proc/net/tcp6 2>/dev/null || awk '$4 == "0A" { port=substr($2, index($2, ":")+1); cmd="echo $((0x" port "))"; cmd | getline port; close(cmd); print "Port:", port }' /proc/net/tcp /proc/net/tcp6```
