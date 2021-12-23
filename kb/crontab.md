# Crontab

# Syntax

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

# Examples
## Every 15 minutes.
```
15     *     *     *     *         rm /home/someuser/tmp/*
```
# Tools
* https://crontab.guru/