# --
# cron
# --
_debug " -- Loading ${(%):-%N}"
help_files[cron]="Cron specific commands" # Help file description
typeset -gA help_cron # Init help array.

# -- cron-list-users
help_cron[cron-list-users]="List user crons"
function cron-list-users() {
    if [[ -d /var/spool/cron/crontabs/ ]]; then
        CRON_SPOOL="/var/spool/cron/crontabs/"
    elif [[ -d /var/spool/cron/ ]]; then
        CRON_SPOOL="/var/spool/cron/"
    else
        _error "No cron spool folder found"
        return 1
    fi

    for user in ${CRON_SPOOL}*(N); do

        _loading "Crons for user ${user:t}: in ${CRON_SPOOL}${user:t}:"
        cat $user | grep -v "#"
        echo "----------------------------------------------------"
    done
}


