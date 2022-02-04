# --
# WordPress commands
# --
_debug " -- Loading ${(%):-%N}"

# - Init help array
typeset -gA help_wordpress

# -- wp-cli but allow root ;)
help_wordpress[wp]='Generate phpinfo() file'
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

# --- wp-countposts
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

