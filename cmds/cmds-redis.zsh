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

# =================================================================================================
# redis-pass
# =================================================================================================
help_redis[redis-pass]="Get Redis password from config"
redis-pass () {
	if ! pgrep redis-server > /dev/null; then
		_error "Redis is not running"
		return 1
	fi

	# -- Check if redis needs auth
	REDIS_AUTH=$(grep -e '^requirepass ' /etc/redis/redis.conf | awk '{print $2}')
	if [[ -n $REDIS_AUTH ]]; then
		echo $REDIS_AUTH
		return 0
	else
		return 1
	fi
}


# =================================================================================================
# -- redis-info
# =================================================================================================
help_redis[redis-info]="Grab redis maxmemory, configuration and statistics"
redis-info () {
	# -- Usage
	function _redis_info_usage() {
		_notice "Usage: redis-info -f"
		_notice "Options:"
		_notice "  -f  Full output"
		_notice "Description: Grab redis maxmemory, configuration and statistics"
	}
	_loading "Collecting Redis Information"
	
	# -- Check if redis is running
	_loading2 "Checking if redis is running"
	if ! pgrep redis-server > /dev/null; then
		_error "Redis is not running"
		return
	fi

	# -- Check if redis needs auth
	_loading2 "Checking if redis needs auth"
	if [[ -n $(redis-pass) ]]; then
		REDIS_CMD="redis-cli -a $(redis-pass)"
	else
		REDIS_CMD="redis-cli"
	fi

	REDIS_INFO=$(eval ${REDIS_CMD} info 2> /dev/null)
	REDIS_MEMORY=$(eval ${REDIS_CMD} info memory 2> /dev/null)
	REDIS_CLI_MAXMEMORY=$(echo "$REDIS_MEMORY" | grep -e '^maxmemory:' | awk -F: '{print $2}')
	REDIS_CLI_MAXMEMORY_HUMAN=$(echo "$REDIS_MEMORY" | grep -e '^maxmemory_human:' | awk -F: '{print $2}')
	REDIS_CLI_MAXMEMORY_POLICY=$(echo "$REDIS_MEMORY" | grep -e '^maxmemory_policy:' | awk -F: '{print $2}')
	
	_loading "Collected information."
	if [[ $1 == "-f" ]]; then
		echo "$REDIS_MEMORY"
		return
	fi
	    
    _loading2 "Printing Redis Information"
	echo "=================="
    echo "version: $(echo "$REDIS_INFO" | grep -e '^redis_version:' | awk -F: '{print $2}')"
	echo "uptime_in_seconds: $(echo "$REDIS_INFO" | grep -e '^uptime_in_seconds:' | awk -F: '{print $2}')"
	echo "uptime_in_days: $(echo "$REDIS_INFO" | grep -e '^uptime_in_days:' | awk -F: '{print $2}')"
	echo "process_id: $(echo "$REDIS_INFO" | grep -e '^process_id:' | awk -F: '{print $2}')"
	echo "=================="
	echo "connected_clients: $(echo "$REDIS_INFO" | grep -e '^connected_clients:' | awk -F: '{print $2}')"
	echo "blocked_clients: $(echo "$REDIS_INFO" | grep -e '^blocked_clients:' | awk -F: '{print $2}')"
	echo "=================="
	echo "used_memory: $(echo "$REDIS_INFO" | grep -e '^used_memory:' | awk -F: '{print $2}')"
	echo "used_memory_human: $(echo "$REDIS_INFO" | grep -e '^used_memory_human:' | awk -F: '{print $2}')"
	echo "used_memory_rss: $(echo "$REDIS_INFO" | grep -e '^used_memory_rss:' | awk -F: '{print $2}')"
	echo "used_memory_peak: $(echo "$REDIS_INFO" | grep -e '^used_memory_peak:' | awk -F: '{print $2}')"
	echo "used_memory_peak_human: $(echo "$REDIS_INFO" | grep -e '^used_memory_peak_human:' | awk -F: '{print $2}')"
	echo "=================="
	echo "total_connections_received: $(echo "$REDIS_INFO" | grep -e '^total_connections_received:' | awk -F: '{print $2}')"
	echo "total_commands_processed: $(echo "$REDIS_INFO" | grep -e '^total_commands_processed:' | awk -F: '{print $2}')"
	echo "instantaneous_ops_per_sec: $(echo "$REDIS_INFO" | grep -e '^instantaneous_ops_per_sec:' | awk -F: '{print $2}')"
	echo "total_net_input_bytes: $(echo "$REDIS_INFO" | grep -e '^total_net_input_bytes:' | awk -F: '{print $2}')"
	echo "total_net_output_bytes: $(echo "$REDIS_INFO" | grep -e '^total_net_output_bytes:' | awk -F: '{print $2}')"
	echo "rejected_connections: $(echo "$REDIS_INFO" | grep -e '^rejected_connections:' | awk -F: '{print $2}')"
	echo "=================="
	echo "used_cpu_sys: $(echo "$REDIS_INFO" | grep -e '^used_cpu_sys:' | awk -F: '{print $2}')"
	echo "used_cpu_user: $(echo "$REDIS_INFO" | grep -e '^used_cpu_user:' | awk -F: '{print $2}')"
	echo "used_cpu_sys_children: $(echo "$REDIS_INFO" | grep -e '^used_cpu_sys_children:' | awk -F: '{print $2}')"
	echo "used_cpu_user_children: $(echo "$REDIS_INFO" | grep -e '^used_cpu_user_children:' | awk -F: '{print $2}')"
	echo "=================="
	echo "mem_fragmentation_ratio: $(echo "$REDIS_INFO" | grep -e '^mem_fragmentation_ratio:' | awk -F: '{print $2}')"
	echo "maxmemory: $REDIS_CLI_MAXMEMORY"
	echo "evicted_keys: $(echo "$REDIS_INFO" | grep -e '^evicted_keys:' | awk -F: '{print $2}')"
	
	
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
        if [[ $REDIS_CONFIG_MAXMEMORY == "" ]]; then
			_error "Redis Config maxmemory is not set in /etc/redis/redis.conf can't compare"
		else
			_noticebg "Compairing Config: $REDIS_CONFIG_MM_MB2BYTES to Proc: $REDIS_CLI_MAXMEMORY"
			if (( $REDIS_CONFIG_MM_MB2BYTES < $REDIS_CLI_MAXMEMORY)); then
				_error "Redis Config maxmemory = $REDIS_MB2BYTES bytes and is smaller than Redis Running maxmemory = $REDIS_CLI_MAXMEMORY bytes."
			else
				_success "Redis Config maxmemory = $REDIS_MB2BYTES bytes is equal to or larger than Redis Running maxmemory = $REDIS_CLI_MAXMEMORY bytes."
			fi
			echo ""
		fi

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