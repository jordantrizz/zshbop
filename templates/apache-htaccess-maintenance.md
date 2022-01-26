# Source
Source: https://www.shellhacks.com/redirect-site-maintenance-page-apache-htaccess/

Provides a maintenance page for all users execpt specific ip addresses.

# Code
```
RewriteEngine On
RewriteCond %{REMOTE_ADDR} !^123\.456\.789\.000
RewriteCond %{DOCUMENT_ROOT}/maintenance.html -f
RewriteCond %{DOCUMENT_ROOT}/maintenance.enable -f
RewriteCond %{SCRIPT_FILENAME} !maintenance.html
RewriteRule ^.*$ /maintenance.html [R=503,L]
ErrorDocument 503 /maintenance.html
Header Set Cache-Control "max-age=0, no-store"
```