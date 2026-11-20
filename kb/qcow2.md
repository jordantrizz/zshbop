* QCOW2
** Convert LVM to QCOW2
- qemu-img convert -O qcow2 /dev/vg0/srv01.example.com-disk /root/srv01.example.com-disk.qcow2
** Mount QCOW2
- guestmount -a path_to_image.qcow2 -i --ro /mount_point
