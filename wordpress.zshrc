#!/usr/bin/env zsh

# --- General WordPress Functions

alias wp="wp --allow-root"

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
wp-posts () {
	if [ -z $1 ]; then 
		echo "$0 <dbname>";
		echo ""
		echo "example: wp-posts database"		
	else 
		mysql $1 -e "SELECT post_type,COUNT(*) FROM wp_posts GROUP BY post_type ORDER BY COUNT(*) DESC;"; 
	fi	
}

