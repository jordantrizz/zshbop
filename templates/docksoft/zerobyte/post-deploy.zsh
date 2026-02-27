compose_file="$DOCKSOFT_CONTAINERS/{{CONTAINER_NAME}}/docker-compose.yml"
credentials_file="$DOCKSOFT_CONTAINERS/{{CONTAINER_NAME}}/admin-credentials.txt"

app_secret=""

if (( $+commands[openssl] )); then
    app_secret=$(openssl rand -hex 32)
else
    app_secret=$(LC_ALL=C tr -dc 'A-Fa-f0-9' < /dev/urandom | head -c 64)
fi

if [[ -z "$app_secret" ]]; then
    _error "Failed to generate Zerobyte APP_SECRET"
    return 1
fi

sed -i "s|{{ZEROBYTE_APP_SECRET}}|$app_secret|g" "$compose_file"
if [[ $? -ne 0 ]]; then
    _error "Failed to inject APP_SECRET into docker-compose.yml"
    return 1
fi

{
    echo "ZEROBYTE_URL=https://{{FQDN}}"
    echo "ZEROBYTE_APP_SECRET=$app_secret"
} > "$credentials_file"

chmod 600 "$credentials_file" 2>/dev/null
_loading3 "Zerobyte credentials saved to: $credentials_file"
