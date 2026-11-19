---
title: CSF
description: "Knowledge base article on CSF. Also available in the shell as `kb csf`."
---

<!-- BEGIN GENERATED: kb-csf -->
* csf -ra - Restart CSF/LFD. 

## Testing LFD Email Alerts
* Set /etc/alias root to forward to a file
```
root: /root/root-emails
```
* Run newaliases, no need to restart postfix.
```
newaliases
```
* tail the file
```
tail -f /root/root-emails
```
* Run a test command that will trigger an LFD alert. For instance process tracking.
```
csf --lfd restart
```

---

*Generated from [`kb/csf.md`](https://github.com/jordantrizz/zshbop/blob/next-release/kb/csf.md) by
`npm run gen:kb`. The shell shows the same article with `kb csf`.*

<!-- END GENERATED: kb-csf -->
