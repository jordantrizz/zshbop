# Cheatsheet
## Finding Malware
```
tcpdump -n src host 192.168.0.1 and "tcp[tcpflags] & (tcp-syn) != 0" and "tcp[tcpflags] & (tcp-ack) == 0"
```
## Using and
```
tcpdump -n src 192.168.1.1 and dst port 21
```