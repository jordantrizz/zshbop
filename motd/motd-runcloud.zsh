# -- motd-runcloud
help_runcloud[motd-runcloud]="Runcloud MOTD"
motd_gp () {
    _loading2 "The last 10 lines from /var/log/runcloud.log"
    cat /var/log/runcloud.log | tail -10

    _loading2 "Common Locations"
    echo "** Logs **"
    echo "/var/log/lsws-rc/runcloud"
    echo "/var/log/runcloud.log"
    echo ""
    echo "** Sites **"
    echo "/home/runcloud/webapps"

}