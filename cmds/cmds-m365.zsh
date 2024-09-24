# --
# powershell commands
# --
_debug " -- Loading ${(%):-%N}"

# What help file is this?
help_files[powershell]="Powershell commands"

# - Init help array
typeset -gA help_powershell

_debug " -- Loading ${(%):-%N}"

# ===============================================
# -- m365-add-email
# ===============================================
help_powershell[m365-add-email]='Add an email to a Microsoft 365 account.'
m365-add-email () {
    m365_add_email_usage () {
        echo "Usage: m365-add-email [-e <email>|-d <domain>] [-u <username>|-all]"
    }
}