# --
# template commands
#
# Example help: help_template[test]='Generate phpinfo() file'
#
# --
_debug " -- Loading ${(%):-%N}"

# What help file is this?
help_files[redis_description]="Redis commands"
help_files[redis]="Redis Commands"

# - Init help array
typeset -gA help_redis

_debug " -- Loading ${(%):-%N}"

# ---------------
# -- redis-memory
# ---------------
help_redis[redis-memory]="Grab redis maxmemory and statistics"
redis-memory () {
    _loading "Running redis-cli info memory"
    redis-cli info memory
    _loading "Retrieving 'evicted_keys' from redis-cli info"
    redis-cli info | grep evict
	_loading "Checking for /etc/redis/redis.conf"
	if [[ -f /etc/redis/redis.conf ]]; then
		_success "Found /etc/redis/redis.conf"
		_notice "Redis 'maxmemory' setting"
		egrep -e '^maxmemory |^maxmemory-policy ' /etc/redis/redis.conf
		_notice "Redis save setting - # save <seconds> <changes>"
		grep '^save ' /etc/redis/redis.conf
		_notice "Redis rdb settings"
		grep 'rdb' /etc/redis/redis.conf | grep -v "^#"
		_notice "Redis append-only setting"
		grep -e '^appendonly ' /etc/redis/redis.conf		
	else
		_error "No /etc/redis/redis.conf file"
	fi
}

# -------------------
# -- redis-clearstats
# -------------------
help_redis[redis-clearstats]="Clear redis stats"
redis-clearstats () {
	_notice "Clearing redis stats"
	redis-cli config resetstat
}