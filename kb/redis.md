# Get Memory Information
```redis-cli info memory```

# Max Memory
```maxmemory```

# List All Keys
1. ```redis-cli```
2. ```KEYS *```

# Common Config
```
maxmemory <systemmemorybased>
maxmemory-policy allkeys-lru
```

# WordPress Redis Config
## Socket Connections
```
define('WP_REDIS_PATH','/var/run/redis/redis-server.sock');
define('WP_REDIS_SCHEME','unix');
```