# --
# ssl commands
#
# Example help: help_ssl[wp]='Generate phpinfo() file'
#
# --
_debug " -- Loading ${(%):-%N}"

# - Init help array
typeset -gA help_ssl

# -- ssl-check
help_ssl[ssl-check]='Check SSL Certificate on host'
ssl-check () {
	local flag_help flag_verbose arg_filename
	arg_domain=("BLANK")
	arg_filename=("BLANK")
	# -- Check arguments
	typeset -A opts
    zparseopts -D -A opts -- \
        {h,-help}=flag_help \
        {v,-verbose}=flag_verbose \
        {f,-filename}:=arg_filename \
		{ip,-ip}:=arg_ip \
		{d,-domain}:=arg_domain
		
    
	# -- Usage
	function _ssl_check_usage () {
		echo ""
		echo "Usage: ssl-check [-d hostname|-f file]"
		echo "  -h help: Print help"
		echo "  -ip ip: Check SSL Certificate on IP"
		echo "  -d hostname: Check SSL Certificate on hostname, eg. google.com"
		echo "  -f file: Check SSL Certificate in file"
		echo "  -v verbose: Verbose output"
		echo ""
		echo "Checking virtual host on ip, use -ip and -d"
	}

	# -- _ssl_check_print_summary - args: $1: OUTPUT
	function _ssl_check_print_summary () {
		local OUTPUT="$1"
		# -- Summary
		_loading " -- Summary"
		
		# -- Print Issuer		
		echo $OUTPUT | grep 'Issuer:'	
		echo $OUTPUT | grep -A2 'Validity'
		echo $OUTPUT | grep 'Subject: CN'
		echo $OUTPUT | grep 'DNS'

	}

	# -- _ssl_check_domain -- args: $1: DOMAIN, $2 IP $2: VERBOSE
	function _ssl_check_domain () {
		local DOMAIN="$1" IP="$2" VERBOSE="$3" VERBOSE_FLAG="" CHECK_CMD
		_loading2 "Domain: $DOMAIN IP: $IP Verbose: $VERBOSE"		
		
		# -- Check if verbose
		if [[ $IP != "0" ]]; then
			CHECK_CMD="echo | openssl s_client -showcerts -servername $DOMAIN -connect $IP:443 2>/dev/null | openssl x509 -inform pem -noout -text"
		else
			CHECK_CMD="echo | openssl s_client -showcerts -servername $DOMAIN -connect $DOMAIN:443 2>/dev/null | openssl x509 -inform pem -noout -text"
		fi
		
		OUTPUT=$(eval $CHECK_CMD)
		_loading2 "Check command: $CHECK_CMD"
		_loading2 "---------------------------------------------------"
		
		if [[ $VERBOSE == "1" ]]; then
			_loading2 " -- Verbose output"
			echo $OUTPUT
		fi

		_ssl_check_print_summary "$OUTPUT"
		
	}

	# -- _ssl_check_file -- args: $1: FILENAME, $2: verbose
	function _ssl_check_file () {
		local FILENAME="$1" VERBOSE="$2"
		_loading2 "-- Filename: $FILENAME Verbose: $VERBOSE"
		_loading2 "---------------------------------------------------"
		
		# -- Check if verbose
		if [[ $VERBOSE == "1" ]]; then
			_loading2 " -- Verbose output"
			VERBOSE_FLAG=""
		else
			VERBOSE_FLAG="| grep -A2 'Validity' | grep 'Subject: CN' | grep 'DNS'"
		fi
		
		# -- Print output
		output=$(openssl x509 -in $FILENAME -text $VERBOSE_FLAG)
		echo $output
		_loading2 "---------------------------------------------------"
		echo ""
		
		# -- Print validity
		_loading " -- Grabbing Validity"
		echo $output | grep -A2 'Validity'
		
		# -- Print Subject: CN
		_loading " -- Grabbing Subject: CN"
		echo $output | grep 'Subject: CN'
		echo $output | grep 'DNS'
	}

	# -- ARGS
	[[ -n $flag_help ]] && HELP="1" || HELP="0"
	[[ -n $flag_verbose ]] && VERBOSE="1" || VERBOSE="0"	
	[[ -n $arg_domain ]] && DOMAIN="$arg_domain[2]" || DOMAIN=""
	[[ -n $arg_ip ]] && IP="$arg_ip[2]" || IP="$DOMAIN"
	# -- Check arguments
	if [[ -n $flag_help ]]; then
		echo "Printing help"
		_ssl_check_usage	
		return 1
	# -- Domain Check
	elif [[ -n $DOMAIN ]]; then
		if [[ $DOMAIN == "BLANK" ]]; then
			_ssl_check_usage			
			_error "No domain name passed to -d"
			return 1
		elif [[ -n $ARG_IP ]]; then
			_loading "-- Checking SSL Certificate on DOMAIN: $DOMAIN IP: $IP"
			_ssl_check_domain $DOMAIN $IP $VERBOSE
		else
			_loading "-- Checking SSL Certificate on domain: $DOMAIN IP: $IP"
			_ssl_check_domain $DOMAIN $IP $VERBOSE
		fi
	# -- File Check
	elif [[ -n $arg_filename ]]; then
		FILENAME=$arg_filename[1]
		if [[ $FILENAME == "BLANK" ]]; then
			_ssl_check_usage			
			_error "No filename passed to -f"
			return 1
		else
			_loading "-- Checking SSL Certificate on file: $FILENAME"
			_ssl_check_file "-f" $FILENAME $flag_verbose
		fi
	else 
		_ssl_check_usage
		_error "Invalid argument passed or no argument passed"
		return 1
	fi	
}

