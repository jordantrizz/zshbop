#!/usr/bin/env zsh

# --- WordPress functions
wp-posttable () {
	if [ -z $1 ]; then echo "Need database name. wp-posttable <dbname>";
	else mysql $1 -e "SELECT post_type,COUNT(*) FROM wp_posts GROUP BY post_type ORDER BY COUNT(*) DESC;"; fi		
}