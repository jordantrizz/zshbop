# =========================================================
# -- WordPress
# =========================================================
_debug " -- Loading ${(%):-%N}"
help_files[wordpress]='WordPress related commands'
typeset -gA help_wordpress
help_files[wordpress_func]='WordPress internal functions'
typeset -gA help_inc_wordpress


# =========================================================
# -- wp wrapper
# =========================================================
help_wordpress[wp]='Run wp-cli with --allow-root'
alias wp="wp --allow-root"

# =========================================================
# -- _wp-cli-check
# =========================================================
help_inc_wordpress[_wp-cli-check]='Check if wp-cli is installed'
_wp-cli-check () {
	# Check if wp-cli is installed
	_cmd_exists wp
	if [[ $? == "1" ]]; then
		_error "Can't find wp-cli:"
		return 1
	fi
}

# =========================================================
# -- _wp-install-check
# =========================================================
help_inc_wordpress[_wp-install-check]='Check if WordPress is installed'
_wp-install-check () {
	# Check if WordPress is installed
	WP_EXISTS=$(wp core is-installed 2> /dev/null)
	if [[ $? == 1 ]]; then
		_error "WordPress is not installed in the current directory."
		return 1
	fi
}

# =========================================================
# =========================================================
# =========================================================
# =========================================================

# =========================================================
# -- wp-db
# =========================================================
help_wordpress[wp-db]='Echo WordPress database credentials'
wp-db () {
	if [ -f wp-config.php ]; then
		grep 'DB' wp-config.php
	elif [ -f ../wp-config.php ]; then
		grep 'DB' ../wp-config.php
	fi
}

# -- wp-countposts
help_wordpress[wp-countposts]='Count WordPress wp_posts table rows.'
wp-countposts () {
	if [ -z $1 ]; then
		echo "$0 <dbname>";
		echo ""
		echo "example: wp-posts database"
	else
		mysql $1 -e "SELECT post_type,COUNT(*) FROM wp_posts GROUP BY post_type ORDER BY COUNT(*) DESC;";
	fi
}

# -- wp-ultimo-delete-subs
wp-ultimo-delete-subs () {
	# Ultimo Tables
	#
	# wp_wu_transactions
	# wp_wu_subscriptions
	# wp_wu_site_owner
	# wp_postmeta post_type = wpu_order
	# wp_domain_mapping
	#
	# Subscription Delete
	# Userid = 17
	# Siteid = 18
	# Subscription ID = 12
	#
	# Find SiteID of wordpress user_id
	# - select site_id FROM wp_wu_site_owner WHERE user_id = 17;
	#
	# Find subscription for wordpress user_id
	# - select * from wp_wu_subscriptions where user_id = '17';
	#
	#

	# delete from wp_wu_transactions where user_id = ‘17’;

	#SELECT DISTINCT ID FROM wp_posts, wp_postmeta WHERE wp_posts.ID = wp_postmeta.post_id AND wp_postmeta.meta_key = 'wpu_order' AND post_type = 'wpultimo_plan' && post_status = 'publish' ORDER BY CAST(wp_postmeta.meta_value as unsigned) ASC
}

# -- wp-countposts
help_wordpress[wp-reinstall]='Force install WordPress core files.'
wp-reinstall () {
	_warning "*** WARNING: This will re-install WordPress core files ***"
	_warning "*** Please make sure this is the correct directory $1 ***"
	read -q "REPLY?Continue? (y/n)"

	if [[ "$REPLY" == "y" ]]; then
		wp core download --force --skip-content
	else
		echo "\nPressed n Quitting.."
	fi
}
help_wordpress[wp-reset]='Completely clean out a site. Danger!' # @@ISSUE
wp-reset () {
	echo "Not built yet"
}

help_wordpress[wp-autoload]='List autoloads'
wp-autoload () {
        if [ -z $1 ]; then
                echo "$0 <dbname>";
                echo ""
                echo "example: wp-autoload database"
        else
		# https://kinsta.com/knowledgebase/wp-options-autoloaded-data/
		mysql -e "SELECT 'autoloaded data in KiB' as name, ROUND(SUM(LENGTH(option_value))/ 1024) as value FROM $1.wp_options WHERE autoload='yes' \
		UNION SELECT 'autoloaded data count', count(*) FROM $1.wp_options WHERE autoload='yes' UNION (SELECT option_name, length(option_value) \
		FROM $1.wp_options WHERE autoload='yes' ORDER BY length(option_value) DESC LIMIT 10)"
	fi
}

# -- wp-login
help_wordpress[wp-login]='Install wp-cli-login-command module'
wp-login () {
	wp package install aaemnnosttv/wp-cli-login-command
	wp login install --activate
}

# -- wp-force-login
help_wordpress[wp-force-login]='Force login to WordPress site'
wp-force-login () {
    wp plugin install --activate wp-force-login
}


# -- wp-doctor
help_wordpress[wp-doctor]='Install wp-doctor module'
wp-doctor () {
	wp package install wp-cli/doctor-command:@stable
}

# -- wp-skip
help_wordpress[wp-skip]='wp-cli but skip themes and plugins'
alias wp-skip="wp --skip-themes --skip-plugins"

