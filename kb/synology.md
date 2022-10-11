# Building Syno Community Packages
* https://github.com/SynoCommunity/spksrc/wiki/Compile-and-build-ruleshttps://github.com/SynoCommunity/spksrc/wiki/Compile-and-build-rules
* https://www.niallobrien.ie/content/compile-synology-packages-using-ubuntugit/
## Specifying Architecture
* make arch-apollolake-6.1
# Updating Nginx Web Server Moustache Template
* NGINX Config: /usr/syno/share/nginx/
```
cd /usr/syno/share/nginx/
cp WWWService.mustache WWWService.mustache.bak
joe WWWService.mustache
```
## Redirect all non-http traffic to https
1. Backup /usr/syno/share/nginx/WWWService.mustache
```
cp /usr/syno/share/nginx/WWWService.mustache /usr/syno/share/nginx/WWWService.mustache.bak
```
2. Edit /usr/syno/share/nginx/WWWService.mustache and modify the listen 80 to the following
```
server {
    listen 80 default_server{{#reuseport}} reuseport{{/reuseport}};
    listen [::]:80 default_server{{#reuseport}} reuseport{{/reuseport}};

    gzip on;
    
    location /.well-known/acme-challenge/ {
    # put your configuration here, if needed
    }

    server_name _;
    return 301 https://$host$request_uri;
}
```
3. Restart Nginx
```
synoservicecfg --restart nginx
```

# Restarting Services
```
synoservicecfg --list
synoservicecfg --restart service
```