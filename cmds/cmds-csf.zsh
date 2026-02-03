# =============================================================================
# csf commands
# =============================================================================
# Example help: help_template[test]='Generate phpinfo() file'
_debug " -- Loading ${(%):-%N}"
help_files[csf]="CSF Commands and scripts"
typeset -gA help_csf
_debug " -- Loading ${(%):-%N}"


# ===============================================
# -- lfd-restart
# ===============================================
help_csf[lfd-restart]="Restart the lfd service"
lfd-restart () {
    sudo csf --lfd restart
}
