# --
# Mail commands
#
# Example help: help_wordpress[wp]='Generate phpinfo() file'
#
# --
_debug " -- Loading ${(%):-%N}"

# What help file is this?
help_files[mail]='All mail related commands'

# - Init help array
typeset -gA help_mail

# -- eximcq
help_mail[eximcq]='Clear all mail in exim MTA queue. *DANGER*'
eximcq () { exim -bp | exiqgrep -i | xargs exim -Mrm }

# -- postmark
help_mail[postmark]='Postmark cli for sending email'
alias postmark="postmark.sh"

# -- mail-smtptest
help_mail[mail-smtptest]='Test SMTP Login'
function mail-smtptest () {
    if [[ $# -lt 4 ]]; then
        echo "Usage: mail-smtptest hostname port username password" >&2
        return 1
    fi

    local hostname="${1:-smtp.example.com}"
    local port="${2:-587}"
    local username="${3:-user@example.com}"
    local password="${4:-password}"
    local response

    # Make SMTP connection
    echo "Trying to connect to $hostname on port $port..."
    response="$(echo -ne "EHLO example.com\r\n" | nc -w 5 "$hostname" "$port")"
    echo "Response: $response"

    # Send STARTTLS command and initiate TLS handshake
    echo "Sending STARTTLS command..."
    response="$(echo -ne "STARTTLS\r\n" | nc -w 5 "$hostname" "$port")"
    echo "Response: $response"

    echo "Initiating TLS handshake..."
    response="$(openssl s_client -quiet -connect "$hostname":"$port" < /dev/null | sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' > smtp.crt)"
    echo "Response: $response"

    # Send EHLO command again after TLS handshake
    echo "Sending EHLO command again after TLS handshake..."
    response="$(echo -ne "EHLO example.com\r\n" | nc -w 5 "$hostname" "$port")"
    echo "Response: $response"

    # Send AUTH LOGIN command and send encoded username and password
    echo "Sending AUTH LOGIN command..."
    response="$(echo -ne "AUTH LOGIN\r\n" | nc -w 5 "$hostname" "$port")"
    echo "Response: $response"

    echo "Sending Base64-encoded username..."
    response="$(echo -ne "$username" | base64 | tr -d '\n' | sed 's/^/USER /' | sed 's/$/\r\n/' | nc -w 5 "$hostname" "$port")"
    echo "Response: $response"

    echo "Sending Base64-encoded password..."
    response="$(echo -ne "$password" | base64 | tr -d '\n' | sed 's/^/PASS /' | sed 's/$/\r\n/' | nc -w 5 "$hostname" "$port")"
    echo "Response: $response"

    # Close connection
    echo "Closing connection..."
    response="$(echo -ne "QUIT\r\n" | nc -w 5 "$hostname" "$port")"
    echo "Response: $response"
}
