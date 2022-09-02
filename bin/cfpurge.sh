#!/bin/bash
# From https://bash.cyberciti.biz/web-server/linuxunix-bash-shell-script-to-purge-cloudflare-urlimages-from-the-command-line/
# Purpose: Purge url(s) using cloudflare API from the bash shell 
# Author: Vivek Gite
# License: GNU GPL v2.x+
#----------------------------------------------------------------------
#
# Purge all, to be implemented.
#
#curl -X DELETE "https://api.cloudflare.com/client/v4/zones/ZONE-ID/purge_cache" \
#-H "X-Auth-Email: YOU@DOMAIN-EMAIL" \
#-H "X-Auth-Key: MY_API_KEY" \
#-H "Content-Type:application/json" \
#--data '{"purge_everything":true}'
#
#-----------------------------------------------------------------------

_debug () {
    if [[ $CFPURGE_DEBUG == 1 ]]; then
        echo "**** DEBUG: $@";
    fi
}

## Check for $HOME/.cloudflare file
if [[ ! -a $HOME/.cloudflare ]]; then
    echo "Error, no .cloudflare file"
    exit 1
else
    source ~/.cloudflare
    echo "-- Found .cloudflare file"
fi

## Variables
CF_ZONEID=""
PURGE_URL=""

## Usage function
usage () {
	echo "Usage: cfpurge.sh url url2";
}

## Get zoneid
cf_getzoneid () {
	ZONE="$(echo $1 | awk -F/ '{ print $3}')"
	CF_ZONEID=$(curl -s -X GET 'https://api.cloudflare.com/client/v4/zones/?per_page=500' \
	-H "X-Auth-Email: ${CF_ACCOUNT}" -H "X-Auth-Key: ${CF_TOKEN}" -H "Content-Type: application/json" \
	| jq -r '.result[] | "\(.id) \(.name)"' \
	| grep "$ZONE" | awk {' print $1 '})	
	echo "  - Debug: $ZONE - ${CF_ZONEID}"
}

## Purge URL
cf_purgeurl () {
	curl -X DELETE "https://api.cloudflare.com/client/v4/zones/${CF_ZONEID}/purge_cache" \
	-H "X-Auth-Email: ${CF_ACCOUNT}" -H "X-Auth-Key: ${CF_TOKEN}" -H "Content-Type: application/json" \
    --data "{\"files\":[\"${PURGE_URL}\"]}"
}

## Get url(s) to purge ##
URLS="$*"
if [[ "$URLS" == "" ]]; then
	usage
    exit 1;
fi

echo "-- Starting purge process."

## Get URL's domain, zoneid and then purge.
for PURGE_URL in $URLS; do
	_debug "$CURL_HEADERS"
	echo "  - Purging URL -- $u"
	echo "  - Getting Zone ID"
	cf_getzoneid $PURGE_URL
	echo "  - Found Zone ID $CF_ZONEID"
	echo "  - Purging from zoneid $CF_ZONEID"
	cf_purgeurl
done

echo "-- End purge process."