#!/bin/bash

# - source GridPane
source "/usr/local/bin/lib/gridpane.sh"
gridpane::setglobals

# - configure message
slack_type="error"
title="$1"
error_message="$2"
slack_details="Server Name: ${host}{{newline}}Server IP: ${serverIP}{{newline}} $error_message"
echo $slack_details
event_type="sys_load_avg"

# - send slack
preemptive_support="false"
      gridpane::notify::slack \
        "${slack_type}" \
        "${title}" \
        "${slack_details}" \
        "${event_type}" \
        "${preemptive_support}"
