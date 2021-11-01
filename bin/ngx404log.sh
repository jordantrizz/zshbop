#!/usr/bin/env zsh
nginx-log-404 () {
        local CAT
        local EGREP
        local FULLCMD
        if [ -z $1 ]; then
                echo "./$0 <logfile> <type> <strip>"
                echo ""
                echo "All arguments are required execpt for <strip>"
                echo ""
                echo "  <logfile> is a nginx log file."
                echo "  <type> (n)ginx or (g)ridpane"
                echo "  <strip> is a list of file excludes"
                echo ""
                echo "  example: ./$0 access_log n '.js|.css'"
        else
                if [[ $1 == *.gz ]]; then CAT="zcat"; else CAT="cat"; fi
                if [ ! -z $3 ]; then
                        FULLCMD="$CAT $1 | egrep -v '$3'"
                else
                        FULLCMD="$CAT $1"
                fi
                if [ $3 == "n" ]; then
                        eval $FULLCMD | awk '($8 ~ /404/)' | awk '{print $8}' | sort | uniq -c | sort -rn
                elif [ $3 == "g"]; then
                        eval $FULLCMD | awk '($10 ~ /404/)' | awk '{print $8}' | sort | uniq -c | sort -rn
                fi
        fi
}