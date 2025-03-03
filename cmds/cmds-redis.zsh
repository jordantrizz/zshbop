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
		echo "Usage: redis-info -f"
		echo "Options:"
		echo "  -p  port (Default: 6379)"		
		echo "  -s  socket (Default: /var/run/redis/redis.sock)"
		echo "  -a  password"
		echo "  -c  config file (Default: /etc/redis/redis.conf)"
		echo "Description: Grab redis maxmemory, configuration and statistics"
	}
	_loading "Collecting Redis Information"
	
	_debugf "args: $@"
	local -a CONFIG_FILE PORT SOCKET PASSWORD
	REDIS_CMD="_redis-info-full"

	# -- parse arguments
	zparseopts -D -E c:=ARG_CONFIG_FILE p:=ARG_PORT s:=ARG_SOCKET a:=ARG_PASSWORD 
	_debugf "CONFIG_FILE: $ARG_CONFIG_FILE ARG_PORT: $ARG_PORT ARG_SOCKET: $ARG_SOCKET ARG_PASSWORD: $ARG_PASSWORD"
	[[ -n $ARG_CONFIG_FILE ]] && { CONFIG_FILE=$ARG_CONFIG_FILE[2]; } || { CONFIG_FILE="/etc/redis/redis.conf"; }
	[[ -n $ARG_PORT ]] && { PORT=$ARG_PORT[2]; } || { PORT=6379; }
	[[ -n $ARG_SOCKET ]] && { SOCKET=$ARG_SOCKET[2]; } || { SOCKET="/var/run/redis/redis.sock"; }
	[[ -n $ARG_PASSWORD ]] && { PASSWORD=$ARG_PASSWORD[2]; }
	
	# -- Check if redis is running
	_loading2 "Checking if redis is running"
	if ! pgrep redis-server > /dev/null; then
		_error "Redis is not running"
		return
	fi

	# -- Add config file if defined
	if [[ -n $CONFIG_FILE ]]; then
		REDIS_CMD="$REDIS_CMD -c $CONFIG_FILE "
	fi

	# -- Add password if defined
	if [[ -n $PASSWORD ]]; then
		REDIS_CMD="$REDIS_CMD -a $PASSWORD "
	fi	

	# -- Check if port or socket is provided
	if [[ -n $PORT ]]; then
		REDIS_CMD+="-p $PORT"
		eval $REDIS_CMD
		return 0
	elif [[ -n $SOCKET ]]; then
		REDIS_CMD+="-s $SOCKET"	
		eval $REDIS_CMD
		return 0	
	fi
	
	# -- Check if there is more than one process
	if [[ $(pgrep -c redis-server) -gt 1 ]]; then
		local REDIS_PIDS=($(pgrep redis-server))
		_notice "More than one redis-server process running"	
		for PID in $REDIS_PIDS; do
			_notice "Redis server (PID: $PID):"
			
			# Get command line to show config
			local CMDLINE=$(\ps -p $PID -o args=)
			echo "  Command: $CMDLINE"
			
			# Find Unix sockets
			local UNIX_SOCKETS=$(ss -pxl | grep $PID | awk {' print $5 '})
			echo "  Unix Sockets: $UNIX_SOCKETS"
			
			# Find TCP ports
			local TCP_PORTS=$(ss -tpl | grep $PID)
			echo "  TCP Ports:"
			echo "$TCP_PORTS"
		done
		return
	else
		_success "One redis-server process running"
		_redis-info-full
	fi
}

