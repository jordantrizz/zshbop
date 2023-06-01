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
