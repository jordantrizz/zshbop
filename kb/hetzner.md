# Installing Proxmox on Hetzner
1. Reboot into rescue.
2. Run installimage
3. Select Proxmox

# Common Issues
## Why can I not send any mails from my server?
Unfortunately, email spammers and scammers like to use cloud hosting providers. And we at Hetzner naturally want to prevent this. That's why we block ports 25 and 465 by default on all cloud servers. This is a very common practice in the cloud hosting industry because it prevents abuse. We want to build trust with our new customers before we unblock these mail ports. Once you have been with us for a month and paid your first invoice, you can create a limit request to unblock these ports for a valid use case. In your request, you can tell us details about your use case. We make decisions on a case-by-case basis.

As an alternative, you can also use port 587 to send emails via external mail delivery services. Port 587 is not blocked and can be used without sending a limit request.

https://docs.hetzner.com/cloud/servers/faq/#why-can-i-not-send-any-mails-from-my-server

## Virtual Mac Addresses
You can't add virtual mac addresses to subnets, only individual IP's.

## Proxmox and Routed IP's Setup
See https://community.hetzner.com/tutorials/install-and-configure-proxmox_ve
### 1. Setup IP Forwarding
```
sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/' /etc/sysctl.conf
sed -i 's/#net.ipv6.conf.all.forwarding=1/net.ipv6.conf.all.forwarding=1/' /etc/sysctl.conf
sysctl -p
```

### 2. Confirm
```
sysctl net.ipv4.ip_forward
sysctl net.ipv6.conf.all.forwarding
```

### 3. Update Networking -  /etc/network/interfaces
* Setup the main networking interface to hold the main IP with the gateway configuration.
* Also setup vmbr0 with the main IP and gateway configuration.
```
auto enp0s31f6
iface enp0s31f6 inet static
        address 198.51.100.10/32    #Main IP
        gateway 198.51.100.1        #Gateway

# Additional Subnet 203.0.113.0/24
auto vmbr1
iface vmbr1 inet static
        address 203.0.113.1/24 # Set one usable IP from the subnet range
        bridge-ports none
        bridge-stp off
        bridge-fd 0
```

### 4. Setup Host
```
# /etc/network/interfaces

auto lo
iface lo inet loopback


auto ens18
iface ens18 inet static
  address 203.0.113.10/24      # Subnet IP
  gateway 203.0.113.1          # Gateway is the IP of the bridge (vmbr1) 
```