#!/bin/bash
# -- Created by jordantrizz -- Version 0.0.1
# -- Purpose: Run cron and log the output to stdout, syslog, or a file.
# -- Usage: Add the following to your crontab
# */5 * * * * /home/systemuser/cron.sh

# Important Variables
SCRIPT_DIR=$(dirname "$(realpath "$0")")
CRON_CMD="/usr/sbin/php /home/systemuser/test.php"

# Settings
LOG_TO_STDOUT="1" # - Log to stdout? 0 = no, 1 = yes
LOG_TO_SYSLOG="1" # - Log to syslog? 0 = no, 1 = yes
LOG_TO_FILE="1" # - Log to file? 0 = no, 1 = yes
LOG_FILE="/home/systemuser/cron.log" # Location for wordpress cron.
HEARTBEAT_URL="https://uptime.betterstack.com/api/v1/heartbeat/qwceqweqwe" # - Heartbeat monitoring URL
POST_CRON_CMD="" # - Command to run after cron completes

# ------------------
# --- Start Cron Job
# ------------------

# Log the start time
START_TIME=$(date +%s.%N)

# Log header
LOG="==================================================
== Cron job start $(echo $START_TIME|date +"%Y-%m-%d %H:%M:%S")
==================================================
"

# Run $CRON_CMD
CRON_OUTPUT="$(eval $CRON_CMD)"
LOG+="$CRON_OUTPUT"

# Check if there was an error running $CRON_CMD
if [[ $? -ne 0 ]]; then
    LOG+="Error: $CRON_CMD - command failed" >&2
    LOG+="$CRON_OUTPUT"
    if [[ -n "$POST_CRON_CMD" ]]; then
        eval "$POST_CRON_CMD"
    fi
else
	# Check if heartbeat monitoring is enabled and send a request to the heartbeat URL if it is and there are no errors
	if [[ -n "$HEARTBEAT_URL" ]] && [[ $? -eq 0 ]] ; then
    	curl -I -s "$HEARTBEAT_URL" > /dev/null
    	LOG+="\n==== Sent Heartbeat to $HEARTBEAT_URL"
	fi

	# Log the end time and CPU usage
	END_TIME=$(date +%s.%N)

	# check if bc installed otherwise use awk
	if [[ $(command -v bc) ]]; then
	    TIME_SPENT=$(echo "$END_TIME - $START_TIME" | bc)
	else
	    TIME_SPENT=$(echo "$END_TIME - $START_TIME" | awk '{printf "%f", $1 - $2}')
	fi
	# Get CPU Usage
	CPU_USAGE=$(ps -p $$ -o %cpu | tail -n 1)

	# POST_CRON_CMD
	if [[ -n "$POST_CRON_CMD" ]]; then
        LOG+="$(eval "$POST_CRON_CMD")"
    fi

	# Write cron job completed time and cpu usage.

fi

LOG+="\n===============================================
== Cron job completed in $TIME_SPENT seconds with $CPU_USAGE% CPU usage.
===============================================
== Cron job End - $(echo $END_TIME | date +"%Y-%m-%d %H:%M:%S")
===============================================
"

# --------------
# --- Logging
# --------------

# Check if logging to stdout is enabled
[[ $LOG_TO_STDOUT == "1" ]] && { echo -e "$LOG"; }
# Check if logging to syslog is enabled
[[ $LOG_TO_SYSLOG == "1" ]] && { echo -e "$LOG" | logger -t "cron-script"; }
# Check if logging to log file is enabled
[[ $LOG_TO_FILE == "1" ]] && { echo -e "$LOG" >> $LOG_FILE; }
