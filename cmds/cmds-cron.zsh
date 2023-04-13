# --
# cron
# --
_debug " -- Loading ${(%):-%N}"
help_files[cron]="Cron specific commands" # Help file description
typeset -gA help_cron # Init help array.

# -- cron-list-users
help_cron[cron-list-users]="List user crons"
function cron-list-users() {
    for user in /var/spool/cron/*(N); do
        echo "Crons for user ${user:t}:"
        cat $user
        echo ""
    done
}


