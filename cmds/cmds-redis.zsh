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

redis-memory () {
	if [[ -f /etc/redis/redis.conf ]]; then
		_notice "Redis 'maxmemory' setting from /etc/redis/redis.conf"
		grep '^maxmemory ' /etc/redis/redis.conf
	else
		_error "No /etc/redis/redis.conf file"
	fi
	_notice "Getting redis-cli info memory"
	redis-cli info memory
}