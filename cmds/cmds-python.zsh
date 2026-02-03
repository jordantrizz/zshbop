# =============================================================================
# -- python commands
# =============================================================================
_debug " -- Loading ${(%):-%N}"
typeset -gA help_python
help_files[python]="Python commands"


# ===============================================
# -- python-clean
# ===============================================
help_python[python-clean]='Clean python cache files'
function python-clean () {
    find . -type f -name "*.py[co]" -delete
    find . -type d -name "__pycache__" -delete
}

# ===============================================
# -- python-venv
# ===============================================
help_python[python-venv]='Create a python virtual environment in the current directory'
function python-venv () {
    python3 -m venv venv
    source venv/bin/activate
}