# -- wp-backupsite
help_wordpress[wp-backupsite]="Backup WordPress site on server to ~/backups"
function wp-backupsite () {
	local SITE=${1} ACTION=${2}	
	local CURR_DIR=$(pwd)
	local DRYRUN=${3:=0}
	_wp_backupsite_usge () {
		echo "Usage: wp-backupsite <domain> <action> <dryrun>"
		echo "  Make sure you're in the wordpress directory, and have wp-cli installed"
		echo ""
		echo "  Options:"
		echo "	domain <site.com>      - domain name of the site"
		echo "	action <db|files|all>  - db, files, all (optional)"
		echo "	dryrun <1>             - dryrun mode (optional)"
		echo ""
		echo "  Example: wp-backupsite example.com"
	}

	# -- Check if site is defined
    if [[ -z $SITE ]]; then
		_wp_backupsite_usge
		return 1
	fi
	
	# -- Check if action is defined
	if [[ -z $ACTION ]]; then
		ACTION="all"		
	elif [[ $ACTION != "db" && $ACTION != "files" && $ACTION != "all" ]]; then
		_wp_backupsite_usge
		_error "Invalid action: $ACTION"
		return 1
	fi
	

	_loading "Backing up $ACTION for $SITE to $HOME/backups"
	[[ $DRYRUN == "1" ]] && _loading3 "Dryrun mode enabled"
	
	# -- check if wp-cli is installed
	_loading3 "Checking if wp-cli is installed"
	_cmd_exists wp
	if [[ $? == "1" ]]; then
		_error "Can't find wp-cli:"
		[[ $DRYRUN == "0" ]] && return 1
	else
		_loading3 "wp-cli is installed"
	fi

	_loading3 "Checking if WordPress is installed in the current directory $CURR_DIR"
    WP_CHECK=$(wp --allow-root core is-installed)	
    if [[ $? == "1" ]]; then
        _error "WordPress is not installed in $CURR_DIR"
		echo "$WP_CHECK"
		[[ $DRYRUN == "0" ]] && return 1
    else
		_loading3 "WordPress is installed in $CURR_DIR"
	fi

    if [[ ! -d $HOME/backups ]]; then
        echo "$HOME/backups directory doesn't exist...creating..."
        mkdir $HOME/backups
    fi

	if [[ $ACTION == "db" || $ACTION == "all" ]]; then
    	_loading "Exporting database for ${SITE}..."
		_loading3 "wp --allow-root db export - | gzip > ${HOME}/backups/db_${SITE}-$(date +%Y-%m-%d-%H%M%S).sql.gz"
    	[[ $DRYRUN == "0" ]] && wp --allow-root db export - | gzip > ${HOME}/backups/db_${SITE}-$(date +%Y-%m-%d-%H%M%S).sql.gz
	fi

	if [[ $ACTION == "files" || $ACTION == "all" ]]; then
		_loading "Backing up files for ${SITE}..."
    	[[ $DRYRUN == "0" ]] && tar --create --gzip --absolute-names --file=${HOME}/backups/wp_${SITE}-$(date +%Y-%m-%d-%H%M%S).tar.gz --exclude='*.tar.gz' --exclude='*.zip'--exclude='wp-content/cache' --exclude='wp-content/ai1wm-backups' .
	fi
}

# =========================================================
# -- wp-skip
# =========================================================
help_wordpress[wp-admin-email]='Update admin email'
function wp-admin-email () {
	_wp-admin-email-usage () {
		echo "Usage: wp-admin-email (get|set <email>)"
	}

	[[ -z $1 ]] && { _wp-admin-email-usage; return 1 }		
	
	_wp-cli-check && _wp-install-check || return 1
	if [[ $1 == "set" ]]; then
		[[ -z $2 ]] && { _wp-admin-email-usage; return 1 }
		wp option update admin_email ${2}
	elif [[ $1 == "get" ]]; then
		wp option get admin_email
	else
		_wp-admin-email-usage
	fi

}
# -- wp-plugins
help_wordpress[wp-plugins]='List plugins'
function wp-plugins () {
    wp plugin status
}

# -- wp-cronshim
help_wordpress[wp-cronshim]='Run wp-cron via cron-shim.sh'
function wp-cronshim () {
    echo "Downloading cron-shim.sh... via https://raw.githubusercontent.com/managingwp/wp-shelltools/main/scripts/cron-shim.sh"
    curl -O https://raw.githubusercontent.com/managingwp/wp-shelltools/main/scripts/cron-shim.sh
    chmod u+x cron-shim.sh
}

# =========================================================
# -- wp-cli-install
# =========================================================
help_wordpress[wp-cli-install]='Install wp-cli'
function wp-cli-install () {
    if [[ -f /usr/local/bin/wp ]]; then
        echo "wp-cli already installed"
        return 1
    else
        echo "Installing wp-cli..."
        # https://wp-cli.org/#installing
        # download via curl to /tmp
        curl -o /tmp/wp-cli.phar https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
        chmod +x /tmp/wp-cli.phar
        mv /tmp/wp-cli.phar /usr/local/bin/wp
        echo "wp-cli installed"
    fi
}

