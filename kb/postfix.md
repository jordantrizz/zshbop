# Common Commands
* mailq - print a list of all queued mail
* postcat -vq [message-id] - print a particular message, by ID (you can see the ID along in mailq's output)
* postqueue -f - process the queued mail immediately
* postsuper -d ALL - delete ALL queued mail (use with caution—but handy if you have a mail send going awry!)

# Common Issues
## Sending Fails due to IPv6 DNS
Update the following line to use IPv4 only.
```
inet_protocols = ipv4
```
