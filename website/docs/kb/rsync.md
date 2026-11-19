---
title: Rsync
description: "Knowledge base article on Rsync. Also available in the shell as `kb rsync`."
---

<!-- BEGIN GENERATED: kb-rsync -->
* rsync -avzh /root/rpmpkgs /tmp/backups/
* rsync -avz rpmpkgs/ root@192.168.0.101:/home/
## Advanced Examples
### rsync + time to logfile
```
#!/bin/bash
DATE=`date +"%Y-%m-%d %T"`
echo "Started $DATE" >> sync.log
(time rsync -avzh --progress /share/storage/* root@127.0.0.1:/mnt/storage.) >> sync.log 2>&1
echo "Stopped $DATE" >> sync.log
```

### rsync + time + logfile + lock file + cron
```
#!/bin/bash
#
# Add to qnap cron
# echo "0 */12 * * * /share/storage/sync.sh:" >> /etc/config/crontab
#
HOME="/share/storage"

if [ -e "$HOME/rsyncjob.lock" ]
then
  echo "Rsync job already running...exiting"
  exit
fi

touch "$HOME/rsyncjob.lock"

DATE=`date +"%Y-%m-%d %T"`
echo "Started $DATE" >> sync.log
(time rsync -avzh --progress /share/storage/* root@127.0.0.1:/mnt/audio-files-storage/.) >> sync.log 2>&1
echo "Stopped $DATE" >> sync.log

trap 'rm "$HOME/rsyncjob.lock"' EXIT
```

---

*Generated from [`kb/rsync.md`](https://github.com/jordantrizz/zshbop/blob/next-release/kb/rsync.md) by
`npm run gen:kb`. The shell shows the same article with `kb rsync`.*

<!-- END GENERATED: kb-rsync -->
