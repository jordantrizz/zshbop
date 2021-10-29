#!/usr/bin/env zsh

# --- General WordPress Functions

wp-help () {
	echo " -- Welcome, this is currently a use at your own risk function"
}

# --- WordPress Alias
wp-db () {
	if [ -f wp-config.php ]; then
		grep 'DB' wp-config.php
	elif [ -f ../wp-config.php ]; then
		grep 'DB' ../wp-config.php
	fi
}

# --- WordPress functions
wp-posttable () {
	if [ -z $1 ]; then echo "Need database name. wp-posttable <dbname>";
	else mysql $1 -e "SELECT post_type,COUNT(*) FROM wp_posts GROUP BY post_type ORDER BY COUNT(*) DESC;"; fi		
}
