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

    local hostname="$1"
    local port="$2"
    local username="$3"
    local password="$4"
    local response
    local conn

    # Make SMTP connection
    echo "Trying to connect to $hostname on port $port..."
    conn="$(nc -w 5 "$hostname" "$port")"
    echo "Connected!"

    # Send EHLO command
    echo "Sending EHLO command..."
    response="$(echo -ne "EHLO example.com\r\n" | tee >(cat - >&3) | cat <&4 >&(grep -v '^EHLO\|^250' >&2))"
    echo "Response: $response"

    # Send STARTTLS command and initiate TLS handshake
    echo "Sending STARTTLS command..."
    response="$(echo -ne "STARTTLS\r\n" | tee >(cat - >&3) | cat <&4 >&(grep -v '^220' >&2))"
    echo "Response: $response"

    echo "Initiating TLS handshake..."
    response="$(openssl s_client -quiet -connect "$hostname":"$port" < /dev/null | sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' > smtp.crt)"
    echo "Response: $response"

    # Start TLS encryption on existing connection
    echo "Starting TLS encryption on existing connection..."
    response="$(echo -ne "EHLO example.com\r\n" | tee >(cat - >&3) | cat <&4 >&(grep -v '^EHLO\|^250' >&2))"
    echo "Response: $response"

    # Send AUTH LOGIN command and send encoded username and password
    echo "Sending AUTH LOGIN command..."
    response="$(echo -ne "AUTH LOGIN\r\n" | tee >(cat - >&3) | cat <&4 >&(grep -v '^334' >&2))"
    echo "Response: $response"

    echo "Sending Base64-encoded username..."
    response="$(echo -ne "$username" | base64 | tr -d '\n' | sed 's/^/USER /' | sed 's/$/\r\n/' | tee >(cat - >&3) | cat <&4 >&(grep -v '^334' >&2))"
    echo "Response: $response"

    echo "Sending Base64-encoded password..."
    response="$(echo -ne "$password" | base64 | tr -d '\n' | sed 's/^/PASS /' | sed 's/$/\r\n/' | tee >(cat - >&3) | cat <&4 >&(grep -v '^235' >&2))"
    echo "Response: $response"

    # Close connection
    echo "Closing connection..."
    response="$(echo -ne "QUIT\r\n" | tee >(cat - >&3) | cat <&4 >&(grep -v '^221' >&2))"
    echo "Response: $response"

    # Close file descriptors
    exec 3>&-
    exec 4<&-
}

