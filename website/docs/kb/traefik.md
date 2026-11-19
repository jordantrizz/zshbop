---
title: Traefik
description: "Knowledge base article on Traefik. Also available in the shell as `kb traefik`."
---

<!-- BEGIN GENERATED: kb-traefik -->
### Config
```
- "traefik.http.middlewares.instancename-secure.basicauth.users=username:encodedpassword"
```

## Password
```
echo $(htpasswd -nB user) | sed -e s/\\$/\\$\\$/g
```

---

*Generated from [`kb/traefik.md`](https://github.com/jordantrizz/zshbop/blob/next-release/kb/traefik.md) by
`npm run gen:kb`. The shell shows the same article with `kb traefik`.*

<!-- END GENERATED: kb-traefik -->
