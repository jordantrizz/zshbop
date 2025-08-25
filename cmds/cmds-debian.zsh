# -- debian Commands
_debug " -- Loading ${(%):-%N}"
typeset -gA help_debian
help_debian[debian-fixes]='Fix common issues on Debian based systems'

# ==================================================
# -- debian-locale-fix
# ==================================================
help_debian[debian-locale-fix]='Fix locale issues on Debian based systems'
debian-locale-fix () {
    # generate and add en_US.UTF-8 UTF-8 for debian
    echo "en_US.UTF-8 UTF-8" | sudo tee -a /etc/locale.gen    
    sudo locale-gen en_US.UTF-8    
}