# =================================================================================================
# -- _redis-info-full -c $CONFIG_FILE -p $PORT -s $SOCKET -a $PASSWORD
# =================================================================================================
_redis-info-full () {
	# -- Check if port or socket is set
	local CONFIG_FILE PORT SOCKET PASSWORD
	
	# -- Arguments
	_debugf "args: $@"
	zparseopts -D -E c:=ARG_CONFIG_FILE p:=ARG_PORT s:=ARG_SOCKET a:=ARG_PASSWORD
	
	_debugf "CONFIG: $ARG_CONFIG_FILE PORT: $ARG_PORT SOCKET: $ARG_SOCKET PASSWORD: $ARG_PASSWORD"
	[[ -n $ARG_CONFIG_FILE ]] && { CONFIG_FILE=$ARG_CONFIG_FILE[2]; }
	[[ -n $ARG_PORT ]] && { PORT=$ARG_PORT[2]; }
	[[ -n $ARG_SOCKET ]] && { SOCKET=$ARG_SOCKET[2]; }
	[[ -n $ARG_PASSWORD ]] && { PASSWORD=$ARG_PASSWORD[2]; }

	REDIS_CMD="redis-cli"

	# -- Check if config file is provided
	if [[ -n $CONFIG_FILE ]]; then
		_loading3 "Using config file: $CONFIG_FILE"
		REDIS_CMD="$REDIS_CMD -c $CONFIG_FILE"
	else
		_loading3 "No config file provided"
	fi
	
	# -- Check if port or socket is provided
	if [[ -n $PORT ]]; then		
		MESSAGE="Port: $PORT"		
		REDIS_CMD="redis-cli -p $PORT"
	elif [[ -n $SOCKET ]]; then
		MESSAGE="Socket: $SOCKET"
		REDIS_CMD="redis-cli -s $SOCKET"
	else
		MESSAGE="Default Port: 6379"
		REDIS_CMD="redis-cli"
	fi
	
	# -- Check if redis needs auth
	if [[ -n $PASSWORD ]]; then
		REDIS_CMD="$REDIS_CMD -a $PASSWORD"
		_loading3 "Using password from -a"
	else
		_loading3 "No password provided"
	fi

	# -- Check if we can connect to redis and get info
	_loading3 "Checking if we can connect to Redis"
	REDIS_CHECK=$(eval $REDIS_CMD info 2> /dev/null)
	# There is no failure status code for NOAUTH
	if [[ $REDIS_CHECK == "NOAUTH Authentication required." ]]; then
		_error "Redis requires a password"
		return 1
	else
		_success "Connected to Redis"
	fi

	_loading3 "Collecting Redis Information from $MESSAGE"
	_debugf "REDIS_CMD: $REDIS_CMD"

	REDIS_INFO=$(eval ${REDIS_CMD} info 2> /dev/null)
	# -- Remove "Warning: Using a password with" from stderr
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

	_loading "Checking for $CONFIG_FILE"
	if [[ -f $CONFIG_FILE ]]; then
		# -- Get redis config settings
		_success "Found $CONFIG_FILE"
		_noticebg "Redis 'maxmemory' setting"
		REDIS_CONFIG_MAXMEMORY=$(grep -e '^maxmemory ' $CONFIG_FILE | awk '{print $2}')
		REDIS_CONFIG_MAXMEMORY_POLICY=$(grep '^maxmemory-policy ' $CONFIG_FILE | awk '{print $2}')
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
			_error "Redis Config maxmemory is not set in $CONFIG_FILE can't compare"
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
		grep '^save ' $CONFIG_FILE
		echo ""

		_noticebg "Redis rdb settings"
		grep 'rdb' $CONFIG_FILE | grep -v "^#"
		echo ""
		
		_noticebg "Redis append-only setting"
		grep -e '^appendonly ' $CONFIG_FILE
		echo ""
		
	else
		_error "No $CONFIG_FILE file"
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

# ===============================================
# -- redis-get-db-size-all
# ===============================================
help_redis[redis-get-db-size-all]="Get the size of all redis databases"
redis-get-db-size-all () {
	_loading "Getting the size of all redis databases"
	if ! pgrep redis-server > /dev/null; then
		_error "Redis is not running"
		return
	fi

	# -- Check if redis needs auth
	if [[ -n $(redis-pass) ]]; then
		REDIS_CMD="redis-cli -a $(redis-pass) 2> /dev/null"
	else
		REDIS_CMD="redis-cli"
	fi

	_loading "Redis Database Keyspace Information"
	# -- Get the size of all redis databases
	$REDIS_CMD info keyspace

}
