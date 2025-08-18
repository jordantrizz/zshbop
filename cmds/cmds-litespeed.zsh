# -- Litespeed and Openlitespeed commands
_debug " -- Loading ${(%):-%N}"
help_files[litespeed]='Litespeed and Openlitespeed commands'
typeset -gA help_litespeed

# ==========================================================
# -- lsw-restart
# ==========================================================
help_litespeed[lsws-fullrestart]='Restart LSW/OLS and kill lsphp'
lsw-fullrestart () {
	lswsctrl fullrestart
	skill -9 lsphp
}

# ==========================================================
# -- lsws
# ==========================================================
help_litespeed[lsws]='Change directory to Litespeed root'
lsws () {
	cd /usr/local/lsws
}

# ==========================================================
# -- lsphp74
# ==========================================================
help_litespeed[lsphp74]='Run lsphp74 cli'
alias lsphp74="/usr/local/lsws/lsphp74/bin/php"

# ==========================================================
# -- lsphp80
# ==========================================================
help_litespeed[lsphp81]='Run lsphp81 cli'
alias lsphp81="/usr/local/lsws/lsphp81/bin/php"

# ==========================================================
# -- ols-check-config
# ==========================================================
help_litespeed[ols-check-config]='Check OpenLiteSpeed configuration'
function ols-check-config () {
	# Check if openlitespeed is installed
		OLS_VERSION="$(/usr/local/lsws/bin/openlitespeed -v 2>&1)"
	if [[ $? -ne 0 ]]; then
		echo "OpenLiteSpeed is not installed or not found in /usr/local/lsws/bin/"
		return 1
	else
		echo "OpenLiteSpeed is installed and found in /usr/local/lsws/bin/openlitespeed"
		echo "==========================================="
		echo $OLS_VERSION
		echo "==========================================="
	fi

	OLS_STATUS="$(/usr/local/lsws/bin/openlitespeed -t 2>&1)"
	if [[ -n "$OLS_STATUS" ]]; then
		_error "OpenLiteSpeed Syntax Test failed!"
		if [[ "$OLS_STATUS" == *"/usr/local/lsws/conf/vhosts"* ]]; then
			_error "OpenLiteSpeed Syntax Test failed - problems with a site's vhconf"
		else
			_error "OpenLiteSpeed Syntax Test failed - problems with httpd_config.conf"
		fi
			echo "------------------------------------------"
			echo "$OLS_STATUS"
			echo "------------------------------------------"
			return 1
	else
		echo "OpenLiteSpeed configuration file syntax tests successful!"
	fi
}

# ==========================================================
# -- ols-output-config
# ==========================================================
help_litespeed[ols-output-config]='Output OpenLiteSpeed configuration'
function ols-output-config () {
	TMP_OLS_CONFIG="$(mktemp /tmp/ols_config_output.XXXXXX)"
	if [[ $? -ne 0 ]]; then
		_error "Failed to create temporary file for OpenLiteSpeed configuration output"
		return 1
	fi

	# Output main OpenLiteSpeed configuration and vhosts to stdout and tmp file
	OLS_CONFIG="/usr/local/lsws/conf/httpd_config.conf"
	if [[ ! -f $OLS_CONFIG ]]; then
		_error "OpenLiteSpeed configuration file not found at $OLS_CONFIG"
		return 1
	fi
	echo "OpenLiteSpeed configuration file found at $OLS_CONFIG"
	echo "==========================================="
	cat $OLS_CONFIG
	echo "==========================================="
	echo "Outputting OpenLiteSpeed configuration to /tmp/ols_config_output.txt"
	cat $OLS_CONFIG > "$TMP_OLS_CONFIG"
	echo "OpenLiteSpeed configuration file outputted to /tmp/ols_config_output.txt"
	echo "==========================================="
	echo "OpenLiteSpeed vhosts configuration:"
	OLS_VHOSTS_DIR="/usr/local/lsws/conf/vhosts"
	if [[ ! -d $OLS_VHOSTS_DIR ]]; then
		_error "OpenLiteSpeed vhosts directory not found at $OLS_VHOSTS_DIR"
		return 1
	fi
	echo "OpenLiteSpeed vhosts directory found at $OLS_VHOSTS_DIR"
	echo "==========================================="
	for vhost in $OLS_VHOSTS_DIR/*; do
		if [[ -d $vhost ]]; then
			echo "Vhost: $(basename $vhost)"
			if [[ -f $vhost/vhconf.conf ]]; then
				echo "Vhost configuration file found at $vhost/vhconf.conf"
				echo "==========================================="
				cat $vhost/vhconf.conf
				cat $vhost/vhconf.conf >> "$TMP_OLS_CONFIG"
				echo "==========================================="
			else
				_error "Vhost configuration file not found at $vhost/vhconf.conf"
			fi
		else
			_error "Vhost directory $vhost is not a directory"
		fi
	done

	echo "OpenLiteSpeed configuration output completed."	
	if [[ -f "$TMP_OLS_CONFIG" ]]; then
		echo "OpenLiteSpeed configuration output saved to $TMP_OLS_CONFIG"
		echo "You can view it with: cat $TMP_OLS_CONFIG"
	else
		_error "Failed to save OpenLiteSpeed configuration output to $TMP_OLS_CONFIG"
		return 1
	fi
}