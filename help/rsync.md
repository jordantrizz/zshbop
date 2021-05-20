# Examples
* rsync -avzh /root/rpmpkgs /tmp/backups/
* rsync -avz rpmpkgs/ root@192.168.0.101:/home/
# Advanced Examples
## rsync + time to logfile
```
#!/bin/bash
DATE=`date +"%Y-%m-%d %T"`
echo "Started $DATE" >> sync.log
(time rsync -avzh --progress /share/storage/* root@127.0.0.1:/mnt/storage.) >> sync.log 2>&1
echo "Stopped $DATE" >> sync.log
```