# =========================================================
# -- wp-profile
# =========================================================
help_wordpress[wp-profile]='Install wp-cli-profile-command module'
function wp-profile () {
    wp package install wp-cli/profile-command
}

# =========================================================
# -- wp-find-wp-cli
# =========================================================
help_wordpress[wp-find]='Find WordPress instances'
function wp-find () {
	echo "Install wp-cli find-command"
	echo "wp package install wp-cli/find-command:@stable"
}

# =========================================================
# -- wp-find
# =========================================================
help_wordpress[wp-find]='Find WordPress instances'
function wp-find () {
	if [[ -z $1 ]]; then
		echo "Usage: wp-find <directory>"
		return 1
	fi
	START_DIR="$1"

	if [[ -z $2 ]] echo "Finding WordPress instances in ${START_DIR}..."

	# Find wp-config.php files and guess ABSPATH
	find "$START_DIR" -name 'wp-config.php' | while read WP_CONFIG_FILE; do
		local WP_CONFIG_PATH=$(dirname $WP_CONFIG_FILE)
		if [[ -d "$WP_CONFIG_PATH/wp-admin" && -d "$WP_CONFIG_PATH/wp-includes" ]]; then
        	echo "$WP_CONFIG_PATH"
    	fi
	done
}

# =========================================================
# -- wp-find-check
# =========================================================
help_wordpress[wp-find-check]='Find WordPress instances and check for core file changes'
function wp-find-check () {
	if [[ -z $1 ]]; then
		echo "Usage: wp-find-check <path> [verbose]"
		return 1
	else
		# -- Check if wp-cli is installed
		_cmd_exists wp
		if [[ $? == "1" ]]; then
			_error "Can't find wp-cli:"
			return 1
		fi

		# -- Check if find package is installed
		WPCLI_FIND_CHECK=$(wp package list | grep find-command)
		if [[ $? == "1" ]]; then
			_loading "Installing wp-cli find-command package"
			wp package install wp-cli/find-command:@stable
		else
			_loading "wp-cli find-command package already installed"
		fi

		# -- Set Variables
		SEARCH_PATH="$1"
		VERBOSE="$2"

		_loading "Checking for WordPress sites at $SEARCH_PATH"
		# -- Find WordPress Sites
		FOUND_SITES_WPPATH=($(wp --allow-root find $SEARCH_PATH --fields=wp_path | grep -v '^wp_path$'))

		# -- Check WordPress sites for core file changes
		for SITE_WPPATH in ${FOUND_SITES_WPPATH[@]}; do
			VERIFY_CHECKSUMS=""
			_loading2 "Checking Site: $SITE_WPPATH"
			VERIFY_CHECKSUMS=$(wp --allow-root --path="$SITE_WPPATH" core verify-checksums 2>&1)

			# -- Check if site has been modified
			if [[ $(echo $VERIFY_CHECKSUMS | grep -i 'Error:') ]]; then
				# -- Count number of files affected
				NUM_FILES_VERIFY_CHECKSUMS=$(echo $VERIFY_CHECKSUMS | wc -l)

				# -- Print out verbose output if requested
				if [[ $VERBOSE ]]; then
					echo $VERIFY_CHECKSUMS
				fi
				_error "    Error: Site doesn't verify checksums, files affected $NUM_FILES_VERIFY_CHECKSUMS"
			else
				_success "Success: Site not modified"
			fi
		_divider_dash
		done
	fi
}

# =========================================================
# -- wp74
# =========================================================
help_wordpress[wp74]='Run wp-cli with PHP 7.4'
function wp74 () {
	[[ -f /usr/bin/php7.4 ]] && { /usr/bin/php7.4 /usr/local/bin/wp "$@" }
}

function wp-query-monitor() {
    if [ $# -ne 1 ]; then
        echo "Usage: wp-query-monitor [enable|disable|remove]"
        return 1
    fi

    action=$1

    _loading "Managing Query Monitor"

    # Check if wp-cli is installed
    _loading2 "Checking if wp-cli is installed"
    if ! command -v wp &>/dev/null; then
        echo "wp-cli is not installed. Please install it first."
        return 1
    fi

    # Check if WordPress is installed
    _loading2 "Checking if WordPress is installed"
    if ! wp core is-installed &>/dev/null; then
        echo "WordPress is not installed in the current directory."
        return 1
    else
        _loading3 "WordPress is installed"
    fi

    case $action in
        "enable")
            _loading2 "Enabling Query Monitor"
            if wp plugin is-installed query-monitor; then
                if ! wp plugin is-active query-monitor; then
                    wp plugin activate query-monitor
                    echo "Query Monitor has been enabled."
                else
                    echo "Query Monitor is already enabled."
                fi
            else
                _loading3 "Query Monitor is not installed, installing now."
                wp plugin install query-monitor --activate
                echo "Query Monitor has been installed and enabled."
            fi
            ;;
        "disable")
            _loading2 "Disabling Query Monitor"
            if wp plugin is-installed query-monitor && wp plugin is-active query-monitor; then
                wp plugin deactivate query-monitor
                echo "Query Monitor has been disabled."
            else
                echo "Query Monitor is not installed or already disabled."
            fi
            ;;
        "remove")
            _loading2 "Removing Query Monitor"
            if wp plugin is-installed query-monitor; then
                wp plugin uninstall query-monitor
                echo "Query Monitor has been uninstalled."
            else
                echo "Query Monitor is not installed."
            fi
            ;;
        *)
            echo "Invalid action. Usage: wp-query-monitor [enable|disable|remove]"
            return 1
            ;;
    esac
}

