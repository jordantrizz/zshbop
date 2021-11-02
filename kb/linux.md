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