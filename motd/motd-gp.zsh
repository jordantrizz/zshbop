# -- gp-motd
help_gridpane[motd_gp]="GridPane MOTD"
motd_gp () {
    # -- monit logs, grab last 10 warnings and errors
    _loading2 "Last 10 monit warnings and errors"
    egrep -i ' warning | error ' /var/log/monit.log | tail -10

    _loading2 "Last 5 Maldet scans"
    maldet-scans | tail -5

    # -- inform
    _notice "View more GridPane logs with the command gp-logs"
}