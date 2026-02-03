_debug " -- Loading ${(%):-%N}"
help_files[misc]='Miscellaneous commands'
typeset -gA help_misc

# -- speedtest-cli - find what's using swap.
help_misc[words]="Random 5 words"
function words () {
    sort -R /usr/share/dictd/wn.index | awk 'NR <= 15 { print $1 }'
}
