# Setup Proxmox VM Guest
* https://support.us.ovhcloud.com/hc/en-us/articles/360002394324-How-to-Connect-a-VM-to-the-Internet-Using-Proxmox-VE

# Create Mac Address for IP
1. Login to OVH Control Panel
2. Clicking Networking->Public IP's
3. Expand the additional IP network range.
4. Click on the three dots to the right and select "Add Virtual Mac"
5. Either create a new or assign to existing.

If you have bare-metal and running virtualization like proxmox. You need to using the virtual machines mac address and select "ovh".