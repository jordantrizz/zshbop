# Logs and Analytics
## GoAccess
```
$ echo "deb https://deb.goaccess.io/ $(lsb_release -cs) main" | sudo tee -a /etc/apt/sources.list.d/goaccess.list
$ wget -O - https://deb.goaccess.io/gnugpg.key | sudo apt-key --keyring /etc/apt/trusted.gpg.d/goaccess.gpg add -
$ sudo apt-get update
$ sudo apt-get install goaccess
```

# Maintenance Page
## Nginx Configuration Option #1 - File Exists
```
   error_page 503 @maintenance;
   location @maintenance {
  	 rewrite ^(.*)$ /maintenance.html break;
   }

    location / {
    	if (-f $document_root/maintenance.html) {
    	    return 503;
	    }
    	... # the rest of your config goes here
    }
```
## Nginx Configuration Option #2 - File Exists + IP
```
    # -- Maintenance page
    if (-f $document_root/maintenance.html) {
        set $maintenance on;
    }

    if ($remote_addr ~ (127.0.0.1|76.70.117.218)) {
      set $maintenance off;
    }

    if ($uri ~ ^/maintenance.html$ ) {
      set $maintenance off;
    }

    if ($maintenance = on) {
      return 503;
    }

    error_page 503 @maintenance;
    location @maintenance {
        rewrite ^(.*)$ /maintenance.html break;
    }
```
## HTML Page
```
<html>
<head>
<meta http-equiv="refresh" content="5; URL=https://url.com/" />
</head>
<body>
This site is under maintenance, please check back soon!
</body>
<html>
```

# Nginx real_ip
```
set_real_ip_from  192.168.1.0/24;
set_real_ip_from  192.168.2.1;
set_real_ip_from  2001:0db8::/32;
real_ip_header    X-Forwarded-For;
real_ip_recursive on;
```
## Cloudflare
```
set_real_ip_from 173.245.48.0/20;
set_real_ip_from 103.21.244.0/22;
set_real_ip_from 103.22.200.0/22;
set_real_ip_from 103.31.4.0/22;
set_real_ip_from 141.101.64.0/18;
set_real_ip_from 108.162.192.0/18;
set_real_ip_from 190.93.240.0/20;
set_real_ip_from 188.114.96.0/20;
set_real_ip_from 197.234.240.0/22;
set_real_ip_from 198.41.128.0/17;
set_real_ip_from 162.158.0.0/15;
set_real_ip_from 104.16.0.0/12;
set_real_ip_from 172.64.0.0/13;
set_real_ip_from 131.0.72.0/22;
set_real_ip_from 104.16.0.0/13;
set_real_ip_from 104.24.0.0/14;
set_real_ip_from 2400:cb00::/32;
set_real_ip_from 2606:4700::/32;
set_real_ip_from 2803:f800::/32;
set_real_ip_from 2405:b500::/32;
set_real_ip_from 2405:8100::/32;
set_real_ip_from 2a06:98c0::/29;
set_real_ip_from 2c0f:f248::/32;
```

# Secure Nginx PHP-FPM
1. Create User
```
useradd site
```
2. Add www-data group (Nginx user) to site user
```
 usermod -a -G site www-data
```
3. Setup PHP-FPM
```
listen = /var/run/php-fpm74/site.sock
listen.owner = www-data
listen.group = www-data
listen.mode = 0666
user = site
group = site
```
4. Change /home and /home/site permissions
```
chmod 701 /home
chmod 750 /home/site
```