---
title: Disk
description: "resize2fs /dev/mapper/ubuntu--image--vg-root"
---

<!-- BEGIN GENERATED: kb-disk -->
* Ubuntu apt-get install -y cloud-guest-utils
* RedHat yum install -y cloud-utils-growpart
* Command: growpart /dev/vda 1

## LVM Tools
* pvs
* vgs
* lvs

## Grow LVM
### Growing a Pyhsical Volume
* pvresize /dev/sda
### Growing Logical Volume
* lvextend -l +100%FREE /dev/ubuntu-image-vg/root
### Growing EXT4 Partition
resize2fs /dev/mapper/ubuntu--image--vg-root


---

*Generated from [`kb/disk.md`](https://github.com/jordantrizz/zshbop/blob/next-release/kb/disk.md) by
`npm run gen:kb`. The shell shows the same article with `kb disk`.*

<!-- END GENERATED: kb-disk -->
