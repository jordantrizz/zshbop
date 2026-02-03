# --
# postmark commands
#
# Example help: help_postmark[test]='Generate phpinfo() file'
#
# --
_debug " -- Loading ${(%):-%N}"

# What help file is this?
help_files[postmark]="Postmark API Commands"

# - Init help array
typeset -gA help_postmark

_debug " -- Loading ${(%):-%N}"

# -- paths
help_postmark[postmark]='Run postmark api commands'
postmark-admin-usage () {
	echo "Usage: postmark <domain> <cmd>"
}
postmark-admin () {
	if [[ ! -f $HOME/.postmark ]]; then
		_error "Couldn't find $HOME/.postmark"
		return 1
	else
		source $HOME/.postmark
		if [[ -z $POSTMARK_TOKEN ]]; then
			_error "Define \$POSTMARK_TOKEN in $HOME/.postmark"
			return 1
		else
			_success "Found \$POSTMARK_TOKEN in $HOME/.postmark"
		fi
	fi
		
	if [[ -z $@ ]]; then
		postmark-admin-usage
		return 1
	elif [[ -z $1 ]]; then
		_error "Missing domain"
		postmark-admin-usage
		return 1
	elif [[ -z $2 ]]; then
		_error "Missing command"
		postmark-admin-usage
		return 1
	fi

	DOMAIN=$1
	CMD=$2
	
	if [[ $CMD == "create-domain" ]]; then
		echo " -- Creating $DOMAIN in postmark"
		curl "https://api.postmarkapp.com/domains" \
		-X POST \
		-H "Accept: application/json" \
		-H "Content-Type: application/json" \
		-H "X-Postmark-Account-Token: ${POSTMARK_TOKEN}" \
		-d "{
			\"Name\": \"${DOMAIN}\",
			\"ReturnPathDomain\": \"pmbounces.${DOMAIN}\"
		}"
	fi

}
