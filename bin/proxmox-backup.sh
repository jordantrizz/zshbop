#!/bin/bash

# ------------
# -- Variables
# ------------
VERSION=0.0.1
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
DEBUG="0"

# -- Colors
RED="\033[0;31m"
GREEN="\033[0;32m"
CYAN="\033[0;36m"
BLUEBG="\033[0;44m"
YELLOWBG="\033[0;43m"
GREENBG="\033[0;42m"
DARKGREYBG="\033[0;100m"
ECOL="\033[0;0m"

# -- script variables
BACKUP_DIR=~/proxmox-backup
DATE=`date +"%Y-%m-%d-%H_%M_%S"`

# -------
# -- Help
# -------
USAGE=\
"$0 <backp|help>

  backup        - Backup proxmox configuration
  help          - This help screen

Version: $VERSION
"
usage () { echo "$USAGE"; }

# ------------
# -- Functions
# ------------

# -- _error
_error () {
    echo -e "${RED}** ERROR ** - $@ ${ECOL}"
}
# -- _success
_success () {
    echo -e "${GREEN}** SUCCESS ** - $@ ${ECOL}"
}

if [[ -z $1 ]]; then
	usage
	exit 1
else
	echo " * Starting backup at ${BACKUP_DIR}/${DATE}"
	mkdir ${BACKUP_DIR}/${DATE}
	if [[ $? -ge 1 ]]; then
		_error "Cloudn't create diretory ${BACKUP_DIR}/${DATE}"
		exit 1
	else
		cp -R /etc/pve/nodes/* ${BACKUP_DIR}/${DATE}
		if [[ $? -ge 1 ]]; then
			_error "Cloudn't copy /etc/pve/nodes/* to ${BACKUP_DIR}/${DATE}"
			exit 1
		else
			_success "Copy completed to ${BACKUP_DIR}/${DATE}"
		fi
	fi
fi
