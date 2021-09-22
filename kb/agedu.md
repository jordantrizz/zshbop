# Index a location
```agedu -s /```
# Generate report
* -H is the root of the report
* -d is the depth

```agedu -H / -d```

# Cronjob
```
#!/usr//bin/bash
NOW=$(date +"%m-%d-%Y")

echo "Start agedu scan $NOW" >> /home/dev/public_html/stats/cronjob.log
/usr/bin/agedu --cross-fs -s / -f /home/dev/public_html/stats/agedu.dat  >> /home/dev/public_html/stats/cronjob.log
echo "Start agedu report $NOW" >> /home/dev/public_html/stats/cronjob.log
/usr/bin/agedu -H / -d 4 -o /home/dev/public_html/stats >> /home/dev/public_html/stats/cronjob.log
echo "End agedu $NOW" >> /home/dev/public_html/stats/cronjob.log
```
