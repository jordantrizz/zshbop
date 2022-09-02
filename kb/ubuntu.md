# Ubuntu
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
