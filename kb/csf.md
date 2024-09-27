# Commands
* csf -ra - Restart CSF/LFD. 

# Testing LFD Email Alerts
* Set /etc/alias root to forward to a file
```
root: /root/root-emails
```
* Run newaliases, no need to restart postfix.
```
newaliases
```
* tail the file
```
tail -f /root/root-emails
```
* Run a test command that will trigger an LFD alert. For instance process tracking.
```
csf --lfd restart
```