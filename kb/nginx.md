# Logs and Analytics
## GoAccess
'''
$ echo "deb https://deb.goaccess.io/ $(lsb_release -cs) main" | sudo tee -a /etc/apt/sources.list.d/goaccess.list
$ wget -O - https://deb.goaccess.io/gnugpg.key | sudo apt-key --keyring /etc/apt/trusted.gpg.d/goaccess.gpg add -
$ sudo apt-get update
$ sudo apt-get install goaccess
'''

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

