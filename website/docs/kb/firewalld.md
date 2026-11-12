---
title: Firewalld
description: "Always make sure to run firewall-cmd --reload after adding a rule."
---

<!-- BEGIN GENERATED: kb-firewalld -->
Always make sure to run ```firewall-cmd --reload``` after adding a rule.
## Common Rules
```
firewall-cmd --permanent --add-rich-rule="rule family='ipv4' source address='192.168.1.1' port port='7080' protocol='tcp' accept" --zone=public
firewall-cmd --reload
```

---

*Generated from [`kb/firewalld.md`](https://github.com/jordantrizz/zshbop/blob/next-release/kb/firewalld.md) by
`npm run gen:kb`. The shell shows the same article with `kb firewalld`.*

<!-- END GENERATED: kb-firewalld -->
