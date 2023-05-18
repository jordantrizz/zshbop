# Common Proxmox Commands
* List Storage ```pvesm list```
* List VM Config ```qm config 102```
* List Cloud Init Settings ```qm cloudinit dump 102 user```
* Restart Proxmox ```systemctl restart pve-cluster```

# Common Tasks
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

## Forward 443 to 8006
```/sbin/iptables -t nat -A PREROUTING -p tcp --dport 443 -j REDIRECT --to-ports 8006```
## Changing Hostname
* Edit /etc/hosts file from “proxmox1.sysadminote.com proxmox1″ to “proxmox2.sysadminote.com proxmox2″ 
* Edit /etc/hostname file from “proxmox1″ to “proxmox2″.
* ```cp -R /etc/pve/nodes/oldhostname/ /root/```
* ```mv /etc/pve/nodes/oldhostname/* /etc/pve/nodes/newhostname/*```
* ```restart```
* Update /etc/pve/storage.cfg with the new hostname.

# Troubleshooting
## Backup Stuck
* Unmount storage that is affected with unmount -f or -l
* Kill vzdump process with kill -9
* Unlock the vm with ```qm unlock 108```

# Setups

## Ubuntu 20 Template Setup
* local-lvm is your lvm storage in proxmox
* list vm config ```qm config 9000```
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

## Internal Network + NAT + DHCP Server
### Create internal Network
1. Create an internal network bridge and give the IP 192.168.5.1/24
### Setup NAT
1. Edit /etc/network/interfaces and add the following
```
post-up echo 1 > /proc/sys/net/ipv4/ip_forward
post-up iptables -t nat -A POSTROUTING -s '192.168.5.0/24' -o vmbr0 -j MASQUERADE
post-down iptables -t nat -D POSTROUTING -s '192.168.5.0/24' -o vmbr0 -j MASQUERADE
```
2. Run ```ifup vmbr1``` which runs the post-up commands.
3. Install iptables-persistent ```apt-get install iptables-persistent```
### Create DHCP Server Container
1. Update Container Template Database
Run the following command ```pveam update``` it should return update successful
2. Navigate to one of the storage which we want to use to store templates
3. Click on “Templates” button
4. Select the lxc container template we want to download and click on “Download” button to download it (e.g. TurnKey WordPress)
5. Once the download is finished, we click on “Create CT” button from Proxmox VE web gui
6. Configure
* Set a ssh-key and password which will be for root@
* Add the host to the bridge and give it an ip of 192.168.5.2/24
* DNS can be 8.8.8.8
### Setup DHCP Server
1. Login to DHCP server via ssh
2. Install dhcp server ```apt install isc-dhcp-server -y```
3. Edit /etc/dhcp/dhcpd.conf
3.2 Make the server authoratative, uncomment this line.
```
#authoritative;
```
3.3 Add to bottom of file
```
subnet 192.168.5.0 netmask 255.255.255.0 {
    option domain-name "domain.com";
    option domain-name-servers 8.8.8.8;
    range 192.168.5.10 192.168.5.254;
    option routers 192.168.5.2;
}

```
4. Restart dhcp server ```systemctl restart isc-dhcp-server```

