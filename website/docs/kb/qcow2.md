---
title: Qcow2
description: "Knowledge base article on Qcow2. Also available in the shell as `kb qcow2`."
---

<!-- BEGIN GENERATED: kb-qcow2 -->
* QCOW2
** Convert LVM to QCOW2
- qemu-img convert -O qcow2 /dev/vg0/srv04.lmt.ca-disk /root/srv04.lmt.ca-disk.qcow2
** Mount QCOW2
- guestmount -a path_to_image.qcow2 -i --ro /mount_point

---

*Generated from [`kb/qcow2.md`](https://github.com/jordantrizz/zshbop/blob/next-release/kb/qcow2.md) by
`npm run gen:kb`. The shell shows the same article with `kb qcow2`.*

<!-- END GENERATED: kb-qcow2 -->