# -- gen-ss-cert
help_ssl[gen-ss-cert]='Generate a self signed certificate'
gen-ssl-cert () {
	openssl req -new -newkey rsa:2048 -sha256 -days 365 -nodes -x509 -keyout cert.key -out cert.crt
	openssl x509 -in cert.crt -out cert.pem
	openssl rsa -in cert.key -out key.pem
}

# ===============================================
# -- certbot-gen-ssl
# ===============================================
help_ssl[certbot-gen-ssl]='Generate SSL certificate using Certbot DNS-01 manual challenge'
certbot-gen-ssl () {
	local domain email wildcard base_dir config_dir work_dir logs_dir certs_dir

	# -- Parse arguments using zparseopts
	zparseopts -D -E -- \
		{h,-help}=flag_help \
		{d,-domain}:=arg_domain \
		{e,-email}:=arg_email

	# -- Usage function
	function _certbot_gen_ssl_usage () {
		echo ""
		echo "Usage: certbot-gen-ssl -d <domain> -e <email>"
		echo "  -h, --help     Show this help message"
		echo "  -d, --domain   Domain name (e.g., example.com)"
		echo "  -e, --email    Email address for Let's Encrypt notifications"
		echo ""
		echo "Example: certbot-gen-ssl -d example.com -e your-email@example.com"
		echo ""
		echo "This will generate certificates for both the domain and wildcard (*.domain)"
		echo "Certificates will be stored in: \$HOME/ssl/<domain>/certs/"
	}

	# -- Show help
	if [[ -n "$flag_help" ]]; then
		_certbot_gen_ssl_usage
		return 0
	fi

	# -- Get domain and email from arguments
	domain="${arg_domain[2]}"
	email="${arg_email[2]}"

	# -- Input Validation
	if [[ -z "$domain" ]] || [[ -z "$email" ]]; then
		_error "Please provide a domain name and email address"
		_certbot_gen_ssl_usage
		return 1
	fi

	wildcard="*.$domain"
	base_dir="$HOME/ssl/$domain"

	# -- Directory Setup
	_loading "Setting up directories for $domain in $base_dir..."
	mkdir -p "$base_dir"

	config_dir="$base_dir/config"
	work_dir="$base_dir/work"
	logs_dir="$base_dir/logs"
	certs_dir="$base_dir/certs"

	mkdir -p "$certs_dir"

	# -- Certbot Execution
	_loading "Starting Certbot DNS-01 manual challenge for $domain and $wildcard..."
	echo "Certificates will be stored in: $certs_dir"

	certbot certonly --manual \
		-d "$domain" -d "$wildcard" \
		--preferred-challenges dns \
		--email "$email" \
		--server https://acme-v02.api.letsencrypt.org/directory \
		--agree-tos \
		--config-dir "$config_dir" \
		--work-dir "$work_dir" \
		--logs-dir "$logs_dir" \
		--cert-path "$certs_dir/cert.pem" \
		--key-path "$certs_dir/privkey.pem" \
		--fullchain-path "$certs_dir/fullchain.pem"

	# -- Completion Message
	if [[ $? -eq 0 ]]; then
		echo ""
		_success "Certificate generation successful!"
		echo "Your certificate files are located in: $certs_dir"
		echo "Remember to run the renewal command manually every 60-90 days using:"
		echo "  certbot renew --config-dir $config_dir"
	else
		echo ""
		_error "Certificate generation failed. Check the logs in $logs_dir for details."
		return 1
	fi
}

# -- curl-vh
help_ssl[curl-vh]='Curl with verbose headers and SSL checking'
