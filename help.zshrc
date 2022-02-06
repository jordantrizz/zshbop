# ----------------------------------------------
# -- help function and it's associated functions
# ----------------------------------------------
#
# The following script handles all of the help information for fucntions and scripts added throughout.
#
# - To add command help, which is a file within this repostiryo and not a function.
#
# 	help_mysql[maxmysqlmem]='Calculate maximum MySQL memory'
#

# -- Help header
help_sub_header () {
		echo "----------------------"
                echo "-- $HCMD"
                echo "----------------------"
}

# -- Help
help () {
        HCMD=$@
        if [ ! $1 ]; then
        	help_intro
        else
                if [ "$HCMD" = "all" ]; then
                	help_core
                	help_mysql
                	help_ssh
                	help_wordpress
                	help_other
                elif [ "$HCMD" = "core" ]; then help_core;
                elif [ "$HCMD" = "mysql" ]; then help_mysql;
                elif [ "$HCMD" = "ssh" ]; then help_ssh;
                elif [ "$HCMD" = "wordpress" ]; then help_wordpress;
                elif [ "$HCMD" = "php" ]; then help_php;
                elif [ "$HCMD" = "other" ]; then help_other;
                else
                	echo "No command category $HCMD, try running kb $HCMD"
                	return
                fi                
        fi
}

# -- Help introduction
help_intro () {
	echo "-----------------------------"
	echo "-- General help for $SCRIPT_NAME --"
        echo "-----------------------------"
        echo ""
        echo "ZSHBop contains a number of built-in functions, scripts and binaries."
        echo ""
        echo "This help command will list all that are available."
        echo ""
        echo "--------------------"
        echo "-- Help Commands --"
        echo "--------------------"
        echo ""
        echo " kb 		- Knowledge Base"
        echo " help 		- this command"
	echo ""
	echo "------------------------"
	echo "-- Command Categories --"
        echo "------------------------"
	echo ""
	printf '%-25s %s\n' " help all" "- List all possible commands."
	printf '%-25s %s\n' " help core" "- List core ZSHbop commands."
	printf '%-25s %s\n' " help mysql" "- List mysql commands."
	printf '%-25s %s\n' " help ssh" "- List ssh commands."
	printf '%-25s %s\n' " help wordpress"	"- List WordPress commands."
	printf '%-25s %s\n' " help php" "- List PHP commands."
	printf '%-25s %s\n' " help other" "- List other commands."
	echo ""
	echo "---------------"
        echo "-- Examples --"
        echo "---------------"
        echo "$> help mysql"
        echo "$> help tools"
        echo ""

}
# -- Core commands
help_core () {
        echo " -- Core ------------------------------------------------------------"
        for key value in ${(kv)help_core}; do
                printf '%s\n' "  ${(r:25:)key} - $value"
        done
}

# -- MySQL commands
help_mysql () {
        echo " -- MySQL ------------------------------------------------------------"
        for key value in ${(kv)help_mysql}; do
		printf '%s\n' "  ${(r:25:)key} - $value"
        done
}

# -- SSH
help_ssh () {
        echo " -- SSH ------------------------------------------------------------"
        for key value in ${(kv)help_ssh}; do
		printf '%s\n' "  ${(r:25:)key} - $value"
        done
}

# -- WordPress
help_wordpress () {
        echo " -- WordPress ------------------------------------------------------------"
        for key value in ${(kv)help_wordpress}; do
		printf '%s\n' "  ${(r:25:)key} - $value"
        done
}

# -- PHP
help_php () {
        echo " -- PHP ------------------------------------------------------------"
        for key value in ${(kv)help_php}; do
                printf '%s\n' "  ${(r:25:)key} - $value"
        done
}

# -- Other
help_other () {
        echo " -- Other ------------------------------------------------------------"
        for key value in ${(kv)help_other}; do
		printf '%s\n' "  ${(r:25:)key} - $value"
        done
}