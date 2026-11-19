---
title: Tcpdump
description: "Knowledge base article on Tcpdump. Also available in the shell as `kb tcpdump`."
---

<!-- BEGIN GENERATED: kb-tcpdump -->
### Finding Malware
```
tcpdump -n src host 192.168.0.1 and "tcp[tcpflags] & (tcp-syn) != 0" and "tcp[tcpflags] & (tcp-ack) == 0"
```
### Using and
```
tcpdump -n src 192.168.1.1 and dst port 21
```

---

*Generated from [`kb/tcpdump.md`](https://github.com/jordantrizz/zshbop/blob/next-release/kb/tcpdump.md) by
`npm run gen:kb`. The shell shows the same article with `kb tcpdump`.*

<!-- END GENERATED: kb-tcpdump -->
