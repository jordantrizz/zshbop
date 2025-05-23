#!/usr/bin/env bash
## - Variables
GOOGLE_SPF="v=spf1 include:_spf.google.com ~all"

## - Functions
# -- Echo command then run
echo_and_run() { 
	if [ -f .test ]; then
		echo "Test Running: $@"
	else
		 echo "Running: $*"
		"$@"
	fi
}

help () {
	echo "---------------------------------------------------------------------"
	echo "A wrapper to cloudflare github.com/bAndie91/cloudflare-cli to provide"
	echo "easy creation of MX records for popular email services"
	echo "---------------------------------------------------------------------"
	echo ""
        echo "Syntax: cfmx -d <domain-name> -s <service> | -spf | -cspf <customSPFrecord>"
	echo ""
	echo "-spf					-Set SPF Record"
	echo "-cspf <spfrecord>			-Custom SPF Record"
	echo "<service>				-Specify service (google,zoho)"
	echo ""
        echo "Example: cfmx -d domain.com -s google"
	echo ""
	exit
}

# -- Set google records
function set-google () {
	echo "Setting Google MX records.."
	echo_and_run cloudflare add record $DOMAIN mx @ ASPMX.L.GOOGLE.COM 1 1
	echo_and_run cloudflare add record $DOMAIN mx @ ALT1.ASPMX.L.GOOGLE.COM 1 5
	echo_and_run cloudflare add record $DOMAIN mx @ ALT2.ASPMX.L.GOOGLE.COM 1 5
	echo_and_run cloudflare add record $DOMAIN mx @ ALT3.ASPMX.L.GOOGLE.COM 1 10
	echo_and_run cloudflare add record $DOMAIN mx @ ALT4.ASPMX.L.GOOGLE.COM 1 10
        if [[ $SPF = 1 ]]; then
                echo "** Setting Google spf record.."
                echo_and_run cloudflare add record $DOMAIN TXT @ "$GOOGLE_SPF"
        fi
}

# -- Modify MX
function modify_mx () {
	if [[ $SERVICE = "google" ]]; then set-google; fi
}

# -- Custom SPF
function custom_spf () {
	echo "** Setting Custom SPF record - $CSPF"
        echo_and_run  cloudflare add record $DOMAIN TXT @ \"$CSPF\"
}

# -- Ingest Variables
POSITIONAL=()
while [[ $# -gt 0 ]]
do
key="$1"

case $key in
    -d|--domain)
    DOMAIN="$2"
    shift # past argument
    shift # past value
    ;;
    -spf|--spf)
    SPF="1"
    shift # past argument
    shift # past value
    ;;
    -cspf|--custom-spf)
    CSPF="$2"
    shift # past argument
    shift # past value
    ;;
    -s|--service)
    SERVICE="$2"
    shift # past argument
    shift # past value
    ;;
    *)    # unknown option
    POSITIONAL+=("$1") # save it in an array for later
    shift # past argument
    ;;
esac
done
set -- "${POSITIONAL[@]}" # restore positional parameters

# -- Let's go!

if [ -z $DOMAIN ]; then
	echo "ERROR: No domain specified"
	help
elif [ ! -z $DOMAIN ] && [ ! -z $CSPF ]; then
	echo "Just modifying SPF"
        custom_spf
	exit
elif [ ! -z $DOMAIN ] && [ -z $SERVICE ]; then
	echo "ERROR: Specify a service or custom SPF"
	help
elif [ ! -z $DOMAIN ] && [ ! -z $SERVICE ]; then
	if [ ! -z $CSPF ]; then
	        echo "Setting MX and Custom SPF"
	        echo "Starting - Domain: $DOMAIN Service: $SERVICE"
	        modify_mx
	        custom_spf
		exit
	fi
	echo "Setting MX Records only"
	echo "Starting - Domain: $DOMAIN Service: $SERVICE"
	modify_mx
else
	help
fi