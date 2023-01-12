#!/bin/bash

# - source GridPane
source "/usr/local/bin/lib/gridpane.sh"
gridpane::setglobals

# - configure message
slack_type="error"
title="$1"
slack_details="Server Name: ${host}{{newline}}Server IP: ${serverIP}{{newline}} $MONIT_EVENT - $MONIT_DESCRIPTION"
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
