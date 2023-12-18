# Upgrading CyberPanel
* See https://community.cyberpanel.net/t/02-upgrading-cyberpanel/81
```
sh <(curl https://raw.githubusercontent.com/usmannasir/cyberpanel/stable/preUpgrade.sh || wget -O - https://raw.githubusercontent.com/usmannasir/cyberpanel/stable/preUpgrade.sh)
```

# Logs
## Main Error log
* /home/cyberpanel/error-logs.txt
* /home/cyberpanel/stderr.log

## LCSP Logs
* /usr/local/lscp/cyberpanel/logs/error.log
* /usr/local/lscp/cyberpanel/logs/access.log
* /usr/local/lscp/cyberpanel/logs/stderr.log

## SSL Renewal Logs
* /root/.acme
* /root/.acme.sh/acme.sh.log

# Tasks
## Reset Admin Password
* Login via ssh as root
*```adminPass newpassword```

## Password Protection
1. Setup webadmin console if you haven't already: https://forums.cyberpanel.net/discussion/87/tutorial-how-to-setup-and-login-to-openlitespeed-webadmin-console
2. Go to Virtual Hosts->Example->Security
3. In a new tab, go to Virtual Hosts->YOUR DOMAIN->Security
4. Add a new entry for your domain
5. Copy the Example for each field but tweak them to fit your domain
6. Go to Virtual Hosts->Example->Context-> /protected/
7. In a new tab, go to Virtual Hosts->YOUR DOMAIN->Context-> /protected/
8. Copy the Example for each field but tweak them to fit your domain
9. In your VPS, go to /usr/local/lsws/conf/vhosts/YOUR DOMAIN
10. Type "nano htpasswd"
11. Go to https://www.askapache.com/online-tools/htpasswd-generator/, fill out the form and select "crypt" for Encryption Algorithm
12. Enter the given user:hash into the htpasswd file then save and close
13. Set permissions to the file by typing "chmod +rwx htpasswd"
14. Done

## Change PHP Settings per Site
* See openlitespeed KB

## Setup Cloudflare Real Visitor IP
* https://openlitespeed.org/kb/show-real-visitor-ip-instead-of-cloudflare-ips/

## Setting up SSL for Admin URL
* https://blog.cyberpanel.net/2018/12/25/how-to-remove-port-8090-from-cyberpanel/

## Regenerate OLS Config
?

## Enable Email Debug Log
```
FYI- Per @usmannasir comment in my feature request (here: #1045 (comment)) we are able to turn on emailDebug to receive notifications about self-signed SSL certs. All you have to do is run the command: touch /usr/local/CyberCP/emailDebug which creates an empty file at that path, and tells CyberPanel to generate those logs via email.
```

## SSL Not Renewing - New Template
* https://github.com/usmannasir/cyberpanel/issues/1044