# Grow Linux Partition
* Ubuntu apt-get install -y cloud-guest-utils
* RedHat yum install -y cloud-utils-growpart
* Command: growpart /dev/vda 1

# LVM Tools
* pvs
* vgs
* lvs

# Grow LVM
## Growing a Pyhsical Volume
* pvresize /dev/sda
## Growing Logical Volume
* lvextend -l +100%FREE /dev/ubuntu-image-vg/root
## Growing EXT4 Partition
resize2fs /dev/mapper/ubuntu--image--vg-root

