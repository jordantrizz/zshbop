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
    awk '/HOST:/ { host=$2 } /STARTED:/ { started=$2 } /ELAPSED:/ { elapsed=$2 } /TOTAL HITS:/ { hits=$3 }  { print " Host: "host " Started: " started " Elapsed: " elapsed " Hits: " hits }' /opt/gridpane/maldet-all-sites-scan.log | tail -10
}


