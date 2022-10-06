# Email
## Sending with postmark
*  joe /etc/postfix/main.cf
```
relayhost = [smtp.postmarkapp.com]:587
smtp_use_tls = yes
smtp_sasl_auth_enable = yes
smtp_sasl_security_options = noanonymous
smtp_sasl_password_maps = hash:/etc/postfix/sasl_passwd
smtp_tls_CAfile = /etc/ssl/certs/ca-certificates.crt
smtp_header_checks = pcre:/etc/postfix/smtp_header_checks
```
* joe /etc/postfix/sasl_passwd
```
[smtp.postmarkapp.com]:587    username:password
```
* postmap /etc/postfix/sasl_passwd
* systemctl restart postfix
## Filter Email and change root emails To:
* joe /etc/postfix/smtp_header_checks
```
/^From:.*/ REPLACE From: server@domain.com
/^To:.*root@server.domain.com$/ REPLACE To: alerts@domain.com
```
* postmap /etc/postfix/smtp_header_checks
* joe /etc/postfix/main.cf
```
smtp_header_checks = pcre:/etc/postfix/smtp_header_checks
``
* systemctl restart postfix