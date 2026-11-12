---
title: SSL
description: "Knowledge base article on SSL. Also available in the shell as `kb ssl`."
---

<!-- BEGIN GENERATED: kb-ssl -->
### Generating SSL Certificate
```openssl req -newkey rsa:2048 -nodes -keyout PRIVATEKEY.key -out MYCSR.csr```

### Check CSR
```openssl req -text -noout -verify -in CSR.csr```

## Testing SSL Certificates
```curl https://roadmap.gridpane.com/f/changelog/```

---

*Generated from [`kb/ssl.md`](https://github.com/jordantrizz/zshbop/blob/next-release/kb/ssl.md) by
`npm run gen:kb`. The shell shows the same article with `kb ssl`.*

<!-- END GENERATED: kb-ssl -->
