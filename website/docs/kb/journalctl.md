---
title: Journalctl
description: "Knowledge base article on Journalctl. Also available in the shell as `kb journalctl`."
---

<!-- BEGIN GENERATED: kb-journalctl -->
```journalctl -p 3 -xb```

* -p 3 means priority err
* -x provides extra message information
* -b means since last boot
## Display all Messages for a specific service
```journalctl -u service-name```
## Display all Messages for a specific service since last boot
```journalctl -u service-name -b```

---

*Generated from [`kb/journalctl.md`](https://github.com/jordantrizz/zshbop/blob/next-release/kb/journalctl.md) by
`npm run gen:kb`. The shell shows the same article with `kb journalctl`.*

<!-- END GENERATED: kb-journalctl -->