# =========================================================
# -- wp-ajaxlog
# =========================================================
help_wordpress[wp-ajaxlog]='Pull down ajaxlog.php from github.com/managingwp/wordpress-code-snippets'
function wp-ajaxlog () {
	wget https://raw.githubusercontent.com/managingwp/wordpress-code-snippets/main/ajaxlog/ajaxlog.php
}

# =========================================================
# -- wp-wordfence-scan
# =========================================================
help_wordpress[wp-wordfence-scan]='Run Wordfence CLI scan'
function wp-wordfence-scan () {
	local SEARCH_PATH="$1"
	local LOG_DIR="$HOME/wp-wordfence-scan-logs"

	# -- internal functions
	_wp-wordfence-scan-usage () {
		echo "Usage: wp-wordfence-scan <path>"
		return 1
	}
	_wp-wordfence-scan-log () {
		local LOG_DATE=$(date +%Y-%m-%d-%H%M%S)
		local LOG_FILE="$LOG_DIR/wp-wordfence-scan-${LOG_DATE}.log"
		local LOG_ENTRY="$LOG_DATE - $1"
		echo "$LOG_ENTRY" >> $LOG_FILE
		if [[ -z $2 ]]; then
			echo "$1"
		fi
	}

	# -- Check path exists
	if [[ -z $SEARCH_PATH ]]; then
		_wp-wordfence-scan-usage
		return 1
	elif [[ ! -d $SEARCH_PATH ]]; then
		_wp-wordfence-scan-usage
		_error "Path $SEARCH_PATH doesn't exist"
		return 1
	fi

	# -- Check if wordfence is installed
	_cmd_exists wordfence
	if [[ $? == "1" ]]; then
		_wp-wordfence-scan-usage
		_error "Can't find wordfence-cli, please install"
		return 1
	fi

	# -- Start logging
	_wp-wordfence-scan-log ">>>>>>>>>>>> START OF RUN <<<<<<<<<<<<" 1
	_wp-wordfence-scan-log ">>>>>>>>>>>> START OF RUN <<<<<<<<<<<<" 1

	# What are we doing?
	_wp-wordfence-scan-log "$(_loading "Running Wordfence scan on $SEARCH_PATH")"

	# -- Find WordPress Sites
	WP_SITE_PATHS=($(wp-find $SEARCH_PATH 1))
	_wp-wordfence-scan-log "$(_loading3 "Found ${#WP_SITE_PATHS[@]} WordPress sites")"

	# -- Run a scan on each site
	for WP_SITE_PATH in ${WP_SITE_PATHS[@]}; do
		_wp-wordfence-scan-log "$(_loading2 "Scanning $WP_SITE_PATH with - wordfence malware-scan -q --no-banner $WP_SITE_PATH")"
		OUTPUT=$(wordfence malware-scan -q --no-banner $WP_SITE_PATH)
		if [[ -z $OUTPUT ]]; then
			_wp-wordfence-scan-log "${GREEN_BG}No issues found${RSC}"
			_wp-wordfence-scan-log "$OUTPUT"
		else
			_wp-wordfence-scan-log "${RED_BG}Issues found${RSC}"
			_wp-wordfence-scan-log "$OUTPUT"

		fi
		_divider_dash
	done

	# -- End logging
	_wp-wordfence-scan-log ">>>>>>>>>>>> END OF RUN <<<<<<<<<<<<" 1
	_wp-wordfence-scan-log ">>>>>>>>>>>> END OF RUN <<<<<<<<<<<<" 1
}

# =========================================================
# -- wp-updates
# =========================================================
help_wordpress[wp-updates]='Check for WordPress updates'
function wp-updates() {
    local SEARCH_PATH="$1"
    local ACTION=$2
    local VERBOSE=${3:-false}
	local LOG_DIR="$HOME/wp-updates-logs"
	local LOG_DATE=$(date +%Y-%m-%d-%H%M%S)
	local TOTAL_WP_CORE_UPDATES=0
	local TOTAL_WP_PLUGIN_UPDATES=0
	local TOTAL_WP_THEME_UPDATES=0
	local TOTAL_WP_CORE_UPDATES_APPLIED=0
	local TOTAL_WP_PLUGIN_UPDATES_APPLIED=0
	local TOTAL_WP_THEME_UPDATES_APPLIED=0	

	# -- Init log files
	if [[ $ACTION == "list" ]]; then
		local LOG_FILE="$LOG_DIR/wp-updates-${LOG_DATE}.log"
		local REPORT_FILE="$LOG_DIR/wp-updates-report-${LOG_DATE}.txt"
	elif [[ $ACTION == "update" ]]; then
		local LOG_FILE="$LOG_DIR/wp-updates-applied-${LOG_DATE}.log"
		local REPORT_FILE="$LOG_DIR/wp-updates-applied-report-${LOG_DATE}.txt"
	fi

	# -- Log Functions
    _wp-updates-usage () {
        echo "Usage: wp-updates <path> [list|update|core|plugins|themes] [verbose]"
        return 1
    }
	_wp-updates-log () {	
		local LOG_ENTRY="$1"
		echo "$LOG_ENTRY" >> $LOG_FILE
		if [[ -z $2 ]]; then
			echo "$1"	
		fi
	}
	_wp-updates-report () {				
		local REPORT_ENTRY="$1"
		CLEANED_REPORT_LINE=$(echo "$REPORT_ENTRY" | sed 's/\x1b\[[0-9;]*m//g')		
		echo "$REPORT_ENTRY" >> $REPORT_FILE
		#cat wp-updates-report-2023-11-23-171227.txt | sed 's/,/\t/g' | column -t
	}

	_wp-updates-verbose () {
		if [[ $VERBOSE == "true" ]]; then
			echo "$1"
		fi
	}

    # Check if $SEARCH_PATH is set
    if [[ -z $SEARCH_PATH ]]; then
        _wp-updates-usage
        return 1
    fi

    # Check if $ACTION is set
    if [[ -z $ACTION ]]; then
        _wp-updates-usage
        return 1
    fi

	# -- Setup Logging dir
	if [[ ! -d $HOME/wp-updates-logs ]]; then
		mkdir $HOME/wp-updates-logs
	fi

    # Print out whats occurring
    _wp-updates-log "$(_loading "Running action:$ACTION on $SEARCH_PATH")"
	_wp-updates-log "$(_loading2 "Logging to $LOG_FILE and report output to $REPORT_FILE")"
	_wp-updates-log ">>>>>>>>>>>> START OF RUN <<<<<<<<<<<<" 1
	_wp-updates-log ">>>>>>>>>>>> START OF RUN <<<<<<<<<<<<" 1

    # Check if wp-cli is installed
    if ! command -v wp &>/dev/null; then
        _error "wp-cli is not installed. Please install it first."
        return 1
    fi

	# -- Check if jq is installed
	_cmd_exists jq
	if [[ $? == 1 ]]; then
		_error "jq is not installed. Please install it first."
		return 1
	fi

	# -- Get latest version of WP
	WP_LATEST_VER=$(curl -s https://api.wordpress.org/core/version-check/1.7/ | jq -r '.offers[0].version')
	_wp-updates-log "$(_success "Latest WordPress version is $WP_LATEST_VER")"

    check_update_wp() {
        local WP_PATH=$1
		local OUTPUT=""

        # Check if WordPress is installed
        WP_EXISTS=$(wp core is-installed --path="$WP_PATH" &>/dev/null)
        if [[ $? == 1 ]] ; then
            _wp-updates-log "$(_error "WordPress is not installed in the $WP_PATH directory - $WP_EXISTS")"
            return 1
        fi

		# -- Print out path and get domain name via wp-cli on a single line
		WP_DOMAIN="$(wp --skip-themes --skip-plugins --allow-root option get siteurl --path="$WP_PATH")"
		OUTPUT="Path: $WP_PATH | Domain: $WP_DOMAIN"

        case $ACTION in
            list)
				local WP_CORE_UPDATED="unknown"
				OUTPUT+=" | LIST "
                WP_CORE_VER=$(wp --allow-root --skip-themes --skip-plugins core version --path="$WP_PATH")
                PLUGIN_COUNT=$(faketty wp --allow-root --skip-themes --skip-plugins plugin list --path="$WP_PATH" --update=available --format=count | awk '{print $1; if(NR>1) print "ERROR: More than one line of output"}')
                THEME_COUNT=$(faketty wp --allow-root --skip-themes --skip-plugins theme list --path="$WP_PATH" --update=available --format=count | awk '{print $1; if(NR>1) print "ERROR: More than one line of output"}')
				if [[ $WP_CORE_VER == $WP_LATEST_VER ]]; then
					WP_CORE_UPDATED="true"
					OUTPUT+=" | Core: ${GREEN_BG}Latest ${WP_CORE_VER}/${WP_LATEST_VER}${RSC}"
				else
					WP_CORE_UPDATED="false"
					OUTPUT+=" | Core: ${RED_BG}Outdated ${WP_CORE_VER}/${WP_LATEST_VER}${RSC}"
				fi
                if [[ $PLUGIN_COUNT == 0 ]]; then
					OUTPUT+=" | Plugin: ${GREEN_BG}None${RSC}"
				else
					OUTPUT+=" | Plugin: ${RED_BG}$PLUGIN_COUNT${RSC}"
				fi
				if [[ $THEME_COUNT == 0 ]]; then
					OUTPUT+=" | Theme: ${GREEN_BG}None${RSC}"
				else
					OUTPUT+=" | Theme: ${RED_BG}$THEME_COUNT${RSC}"
				fi
                if [[ "$VERBOSE" == "true" ]]; then
                    OUTPUT+="Detailed list of outdated plugins:\n"
                    OUTPUT+="$(faketty wp --allow-root --skip-themes --skip-plugins plugin list --path="$WP_PATH" --update=available)\n"
                    OUTPUT+="Detailed list of outdated themes:\n"
                    OUTPUT+="$(faketty wp --allow-root --skip-themes --skip-plugins theme list --path="$WP_PATH" --update=available)\n"
                fi
				_wp-updates-log "$OUTPUT"
				REPORT_LINE="$WP_PATH,$WP_DOMAIN,$WP_CORE_UPDATED,$WP_CORE_VER,$PLUGIN_COUNT,$THEME_COUNT"
				_wp-updates-report "$REPORT_LINE"
				TOTAL_WP_CORE_UPDATES=$(($TOTAL_WP_CORE_UPDATES + $WP_CORE_UPDATED))
				TOTAL_WP_PLUGIN_UPDATES=$(($TOTAL_WP_PLUGIN_UPDATES + $PLUGIN_COUNT))
				TOTAL_WP_THEME_UPDATES=$(($TOTAL_WP_THEME_UPDATES + $THEME_COUNT))
                ;;
            update)
                local PLUGIN_UPDATE_COUNT=0
                local THEME_UPDATE_COUNT=0
                local WP_CORE_UPDATED="unknown"

				OUTPUT+=" | UPDATES"
                # Updating WordPress Core
				WP_CORE_VER=$(wp --allow-root --skip-themes --skip-plugins core version --path="$WP_PATH")
                CORE_UPDATE_OUTPUT=$(wp --allow-root core update --path="$WP_PATH" --skip-themes --skip-plugins)
                if [[ $CORE_UPDATE_OUTPUT == *"WordPress is up to date."* ]]; then
                    OUTPUT+=" | Core: ${GREEN_BG}Latest $WP_CORE_VER/$WP_LATEST_VER${RSC}"
					WP_CORE_UPDATED="true"
                else
					OUTPUT+=" | Core: ${RED_BG}Outdated $WP_CORE_VER/$WP_LATEST_VER${RSC}"
					WP_CORE_UPDATED="false"
				fi

                # Updating Plugins
                PLUGIN_UPDATE_OUTPUT=$(wp --allow-root plugin update --all --path="$WP_PATH" --skip-themes --skip-plugins)
                if [[ $PLUGIN_UPDATE_OUTPUT != *"Plugin already updated".* ]]; then
                    PLUGIN_UPDATE_COUNT=$(echo "$PLUGIN_UPDATE_OUTPUT" | grep -c 'Updating' | wc -l)
					OUTPUT+=" | Plugins: ${RED_BG}${PLUGIN_UPDATE_COUNT}${RSC}"
                else
					OUTPUT+=" | Plugins: ${GREEN_BG}None${RSC}"
				fi

                # Updating Themes
                THEME_UPDATE_OUTPUT=$(wp --allow-root theme update --all --path="$WP_PATH" --skip-themes --skip-plugins)
                if [[ $THEME_UPDATE_OUTPUT != *"Theme already updated."* ]]; then
                    THEME_UPDATE_COUNT=$(echo "$THEME_UPDATE_OUTPUT" | grep -c 'Updating' | wc -l)
					OUTPUT+=" | Themes: ${RED_BG}${THEME_UPDATE_COUNT}${RSC}"
                else
					OUTPUT+=" | Themes: ${GREEN_BG}None${RSC}"
				fi

				_wp-updates-log "$OUTPUT"
				REPORT_LINE="$WP_PATH,$WP_DOMAIN,$WP_CORE_UPDATED,$WP_CORE_VER,$PLUGIN_UPDATE_COUNT,$THEME_UPDATE_COUNT"
				_wp-updates-report "$REPORT_LINE"
				TOTAL_WP_CORE_UPDATES_APPLIED=$(($TOTAL_WP_CORE_UPDATES_APPLIED + $WP_CORE_UPDATED))
				TOTAL_WP_PLUGIN_UPDATES_APPLIED=$(($TOTAL_WP_PLUGIN_UPDATES_APPLIED + $PLUGIN_UPDATE_COUNT))
				TOTAL_WP_THEME_UPDATES_APPLIED=$(($TOTAL_WP_THEME_UPDATES_APPLIED + $THEME_UPDATE_COUNT))

                ;;
            plugins)
				PLUGIN_UPDATES_ONLY=$(wp --allow-root plugin update --all --path="$WP_PATH" --skip-themes --skip-plugins --format=ids)
				PLUGIN_UPDATES_ONLY_COUNT=$(echo "$PLUGIN_UPDATES" | wc -w)
				echo "- UPDATE PLUGINS - Plugins: $PLUGIN_UPDATES_ONLY_COUNT"
				;;
			themes)
				THEME_UPDATES_ONLY=$(wp --allow-root theme update --all --path="$WP_PATH" --skip-themes --skip-plugins --format=ids)
				THEME_UPDATES_ONLY_COUNT=$(echo "$THEME_UPDATES" | wc -w)
				OUTPUT+="- UPDATE THEMES - Themes: $THEME_UPDATES_ONLY_COUNT"
				echo $OUTPUT
				;;
			core)
				CORE_UPDATES_ONLY=$(wp --allow-root core update --path="$WP_PATH" --quiet)
				OUTPUT+="- UPDATE CORE - Core: $CORE_UPDATES_ONLY"
				echo $OUTPUT
                ;;
            *)
				_wp-updates-usage
                ;;
        esac
    }

    # Find wp-config.php files and process each WordPress installations
	WP_SITE_PATHS=($(wp-find $SEARCH_PATH 1))
	if [[ $? == "1" ]]; then
		_wp-updates-log "$(_error "No WordPress installations found")"
		return 1
	else
		_wp-updates-log "$(_success "Found ${#WP_SITE_PATHS[@]} WordPress site(s)")"
	fi

	# -- Run a scan on each site
	for WP_SITE_PATH in ${WP_SITE_PATHS[@]}; do
        check_update_wp "$WP_SITE_PATH"
    done
	
	_wp-updates-log ">>>>>>>>>>>> SUMMARY <<<<<<<<<<<<" 1
	echo ""
	if [[ $ACTION == "list" ]]; then
		SUMMARY="Total WordPress sites: ${#WP_SITE_PATHS[@]}\n"
		SUMMARY+="Total WordPress core updates: $TOTAL_WP_CORE_UPDATES\n"
		SUMMARY+="Total WordPress plugin updates: $TOTAL_WP_PLUGIN_UPDATES\n"
		SUMMARY+="Total WordPress theme updates: $TOTAL_WP_THEME_UPDATES\n"
	elif [[ $ACTION == "update" ]]; then
		SUMMARY="Total WordPress sites: ${#WP_SITE_PATHS[@]}\n"
		SUMMARY+="Total WordPress core updates applied: $TOTAL_WP_CORE_UPDATES_APPLIED\n"
		SUMMARY+="Total WordPress plugin updates applied: $TOTAL_WP_PLUGIN_UPDATES_APPLIED\n"
		SUMMARY+="Total WordPress theme updates applied: $TOTAL_WP_THEME_UPDATES_APPLIED\n"
	else
		SUMMARY="Total WordPress sites: ${#WP_SITE_PATHS[@]}"
	fi
	_wp-updates-log $SUMMARY
	_wp-updates-log ">>>>>>>>>>>> SUMMARY <<<<<<<<<<<<" 1	

	_wp-updates-log ">>>>>>>>>>>> END OF RUN <<<<<<<<<<<<" 1
	_wp-updates-log ">>>>>>>>>>>> END OF RUN <<<<<<<<<<<<" 1
}

