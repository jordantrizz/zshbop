# -- python commands
_debug " -- Loading ${(%):-%N}"
typeset -gA help_python
help_files[python]="Python commands"


# --------------------------------------------------
# -- python-clean
# --------------------------------------------------
help_python[python-clean]='Clean python cache files'
function python-clean () {
        find . -type f -name "*.py[co]" -delete
        find . -type d -name "__pycache__" -delete
}