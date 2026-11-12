---
title: Redis
description: "1. redis-cli"
---

<!-- BEGIN GENERATED: kb-redis -->
```redis-cli info memory```

## Max Memory
```maxmemory```

## List All Keys
1. ```redis-cli```
2. ```KEYS *```

## Common Config
```
maxmemory <systemmemorybased>
maxmemory-policy allkeys-lru
```

## WordPress Redis Config
### Socket Connections
```
define('WP_REDIS_PATH','/var/run/redis/redis-server.sock');
define('WP_REDIS_SCHEME','unix');
```

---

*Generated from [`kb/redis.md`](https://github.com/jordantrizz/zshbop/blob/next-release/kb/redis.md) by
`npm run gen:kb`. The shell shows the same article with `kb redis`.*

<!-- END GENERATED: kb-redis -->
