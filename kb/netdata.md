# Install/Uninstall/Update
## Install netdata
* ```bash <(curl -Ss https://my-netdata.io/kickstart.sh)```

## Uninstall netdata
* ```/usr/libexec/netdata/netdata-uninstaller.sh --yes```

## Update netdata
* ```wget -O /tmp/netdata-kickstart.sh https://my-netdata.io/kickstart.sh && sh /tmp/netdata-kickstart.sh --dry-run```

# Install Notes
## Specify different temporary directory, instead of default /tmp
* ```env TMPDIR=/root/tmp bash <(curl -Ss https://my-netdata.io/kickstart.sh)```

# Configuration
## Editing Confg
* ```./edit-config go.d/web_log.conf```

# Alarms

## Disable Email (Doesn't Work for Cloud)
1. Edit health_alarm_notify.conf
```/etc/netdata/edit-config health_alarm_notify.conf```
2. Change SEND_EMAIL="YES" to "NO"

## Disable Health Checks Completely (Works for Cloud)
1. Edit netdata.conf and add
```
[health]
enabled=no
```

## Silence Specific Alarms
1. Locate the Alarm
```grep 'web_log_' /usr/lib/netdata -R```
2. Edit the alarm configuration
```./edit-config health.d/web_log.conf```
3. Set the to: line to silent
```to: slient```

## 1m_tcp_syn_queue_cookies
```
SYN queue
The SYN queue tracks TCP handshakes until connections are fully established.
It overflows when too many incoming TCP connection requests hang in the
half-open state and the server is not configured to fall back to SYN cookies.
Overflows are usually caused by SYN flood DoS attacks (i.e. someone sends
lots of SYN packets and never completes the handshakes).
```
* Edit /etc/sysctl.conf and updated net.ipv4.tcp_syncookies to equal 1 and run sysctl -p

## web_log_1m_redirects
* Details: ratio of redirection HTTP requests over the last minute (3xx except 304)
* This can occur and be normal, so suggest disabling this alarm.
```
./edit-config health.d/web_log.conf
```