# =========================================================
# -- wp-delete-wp-themes
# =========================================================
help_wordpress[wp-delete-wp-themes]='Delete default WordPress themes'
function wp-delete-wp-themes () {
    # Path to the WordPress themes directory
	local SITE_PATH="$1"

	# -- Usage
	_wp-delete-wp-themes-usage () {
		echo "Usage: wp-delete-wp-themes [path]"
		return 1
	}
	# -- Print out action
	_loading "Deleting default WordPress themes on $SITE_PATH"

	# -- Check path exists and has wordpress installed
	if [[ -z $SITE_PATH ]]; then
		_wp-delete-wp-themes-usage
		return 1
	elif [[ ! -d $SITE_PATH ]]; then
		_error "Path $SITE_PATH doesn't exist"
		return 1
	fi

	# -- Check if WordPress is installed
	_loading "Checking if WordPress is installed in the $SITE_PATH directory"
	WP_EXISTS=$(wp core is-installed --path="$SITE_PATH" &>/dev/null)
	if [[ $? == 1 ]] ; then
		_error "WordPress is not installed in the $SITE_PATH directory."
		echo "$WP_EXISTS"
		return 1
	else
		_success "WordPress is installed in $SITE_PATH"
	fi

    # Get the current active theme by parsing the WordPress configuration
    local CURRENT_THEME=$(wp --allow-root theme list --status=active --field=name)

    # List all default WordPress themes except for 2023
    for theme in "$themes_dir"/twenty{ten,eleven,twelve,thirteen,fourteen,fifteen,sixteen,seventeen,eighteen,nineteen,twenty,twentyone,twentytwo}; do
		_loading2 "Checking theme: $(basename "$theme")"
        # Check if the theme exists and is not the current active theme
        if [[ -d "${SITE_PATH}/wp-content/themes/$theme" && $theme != "$CURRENT_THEME" ]]; then
            _loading3 "Deleting theme: $(basename "$theme")"
            wp --allow-root theme delete "$(basename "$theme")"
        fi
    done

    _success "Theme deletion completed."
}

