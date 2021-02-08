# Setting up SSL for Admin URL
* https://blog.cyberpanel.net/2018/12/25/how-to-remove-port-8090-from-cyberpanel/

# Password Protection
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