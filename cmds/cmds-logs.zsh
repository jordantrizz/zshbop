# --
# log commands
#
# Example help: help_template[test]='Generate phpinfo() file'
#
# --
_debug " -- Loading ${(%):-%N}"

# What help file is this?
help_files[logs]="Commands for dealing with logs."

# - Init help array
typeset -gA help_logs

_debug " -- Loading ${(%):-%N}"

# -- maldet-log
help_logs[maldet-log]='Print out maldet scans from log file in a single line.'
maldet-scans () {
    if [[ -f /usr/local/maldetect/logs/event_log ]]; then
        MALDET_LOG_FILE="/usr/local/maldetect/logs/event_log"
        grep 'scan completed on' ${MALDET_LOG_FILE}
    else
        _error "Couldn't access maldet file at ${MALDET_LOG_FILE}" 0
        return 1
    fi    
}