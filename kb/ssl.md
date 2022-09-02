# Common Commands
## Generating SSL Certificate
```openssl req -newkey rsa:2048 -nodes -keyout PRIVATEKEY.key -out MYCSR.csr```

## Check CSR
```openssl req -text -noout -verify -in CSR.csr```

# Testing SSL Certificates
```curl https://roadmap.gridpane.com/f/changelog/```