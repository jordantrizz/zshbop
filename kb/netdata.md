# Install/Uninstall/Update
## Install netdata
* ```bash <(curl -Ss https://my-netdata.io/kickstart.sh)```

## Uninstall netdata
* ```/usr/libexec/netdata/netdata-uninstaller.sh --yes```

## Update netdata
* ```wget -O /tmp/netdata-kickstart.sh https://my-netdata.io/kickstart.sh && sh /tmp/netdata-kickstart.sh --dry-run```

# Common Commands
* Reload health ```netdatacli reload-health```

# Install Notes
## Specify different temporary directory, instead of default /tmp
* ```env TMPDIR=/root/tmp bash <(curl -Ss https://my-netdata.io/kickstart.sh)```

# Configuration
## Editing Confg
Copies default config to override directory.
* ```./edit-config go.d/web_log.conf```

# Cheatsheet
* https://learn.netdata.cloud/docs/getting-started/manage-and-configure/

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

## Agent Slack Notifications
See https://learn.netdata.cloud/docs/alerts-and-notifications/notifications/agent-alert-notifications/slack
### 1 - Open health_alarm_notify.conf
```
cd /etc/netdata
./edit-config health_alarm_notify.conf
```
### 2 - Search and Replace
* Set SEND_SLACK to YES.
* Set SLACK_WEBHOOK_URL to your Slack app's webhook URL.
* Set DEFAULT_RECIPIENT_SLACK to the Slack channel your Slack app is set to send messages to.

### 3 - Example
```
SEND_SLACK="YES"
SLACK_WEBHOOK_URL="https://hooks.slack.com/services/XXXXXXXX/XXXXXXXX/XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX" 
DEFAULT_RECIPIENT_SLACK="#alarms"
```

## Testing Alerts
```
sudo su -s /bin/bash netdata
export NETDATA_ALARM_NOTIFY_DEBUG=1
/usr/libexec/netdata/plugins.d/alarm-notify.sh test
```

## Silence Specific Alarms
1. Locate the Alarm
```grep 'web_log_' /usr/lib/netdata -R```
2. Edit the alarm configuration
```./edit-config health.d/web_log.conf```
3. Set the to: line to silent
```to: slient```

## Silent Web Logs
Theres are common alerts you'll get that might not be of concern

* web_log_1m_unmatched
* web_log_1m_redirects
* web_log_1m_bad_requests
* web_log_1m_successful

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

# Common Alarms to Silence
```
web_log_1m_unmatched
web_log_1m_redirects
```
# Common Tasks
## Change Hostname
1. Edit netdata.conf (usually found in /etc/netdata )
2. Add hostname="ENTER_NEW_NODE_NAME" under [global]
3. Restart netdata with sudo systemctl restart netdata or the relevant command for your system.

## Netdata on Synology Startup Script
1. Add this file as /etc/rc.netdata. Make it executable with chmod 0755 /etc/rc.netdata.
2. Add or edit /etc/rc.local and add a line calling /etc/rc.netdata to have it start on boot:
```
[ -x /etc/rc.netdata ] && /etc/rc.netdata start
```
3. Make sure /etc/rc.netdata is executable: chmod 0755 /etc/rc.netdata.