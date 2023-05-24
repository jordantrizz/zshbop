# -- gp-motd
help_gridpane[motd_gp]="GridPane MOTD"
motd_gp () {
    # -- monit logs, grab last 10 warnings and errors
    _loading2 "Last 5 monit warnings and errors"
    egrep -i ' warning | error ' /var/log/monit.log | tail -5

    _loading2 "Last 5 Maldet scans"
    maldet-scans | tail -5

    # -- gp-oscheck
    _loading2 "Checking OS"    
    gp-oscheck

    # -- inform
    _notice "View more GridPane logs with the command gp-logs"

    _loading "End GP MOTD - run gp-audit"
    echo ""

}