# Common Proxmox Commands
* List Storage ```pvesm list```
* List VM Config ```qm config 102```

# Cloud Init Setup
## Ubuntu 20 Template Setup
```
wget https://cloud-images.ubuntu.com/focal/current/focal-server-cloudimg-amd64.img
qm create 9000 --memory 2048 --net0 virtio,bridge=vmbr0
qm importdisk 9000 focal-server-cloudimg-amd64.img local-lvm
qm set 9000 --scsihw virtio-scsi-pci --scsi0 local-lvm:vm-9000-disk-0
qm set 9000 --ide2 local-lvm:cloudinit
qm set 9000 --boot c --bootdisk scsi0
qm set 9000 --serial0 socket --vga serial0
qm template 9000
```

## Deploy from Template
```qm clone 9000 `pvesh get /cluster/nextid` --name zshdev```
### Set networking
```
qm set 123 --ipconfig0 ip=10.0.10.123/24,gw=10.0.10.1
```
### DHCP Networking
```
qm set 123 --ipconfig0 ip=dhcp
```
### Set SSH Key
```qm set 123 --sshkey ~/.ssh/id_rsa.pub```

### Override Cloud Init with Custom File
Note: User config will overwrite automatic config from proxmox, so vendor is preferred.
1. Create snippets storage
* ID: snippets
* Directory: /var/lib/vz
2. Create cloud-init.yml
3. Apply to VM
```
qm set 102 --cicustom "user=snippets:snippets/cloud-init.yml"
``` 
or
```
qm set 100 --cicustom "vendor=local:snippets/vendor.yml"
```

### One Liner
```
export NVMID=`pvesh get /cluster/nextid`
qm clone 9000 $NVMID --name zshdev
qm set $NVMID --ipconfig0 ip=dhcp
qm set $NVMID --cicustom "user=local:snippets/cloud-init.yml,vendor=local:snippets/vendor.yml"
```
## Common Commands
* List Cloud Init Settings ```qm cloudinit dump 102 user```
* Restart Proxmox ```systemctl restart pve-cluster```

# Email
## Sending with postmark
*  joe /etc/postfix/main.cf
```
relayhost = [smtp.postmarkapp.com]:587
smtp_use_tls = yes
smtp_sasl_auth_enable = yes
smtp_sasl_security_options = noanonymous
smtp_sasl_password_maps = hash:/etc/postfix/sasl_passwd
smtp_tls_CAfile = /etc/ssl/certs/ca-certificates.crt
smtp_header_checks = pcre:/etc/postfix/smtp_header_checks
```
* joe /etc/postfix/sasl_passwd
```
[smtp.postmarkapp.com]:587    username:password
```
* postmap /etc/postfix/sasl_passwd
* systemctl restart postfix
## Filter Email and change root emails To:
* joe /etc/postfix/smtp_header_checks
```
/^From:.*/ REPLACE From: server@domain.com
/^To:.*root@server.domain.com$/ REPLACE To: alerts@domain.com
```
* postmap /etc/postfix/smtp_header_checks
* joe /etc/postfix/main.cf
```
smtp_header_checks = pcre:/etc/postfix/smtp_header_checks
```
* systemctl restart postfix

# Advanced Actions
## Changing Hostname
* Edit /etc/hosts file from “proxmox1.sysadminote.com proxmox1″ to “proxmox2.sysadminote.com proxmox2″ 
* Edit /etc/hostname file from “proxmox1″ to “proxmox2″.
* ```cp -R /etc/pve/nodes/oldhostname/ /root/```
* ```mv /etc/pve/nodes/oldhostname/* /etc/pve/nodes/newhostname/*```

# Troubleshooting
## Backup Stuck
* Unmount storage that is affected with unmount -f or -l
* Kill vzdump process with kill -9
* Unlock the vm with ```qm unlock 108```