# =========================================================
# -- wp-domain
# =========================================================
help_wordpress[wp-domain]='Get domain name from WordPress site'
function wp-domain () {
	local SITE_PATH="$1"
	if [[ -z $SITE_PATH ]]; then
		# Use current directory
		SITE_PATH=$(pwd)
	fi
	if [[ ! -d $SITE_PATH ]]; then
		echo "Path $SITE_PATH doesn't exist"
		return 1
	fi
	if ! wp core is-installed --path="$SITE_PATH" &>/dev/null; then
		echo "WordPress is not installed in the $SITE_PATH directory."
		return 1
	fi
	wp --allow-root option get siteurl --path="$SITE_PATH"
}

# =========================================================
# -- wp-plugin-install
# =========================================================
help_wordpress[wp-plugin-install]='Install WordPress plugin'
function wp-plugin-install () {
	local PLUGIN_NAME="$1"
	local SITE_PATH="$2"
	if [[ -z $PLUGIN_NAME ]]; then
		echo "Usage: wp-plugin-install <plugin-name> [path]"
		return 1
	fi
	if [[ -z $SITE_PATH ]]; then
		# Use current directory
		SITE_PATH=$(pwd)
	fi
	if [[ ! -d $SITE_PATH ]]; then
		echo "Path $SITE_PATH doesn't exist"
		return 1
	fi
	if ! wp core is-installed --path="$SITE_PATH" &>/dev/null; then
		echo "WordPress is not installed in the $SITE_PATH directory."
		return 1
	fi


	_loading "Installing $PLUGIN_NAME in $SITE_PATH"
	# -- Install plugin
	_loading3 "Running - wp --allow-root plugin install $PLUGIN_NAME --path=$SITE_PATH --activate"
	wp --allow-root plugin install "$PLUGIN_NAME" --path="$SITE_PATH" --activate
	# -- Chown the plugin directory in $SITE_PATH to the wp-content/plugins user and group
	# Get the user and group of the wp-content directory
	local WP_CONTENT_USER=$(stat -c '%U' "$SITE_PATH/wp-content")
	local WP_CONTENT_GROUP=$(stat -c '%G' "$SITE_PATH/wp-content")
	# Chown the plugin directory to the user and group of the wp-content directory
	_loading3 "Running - chown -R $WP_CONTENT_USER:$WP_CONTENT_GROUP $SITE_PATH/wp-content/plugins/$PLUGIN_NAME"
	chown -R "$WP_CONTENT_USER:$WP_CONTENT_GROUP" "$SITE_PATH/wp-content/plugins/$PLUGIN_NAME"

}

