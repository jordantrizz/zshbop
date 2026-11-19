---
title: Cpanel
description: "https://support.cpanel.net/hc/en-us/articles/4420396389399-How-do-I-list-all-domains-for-a-user-account-on-my-server"
---

<!-- BEGIN GENERATED: kb-cpanel -->
### Get Users to Domain Mapping
https://support.cpanel.net/hc/en-us/articles/4420396389399-How-do-I-list-all-domains-for-a-user-account-on-my-server
```
cat /etc/userdomains
```
### Get Domain to User Mapping API
```
uapi --output=jsonpretty --user=$user DomainInfo list_domains
```

---

*Generated from [`kb/cpanel.md`](https://github.com/jordantrizz/zshbop/blob/next-release/kb/cpanel.md) by
`npm run gen:kb`. The shell shows the same article with `kb cpanel`.*

<!-- END GENERATED: kb-cpanel -->
