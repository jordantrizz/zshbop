#!/bin/bash 
 
# Name: Check for domain name availability 
# linuxconfig.org 
# Please copy, share, redistribute and improve 
# https://linuxconfig.org/check-domain-name-availability-with-bash-and-whois

# -- Variables
RED='\033[41m'
GREEN='\033[42;5;30m'
NC='\033[0m' # No Color

usage () {
	echo "Usage: domaincheck (domain.ext|-a domain)"
	echo "Check if a domain name is available. Enter in the full domain name"
	echo "   -a    - check all domain extensions, just enter the first part"
	echo ""
}

check_domain () {
	whois $1 | egrep -q '^No match|^NOT FOUND|^Not fo|AVAILABLE|^No Data Fou|has not been regi|No entri'
	if [ $? -eq 0 ]; then
		echo -e "$1${DOMAINS[${i}]} : ${GREEN} > available < ${NC}"
	else
		echo -e "$1${DOMAINS[${i}]} : ${RED}X unavailable X ${NC}"
	fi
      
}

DOMAIN="$1"
#echo "Running $@"
 
if [[ -z $@ ]]; then 
	usage
    exit 1
fi

echo "-- Running on $@"

if [[ $1 == "-a" ]]; then
	CHECK_DOMAIN="2"
	DOMAIN_EXTS=( '.com' '.co.uk' '.net' '.info' '.mobi' \ 
	'.org' '.tel' '.biz' '.tv' '.cc' '.eu' '.ru' \ 
	'.in' '.it' '.sk' '.com.au' )
else
	CHECK_DOMAIN="1"
fi

if [[ $CHECK_DOMAIN == "1" ]]; then
	echo "Checking single domain $DOMAIN"
	check_domain $DOMAIN
elif [[ $CHECK_DOMAIN == "2" ]]; then 
	echo "Checking name $DOMAIN on $DOMAIN_EXTS"
	ELEMENTS=${#DOMAIN_EXTS[@]}
	while (( "$#" )); do  
 		for (( i=0;i<$ELEMENTS;i++)); do 
			check_domain ${DOMAINS[${i}]}
		done 
 	shift 
 	done
fi