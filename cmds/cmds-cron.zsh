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

help_cron[cron-list]="List all crons"
function cron-list () {
    FULL_OUTPUT=""
    FINAL_OUTPUT=""

    # -- Ensure the script is run as root
    if [[ $EUID -ne 0 ]]; then
        echo "This script must be run as root"
        exit 1
    fi

    # -- Check if requesting full output
    if [[ $1 == "full" ]]; then
        FULL_OUTPUT="1"
    fi

    # -- List system-wide crontabs
    CRON_SYSTEM_OUTPUT="$(_loading "Listing /etc/crontab")\n"
    CRON_SYSTEM_OUTPUT+="$(cat /etc/crontab)\n"
    FINAL_OUTPUT+="$CRON_SYSTEM_OUTPUT\n\n"

    # List crontabs in cron.d directory
    CRON_CROND_OUTPUT="$(_loading "Crontabs in /etc/cron.d*")\n"
    CRON_DIRS=($(find /etc/cron.* -type d))
    for CRON_DIR in $CRON_DIRS; do
        CRON_CROND_OUTPUT+="$(_loading "Crontab directory ${CRON_DIR}:")\n"
        CRONS_CROND=($(\ls -L ${CRON_DIR}))
        for CRON in ${CRONS_CROND[@]}; do
            CRON_CROND_OUTPUT+="$(_loading2 "Crontab for ${CRON_DIR}/${CRON}:")\n"
            if [[ $FULL_OUTPUT == "1" ]]; then
                CRON_CROND_OUTPUT+="$(cat ${CRON_DIR}/${CRON})\n"
                CRON_CROND_OUTPUT+="----------------------------------------------------------\n"
            fi
        done
    done
    FINAL_OUTPUT+="$CRON_CROND_OUTPUT\n\n"

    # List user-specific crontabs
    CRON_USER_OUTPUT=""
    CRON_USER_OUTPUT+="$(_loading "User-specific crontabs:")\n"
    for user in $(cut -f1 -d: /etc/passwd); do
        CRON_USER_OUTPUT+=$(_loading2 "Crontab for $user:\n")
        CRON_USER_OUTPUT+="$(crontab -l -u $user 2>&1)\n"
    done
    FINAL_OUTPUT+="${CRON_USER_OUTPUT}\n\n"

    FINAL_OUTPUT+="\nIf you want to see the full output of cron.d* files type 'cron-list full'\n"
    echo $FINAL_OUTPUT | less
}