# Setup Proxmox VM Guest
* https://support.us.ovhcloud.com/hc/en-us/articles/360002394324-How-to-Connect-a-VM-to-the-Internet-Using-Proxmox-VE

# Create Mac Address for IP
1. Login to OVH Control Panel
2. Clicking Networking->Public IP's
3. Expand the additional IP network range.
4. Click on the three dots to the right and select "Add Virtual Mac"
5. Either create a new or assign to existing.
5.1 If you're attaching the IP to an existing server or virtual instance, use existing.
5.2 For new server or instances you will need to create a new one and then make sure your virtual instance has it's network interface overriden.

# OVH netplan + cloud-init
* https://www.reddit.com/r/Proxmox/comments/llz6ww/proxmox_template_with_custom_cloudinit_need_to/
1. You must first set the storage up to permit storing the 'snippets' type:
```
pvesm set local --content images,rootdir,vztmpl,backup,iso,snippets
```
2. Create a network.yaml within a new directory `/var/lib/vz/snippets/` that looks similar to:
```
network:
    version: 2
    ethernets:
        eth0:
            addresses:
            - 192.168.0.2/32
            gateway4: 192.168.0.254
            match:
                macaddress: 00:00:00:00:00:00
            nameservers:
                addresses:
                - 8.8.8.8
                - 1.1.1.1
                search:
                - lmthosting.com
            set-name: eth0
            routes:
            - to: 192.168.0.254/32
              via: 0.0.0.0
              scope: link
```

3. Clone a template, i.e. one made from one of the ubuntu cloud-init images:
```
qm clone 9000 123 --name cloudinit-test01
```
4. Configure the VM to use your custom Netplan V1 config:
```
qm set 124 --sshkey ~/.ssh/id_rsa.pub --cicustom network=local:snippets/network.yaml -citype nocloud
```