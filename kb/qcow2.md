* QCOW2
** Convert LVM to QCOW2
- qemu-img convert -O qcow2 /dev/vg0/srv04.lmt.ca-disk /root/srv04.lmt.ca-disk.qcow2
** Mount QCOW2
- guestmount -a path_to_image.qcow2 -i --ro /mount_point
