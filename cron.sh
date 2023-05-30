#!/bin/bash
# -- Created by jordantrizz -- Version 0.0.1
# -- Purpose: Run cron and log the output to stdout, syslog, or a file.
# -- Usage: Add the following to your crontab
# */5 * * * * /home/systemuser/cron.sh

# Important Variables
SCRIPT_DIR=$(dirname "$(realpath "$0")")
CRON_CMD=""

# Settings
LOG_TO_STDOUT="1" # - Log to stdout? 0 = no, 1 = yes
LOG_TO_SYSLOG="1" # - Log to syslog? 0 = no, 1 = yes
LOG_TO_FILE="0" # - Log to file? 0 = no, 1 = yes
LOG_FILE="/home/app.goodmorningleland.com/wordpress-crons.log" # Location for wordpress cron.
HEARTBEAT_URL="https://uptime.betterstack.com/api/v1/heartbeat/qemxv615Fi8DUjAhzakbdCnE" # - Heartbeat monitoring URL
POST_CRON_CMD="" # - Command to run after cron completes

# Log the start time
START_TIME=$(date +%s.%N)

# Run WordPress crons due now and log the output
CRON_OUTPUT=$(eval $CRON_CMD)

# Check if there was an error running wp-cli command
if [[ $? -ne 0 ]]; then
    echo "Error: $CRON_CMD - command failed" >&2
    echo "$CRON_OUTPUT"
    if [[ -n "$POST_CRON_CMD" ]]; then
        eval "$POST_CRON_CMD"
    fi
    exit 1
fi

# Check if heartbeat monitoring is enabled and send a request to the heartbeat URL if it is and there are no errors
if [[ -n "$HEARTBEAT_URL" ]] && [[ $? -eq 0 ]] ; then
    curl -I -s "$HEARTBEAT_URL" > /dev/null
fi

# Log the end time and CPU usage
END_TIME=$(date +%s.%N)

# check if bc installed otherwise use awk
if [[ $(command -v bc) ]]; then
    TIME_SPENT=$(echo "$END_TIME - $START_TIME" | bc)
else
    TIME_SPENT=$(echo "$END_TIME - $START_TIME" | awk '{printf "%f", $1 - $2}')
fi
CPU_USAGE=$(ps -p $$ -o %cpu | tail -n 1)

# Check if logging to syslog is enabled
if [[ $LOG_TO_STDOUT == "1" ]]; then
    echo -e "Cron job completed in $TIME_SPENT seconds with $CPU_USAGE% CPU usage. \nOutput: $CRON_OUTPUT"
elif [[ $LOG_TO_SYSLOG == "1" ]]; then
    echo -e "Cron job completed in $TIME_SPENT seconds with $CPU_USAGE% CPU usage. \nOutput: $CRON_OUTPUT" | logger -t "cron-script"
elif [[ $LOG_TO_FILE == "1" ]]; then
    # Log to file in the WordPress install directory
    echo "$(date +"%Y-%m-%d %H:%M:%S") - Cron completed in $TIME_SPENT seconds with $CPU_USAGE% CPU usage. \nOutput: $CRON_OUTPUT" >> $LOG_FILE
fi
