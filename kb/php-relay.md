# Install Notes
* skill -9 lsphp if module doesnt show up for LSWS
* Install php-relay for CLI version and FPM version as they might differ.

# Install on Litespeed/Openlitespeed
* Following Ubuntu packages install.
* ```cp /usr/lib/php/20190902/relay.so /usr/local/lsws/lsphp74/lib/php/20190902```
* joe /usr/local/lsws/lsphp74/etc/php/7.4/mods-available
```
; The path to the extension binary.
; Relative paths will look in `php-config --extension-dir`.
;
extension = relay.so

; Relay license key (via https://relay.so).
; Without a license key Relay will throttle to 16MB memory one hour after startup.
;
; relay.key =

; The environment Relay is running in.
; Supported values: `production`, `staging`, `testing`, `development`
;
; relay.environment = development

; How much memory Relay allocates on startup. This value can either be a
; number like 134217728 or a unit (e.g. 128M) like memory_limit.
; See: https://php.net/manual/faq.using.php#faq.using.shorthandbytes
;
; Relay will allocate at least 16M for overhead structures.
; Set to `0` to disable in-memory caching and use as client only.
;
; relay.maxmemory = 32M

; At what percentage of used memory should Relay start evicting keys.
;
; relay.maxmemory_pct = 95

; How Relay evicts keys. This has been designed to mirror Redis’
; options and we currently support `noeviction`, `lru`, and `random`.
; The default `noeviction` policy will proxy all uncached commands
; to Redis, once the in-memory cache is full.
;
; relay.eviction_policy = noeviction

; How many keys should we scan each time we process evictions.
;
; relay.eviction_sample_keys = 128

; Default to using a persistent connection when calling `connect()`.
;
; relay.default_pconnect = 1

; The number of databases Relay will create per in-memory cache.
; This setting should match the `databases` setting in your `redis.conf`.
;
; relay.databases = 16

; The maximum number of PHP workers that will have their own in-memory cache.
; While each PHP worker will have its own connection to Redis, not all
; workers need their own in-memory cache and can be read-only workers.
;
; This setting is per connection endpoint (distinct Redis connections),
; e.g. connecting to two separate instances will double the workers.
;
; relay.max_endpoint_dbs = 32

; The number of epoch readers allocated on startup.
;
; relay.initial_readers = 128

; How often (in microseconds) Relay should proactively check the
; connection for invalidation messages from Redis.
;
; relay.invalidation_poll_freq = 5

; Whether Relay should log debug information.
; Supported levels: `debug`, `verbose`, `notice`, `error`, `off`
;
; relay.loglevel = off

; The path to the file in which information should be logged, if logging is enabled.
;
; relay.logfile = /tmp/relay.log
```