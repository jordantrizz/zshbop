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
function   () {
	# -- Check if mysql_wrapper is installed
	_cmd_exists _mysql_wrapper
	if [[ $? == 1 ]]; then
		_debugf "MySQL wrapper is not installed"
	else
		_debugf "MySQL wrapper is installed"
		alias mysql="_mysql_wrapper"
	fi
}
INIT_LAST+=('_zb_mysql_wrapper')

# ===============================================
# -- _zb_mysqldump_wrapper
# ===============================================
help_int_mysql[_zb_mysqldump_wrapper]='Set mysqldump wrapper'
function _zb_mysqldump_wrapper () {
	# -- Check if _mysqldump_wrapper is installed
	_cmd_exists _mysqldump_wrapper
	if [[ $? == 1 ]]; then
		_debugf "MySQL wrapper is not installed"
		echo "$(which mysqldump)"
	else
		_debugf "MySQL wrapper is installed"
		echo "_mysqldump_wrapper"
	fi
}
alias mysqldump="$(_zb_mysqldump_wrapper)"