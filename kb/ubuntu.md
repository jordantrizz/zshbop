# Ubuntu
# DNS
## Check DNS
```
systemd-resolve --status
```
## Check if DHCP is being used
```
cat /etc/netplan/*network*
```

## Check resolvconf
```
cat /etc/resolvconf/resolv.conf.d/*
```

## Clear Local DNS Cache
```
systemd-resolve --flush-caches
systemd-resolve --statistics
```

# Time and Date Sync
* Check to see firewall is block tcp/udp 123 for NTP.
* ```journalctl -u systemd-timesyncd```
* ```systemctl restart systemd-timesyncd```
* ```timedatectl```
* ```timedatectl set-ntp on```

# Unattended Updates
## Install and unattended-upgrades
```
sudo apt-get install unattended-upgrades
sudo dpkg-reconfigure --priority=low unattended-upgrades
```
## Check for updates
```
sudo unattended-upgrade -d
```
## Dry run
```
sudo unattended-upgrade -d --dry-run
```

# Setting Swap
```
fallocate -l 1G /swapfile
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
```

# Single User Mode
1. Boot server and select Ubuntu and hit 'e'
2. In the editor, search for the line that starts with “linux” and has parameters like root=/dev/disk-device
3. Remove ro and add rw init=/bin/bash at the end of the line
4. Hit 'F10' to boot into single user mode.