# =========================================================
# -- wp-list-transients
# =========================================================
help_wordpress[wp-list-transients]='List all transients in wp_options table'
function wp-list-transients () {
	local SITE_PATH="$1"
	if [[ -z $SITE_PATH ]]; then
		# Use current directory
		SITE_PATH=$(pwd)
	fi
	if [[ ! -d $SITE_PATH ]]; then
		echo "Path $SITE_PATH doesn't exist"
		return 1
	fi
	if ! wp core is-installed --path="$SITE_PATH" &>/dev/null; then
		echo "WordPress is not installed in the $SITE_PATH directory."
		return 1
	fi
	_loading "Listing transients in $SITE_PATH"
	wp --allow-root transient list --path="$SITE_PATH"
}

# =========================================================
# -- wp-delete-transients
# =========================================================
help_wordpress[wp-delete-transients]='Delete all transients in wp_options table'
function wp-delete-transients () {
	local SITE_PATH="$1"
	if [[ -z $SITE_PATH ]]; then
		# Use current directory
		SITE_PATH=$(pwd)
	fi
	if [[ ! -d $SITE_PATH ]]; then
		echo "Path $SITE_PATH doesn't exist"
		return 1
	fi
	if ! wp core is-installed --path="$SITE_PATH" &>/dev/null; then
		echo "WordPress is not installed in the $SITE_PATH directory."
		return 1
	fi
	_loading "Deleting transients in $SITE_PATH"
	wp --allow-root transient delete --all --path="$SITE_PATH"
}

