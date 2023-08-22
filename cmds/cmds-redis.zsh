# --
# template commands
#
# Example help: help_template[test]='Generate phpinfo() file'
#
# --
_debug " -- Loading ${(%):-%N}"

# What help file is this?
help_files[redis]="Redis Commands"

# - Init help array
typeset -gA help_redis

_debug " -- Loading ${(%):-%N}"

# ---------------
# -- redis-memory
# ---------------
help_redis[redis-info]="Grab redis maxmemory, configuration and statistics"
redis-info () {
    REDIS_INFO=$(redis-cli info)
	REDIS_MEMORY=$(redis-cli info memory)
	REDIS_CLI_MAXMEMORY=$(echo "$REDIS_MEMORY" | grep -e '^maxmemory:' | awk -F: '{print $2}')
	REDIS_CLI_MAXMEMORY_HUMAN=$(echo "$REDIS_MEMORY" | grep -e '^maxmemory_human:' | awk -F: '{print $2}')
	REDIS_CLI_MAXMEMORY_POLICY=$(echo "$REDIS_MEMORY" | grep -e '^maxmemory_policy:' | awk -F: '{print $2}')
	REDIS_CLI_EVICTED_KEYS=$(echo "$REDIS_INFO" | grep -e '^evicted_keys:' | awk -F: '{print $2}')
	_loading "Running redis-cli info memory"
	echo "$REDIS_MEMORY"
    echo ""
    
    _loading "Retrieving 'evicted_keys' from redis-cli info"	
    echo "evicted_keys: $REDIS_CLI_EVICTED_KEYS"
    echo ""

	_loading "Checking for /etc/redis/redis.conf"
	if [[ -f /etc/redis/redis.conf ]]; then
		# -- Get redis config settings
		_success "Found /etc/redis/redis.conf"
		_noticebg "Redis 'maxmemory' setting"
		REDIS_CONFIG_MAXMEMORY=$(grep -e '^maxmemory ' /etc/redis/redis.conf | awk '{print $2}')
		REDIS_CONFIG_MAXMEMORY_POLICY=$(grep '^maxmemory-policy ' /etc/redis/redis.conf | awk '{print $2}')
		echo "conf-maxmemory: $REDIS_CONFIG_MAXMEMORY"
		echo "conf-maxmemory-policy: $REDIS_CONFIG_MAXMEMORY_POLICY"
		echo ""

		_noticebg "Redis 'maxmemory' redis-cli info"
		echo "cli-maxmemory: $REDIS_CLI_MAXMEMORY"
		echo "cli-maxmemory-policy: $REDIS_CLI_MAXMEMORY_POLICY"
		echo ""

        # -- Error if maxmemory from redis-cli info doesn't match redis.conf, convert REDIS_MAX_MEMORY_HUMAN to bytes
        REDIS_CONFIG_MAXMEMORY=${REDIS_CONFIG_MAXMEMORY%"mb"}
        REDIS_CLI_MAXMEMORY=${REDIS_CLI_MAXMEMORY//$'\r'/}
        REDIS_CONFIG_MM_MB2BYTES=$(( $REDIS_CONFIG_MAXMEMORY * 1024 * 1024))
        _noticebg "Compairing Config: $REDIS_CONFIG_MM_MB2BYTES to Proc: $REDIS_CLI_MAXMEMORY"
        if (( $REDIS_CONFIG_MM_MB2BYTES < $REDIS_CLI_MAXMEMORY)); then
            _error "Redis Config maxmemory = $REDIS_MB2BYTES bytes and is smaller than Redis Running maxmemory = $REDIS_CLI_MAXMEMORY bytes."
        else
            _success "Redis Config maxmemory = $REDIS_MB2BYTES bytes is equal to or larger than Redis Running maxmemory = $REDIS_CLI_MAXMEMORY bytes."
        fi
		echo ""

		_noticebg "Redis save setting - # save <seconds> <changes>"
		grep '^save ' /etc/redis/redis.conf
		echo ""

		_noticebg "Redis rdb settings"
		grep 'rdb' /etc/redis/redis.conf | grep -v "^#"
		echo ""
		
		_noticebg "Redis append-only setting"
		grep -e '^appendonly ' /etc/redis/redis.conf
		echo ""
		
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