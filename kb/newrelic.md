# Openlightspeed Install
## OLS Agent Install
This will install newrelic agent into lsphp74, repeat for all versions needed.

```
echo 'deb http://apt.newrelic.com/debian/ newrelic non-free' | sudo tee /etc/apt/sources.list.d/newrelic.list
wget -O- https://download.newrelic.com/548C16BF.gpg | sudo apt-key add -
sudo apt-get update
sudo apt-get install newrelic-php5
export NR_INSTALL_PATH=/usr/local/lsws/lsphp74/bin
newrelic-install
```

## OLS Update Application Name
```
grep -inr "newrelic.appname =" /etc
grep -inr "newrelic.appname =" /usr/local/lsws/
```

## OLS Restart for Changes
```
systemctl restart lsws
killall lsphp
```

## OLS Configure Individual Websites
```
nano /var/www/site.url/htdocs/.user.ini
```
Modify
```
newrelic.appname = "{sitename};{servername}"
```


# Disable Browser Monitoring
```
newrelic.browser_monitoring.auto_instrument = false
```
