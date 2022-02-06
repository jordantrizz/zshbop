# ----------------------------
# -- Functions that are Tools!
# ----------------------------

# -- curl
vh () { vh_run=$(curl --header "Host: $1" $2 --insecure -i | head -50);echo $vh_run }

# -- SSL
check_ssl () { echo | openssl s_client -showcerts -servername $1 -connect $1:443 2>/dev/null | openssl x509 -inform pem -noout -text }
