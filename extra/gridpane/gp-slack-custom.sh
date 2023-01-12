#!/bin/bash
#
# Usage: gp-slack-custom.sh <slack message title>
#

# - source GridPane
source "/usr/local/bin/lib/gridpane.sh" # - Contains lots of GridPane functions
gridpane::setglobals # - Needed for gridpane::notify:slack

# - Slack message
slack_type="error" # can be warning or error and maybe success?
title="$1" # slack title
slack_details="Server Name: ${host}{{newline}}Server IP: ${serverIP}{{newline}} $MONIT_EVENT" # full details for slack message
event_type="sys_load_avg" # Used because the API won't accept anything but specific event_types

# - send slack
preemptive_support="false"
      gridpane::notify::slack \
        "${slack_type}" \
        "${title}" \
        "${slack_details}" \
        "${event_type}" \
        "${preemptive_support}"
