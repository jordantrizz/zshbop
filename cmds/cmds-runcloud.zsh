# --
# template commands
#
# Example help: help_template[test]='Generate phpinfo() file'
#
# --
_debug " -- Loading ${(%):-%N}"

# What help file is this?
help_files[runcloud]="Common Runcloud Tools"

# - Init help array
typeset -gA help_runcloud

# -- gp-backupallsites
help_runcloud[runcloud-backupallsites]="Backup all sites on server to ~/backups"
runcloud-backupallsites () {
    echo "Not working"
    return 1
    if [[ ! -d $HOME/backups ]]; then
        echo "$HOME/backups directory doesn't exist...creating..."
        mkdir $HOME/backups
    fi
    for SITE in ${(f)SITES}; do
        echo "Backing up ${SITE}..."
        /usr/local/bin/wp --allow-root --path=/var/www/${SITE}/htdocs db export - | gzip > ${HOME}/backups/db_${SITE}-$(date +%Y-%m-%d-%H%M%S).sql.gz
        tar --create --gzip --absolute-names --file=${HOME}/backups/wp_${SITE}-$(date +%Y-%m-%d-%H%M%S).tar.gz --exclude='*.tar.gz' --exclude='*.zip'--exclude='wp-content/cache' --exclude='wp-content/ai1wm-backups' /var/www/${SITE}/htdocs
    done
}
