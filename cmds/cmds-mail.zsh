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

    # Check if hostname resolves
    #host_ip="$(dig +short "$hostname" | head -n 1)"
    #if [[ -z "$host_ip" ]]; then
    #    _error "Unable to resolve hostname: $hostname" >&2
    #    return 1
    #fi

    # Check if port is open
    #if ! nc -z -w5 "$host_ip" "$port"; then
    #    _error "Unable to connect to $hostname on port $port" >&2
    #    return 1
    #fi

      if [ $# -ne 4 ]; then
    echo "Usage: smtp_connect <smtp_server> <smtp_port> <username> <password>"
    return 1
  fi

  local smtp_server=$1
  local smtp_port=$2
  local username=$3
  local password=$4
  local temp_file=$(mktemp)

  {
    echo "EHLO $smtp_server"
    sleep 1
    echo "AUTH LOGIN"
    sleep 1
    echo "$username" | base64
    sleep 1
    echo "$password" | base64
    sleep 1
    echo "QUIT"
  } | openssl s_client -connect $smtp_server:$smtp_port -starttls smtp -crlf 2>/dev/null > $temp_file

  local response=$(cat $temp_file)
  rm $temp_file
  echo "$response"

}

