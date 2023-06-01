# -- WordPress
_debug " -- Loading ${(%):-%N}"
help_files[wordpress]='WordPress related commands'
typeset -gA help_wordpress

# -- wp-cli but allow root ;)
help_wordpress[wp]='Run wp-cli with --allow-root'
alias wp="wp --allow-root"

# -- wp-db
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
wp-backupsite () {
    if [[ -z $1 ]]; then
        echo "Usage: wp-backupsite <domain>"
        echo "  Make sure you're in the wordpress directory, and have wp-cli installed"
        return 1
    fi
    SITE="$1"

    WP_CHECK=$(wp --allow-root core is-installed)
    if [[ $? == "1" ]]; then
        _error "$WP_CHECK"
    fi

    if [[ ! -d $HOME/backups ]]; then
        echo "$HOME/backups directory doesn't exist...creating..."
        mkdir $HOME/backups
    fi

    echo "Backing up ${SITE}..."
    /usr/local/bin/wp --allow-root db export - | gzip > ${HOME}/backups/db_${SITE}-$(date +%Y-%m-%d-%H%M%S).sql.gz
    tar --create --gzip --absolute-names --file=${HOME}/backups/wp_${SITE}-$(date +%Y-%m-%d-%H%M%S).tar.gz --exclude='*.tar.gz' --exclude='*.zip'--exclude='wp-content/cache' --exclude='wp-content/ai1wm-backups' .
}

# -- wp-skip
help_wordpress[wp-admin-email]='Update admin email'
function wp-admin-email () {
    [[ -z $1 ]] && { echo "Usage: wp-admin-email <email>"; return 1 } || wp option update admin_email ${1}
    
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

# -- wp-cli-install
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

# -- wp-profile
help_wordpress[wp-profile]='Install wp-cli-profile-command module'
function wp-profile () {
    wp package install wp-cli/profile-command
}

# -- wp-find
help_wordpress[wp-find]='Find WordPress instances'
function wp-find () {
	echo "Install wp-cli find-command"
	echo "wp package install wp-cli/find-command:@stable"
}

# -- wp-find2
help_wordpress[wp-find2]='Find WordPress instances'
function wp-find2 () {
	if [[ -z $1 ]]; then
		echo "Usage: wp-find <directory>"
		echo "  Make sure you're in the wordpress directory, and have wp-cli installed"
		return 1
	fi
	DIR="$1"

	WP_CHECK=$(wp --allow-root core is-installed)
	if [[ $? == "1" ]]; then
		_error "$WP_CHECK"
	fi

	echo "Finding WordPress instances in ${DIR}..."
	find ${DIR} -type f -name 'wp-config.php' -exec grep -H 'DB_NAME' {} \;
}

# -- wp-find-check
help_wordpress[wp-find-check]='Find WordPress instances and check for core file changes'
function wp-find-check () {
	if [[ -z $1 ]]; then
		echo "Usage: wp-find-check <path> [verbose]"
		return 1
	else
		# -- Check if wp-cli is installed
		_cexists wp
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