# =========================================================
# -- wp-list-transients-duplicate
# =========================================================
help_wordpress[wp-list-transients-duplicate]='List duplicate transients in wp_options table'
function wp-list-transients-duplicate () {
	local SITE_PATH="$1"
	if [[ -z $SITE_PATH ]]; then
		# Use current directory
		SITE_PATH=$(pwd)
	fi
	if [[ ! -d $SITE_PATH ]]; then
		echo "Path $SITE_PATH doesn't exist"
		return 1
	fi
	if ! wp core is-installed --path="$SITE_PATH" &>/dev/null; then
		echo "WordPress is not installed in the $SITE_PATH directory."
		return 1
	fi
	_loading "Listing duplicate transients in $SITE_PATH"
	wp --allow-root db query "SELECT LEFT(option_name, LENGTH(option_name) - LOCATE('_', REVERSE(option_name))) AS base_option_name,
COUNT(*) AS duplicate_count
FROM wp_options
WHERE option_name LIKE '_transient_%' 
   OR option_name LIKE '_transient_timeout_%'
GROUP BY base_option_name
ORDER BY duplicate_count DESC;"

}

# =========================================================
# -- wp-user-count
# =========================================================
help_wordpress[wp-user-count]='Count users in wp_users table'
function wp-user-count () {
	local SITE_PATH="$1"
	[[ -z $SITE_PATH ]] && SITE_PATH=$(pwd)
	[[ ! -d $SITE_PATH ]] && { echo "Path $SITE_PATH doesn't exist"; return 1; }
	
	# Check if WordPress is installed using wp-cli
	_wp-install-check $SITE_PATH
	if [[ $? == 0 ]]; then
		_loading "Counting users in $SITE_PATH"
		# Use mysql
		USER_COUNT=$(wp db query "SELECT COUNT(*) FROM wp_users" --path="$SITE_PATH" --skip-plugins --skip-themes --skip-column-names)
		echo "User count: $USER_COUNT"
	else
		echo "WordPress is not installed in the $SITE_PATH directory."
		return 1
	fi
}