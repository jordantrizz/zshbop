# =================================================================================================
# MySQL commands
# =================================================================================================
_debug " -- Loading ${(%):-%N}"
# What help file is this?
help_int[mysql_func]='MySQL Internal Functions'
typeset -gA help_int_mysql

MYSQL_PAGER=

# ===============================================
# -- _zb_mysql_wrapper
# ===============================================
help_int_mysql[_zb_mysql_wrapper]='Set mysql wrapper'
function  _zb_mysql_wrapper () {
	_log "Setting mysql wrapper"
	# -- Check if mysql_wrapper is installed
	_cmd_exists _mysql_wrapper
	if [[ $? == 1 ]]; then
		_debugf "MySQL wrapper is not installed"
		function _mysql_wrapper () {
			mysql "$@"
		}
	else
		_debugf "MySQL wrapper is installed"		
		export MYSQL_WRAPPER=$(which _mysql_wrapper)
	fi
}
INIT_LAST_CORE+=(_zb_mysql_wrapper)

# ===============================================
# -- _zb_mysqldump_wrapper
# ===============================================
help_int_mysql[_zb_mysqldump_wrapper]='Set mysqldump wrapper'
function _zb_mysqldump_wrapper () {
	# -- Check if _mysqldump_wrapper is installed
	_cmd_exists _mysqldump_wrapper
	if [[ $? == 1 ]]; then
		_debugf "MySQL wrapper is not installed"
		function _mysqldump_wrapper () {
			_debugf "mysqldump --max_allowed_packet=512M $@"
			mysqldump --max_allowed_packet=512M "$@"
		}
	else
		_debugf "MySQL wrapper is installed"		
		export MYSQLDUMP_WRAPPER=$(which _mysqldump_wrapper)
	fi
}
INIT_LAST_CORE+=(_zb_mysqldump_wrapper)