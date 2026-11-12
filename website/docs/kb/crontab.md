---
title: Crontab
description: "Knowledge base article on Crontab. Also available in the shell as `kb crontab`."
---

<!-- BEGIN GENERATED: kb-crontab -->

## Syntax

```
*	any value
,	value list separator
-	range of values
/	step values
@yearly	(non-standard)
@annually	(non-standard)
@monthly	(non-standard)
@weekly	(non-standard)
@daily	(non-standard)
@hourly	(non-standard)
@reboot	(non-standard)
```

## Examples
### Every 15 minutes.
```
15     *     *     *     *         rm /home/someuser/tmp/*
```
## Tools
* https://crontab.guru/

---

*Generated from [`kb/crontab.md`](https://github.com/jordantrizz/zshbop/blob/next-release/kb/crontab.md) by
`npm run gen:kb`. The shell shows the same article with `kb crontab`.*

<!-- END GENERATED: kb-crontab -->
