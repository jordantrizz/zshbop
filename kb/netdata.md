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

# Issues

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