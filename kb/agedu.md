# Agedu Install
```apt-get install agedu```
# Common Commands
## Index a location
```agedu -s /```
## Generate report
* -H is the root of the report
* -d is the depth

```agedu -H / -d```

# Exposing Agedu
## Nginx configuration
* Create new Nginx configuration
```joe /etc/nginx/sites-available/agedu```
* Enter in the following.
```
## For Agedu Daemon
server {
    listen    80;
    server_name subdomian.com;
    location / {
        proxy_pass  http://127.0.0.1:8081;
        proxy_connect_timeout       5;
        proxy_send_timeout          5;
        proxy_read_timeout          5;
        send_timeout                5;
    }
}
```
* Synmlink the new configuration to enable
```ln -s /etc/nginx/sites-available/agedu /etc/nginx/sites-enabled/agedu```
* Check nginx config and reload
```nginx -t```
```systemctl nginx reload```
* Initiate a scan
```agedu -s /root/agedu.dat -s /home```
* Run webserver, place password in /root/agedu.pass in format 'user:pass'
```agedu --files -f /root/agedu.dat -w --address 127.0.0.1:8081 --auth basic --auth-file /root/agedu.pass```



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
