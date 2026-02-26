default_config_source="$DOCKSOFT_CONTAINERS/{{CONTAINER_NAME}}/conf.yml"
runtime_config_file="$DOCKSOFT_DATA/{{CONTAINER_NAME}}/data/conf.yml"
credentials_file="$DOCKSOFT_CONTAINERS/{{CONTAINER_NAME}}/admin-credentials.txt"

admin_password=""
admin_hash=""

if (( $+commands[openssl] )); then
    admin_password=$(openssl rand -base64 48 | tr -dc 'A-Za-z0-9#@%*&^' | head -c 24)
else
    admin_password=$(LC_ALL=C tr -dc 'A-Za-z0-9#@%*&^' < /dev/urandom | head -c 24)
fi

if [[ -z "$admin_password" ]]; then
    _error "Failed to generate random Dashy admin password"
    return 1
fi

if (( $+commands[openssl] )); then
    admin_hash=$(printf "%s" "$admin_password" | openssl dgst -sha256 | awk '{print $2}' | tr '[:lower:]' '[:upper:]')
elif (( $+commands[sha256sum] )); then
    admin_hash=$(printf "%s" "$admin_password" | sha256sum | awk '{print $1}' | tr '[:lower:]' '[:upper:]')
fi

if [[ -z "$admin_hash" ]]; then
    _error "Failed to generate Dashy SHA-256 password hash"
    return 1
fi

if [[ ! -f "$runtime_config_file" ]] && [[ -f "$default_config_source" ]]; then
    cp "$default_config_source" "$runtime_config_file"
fi

if [[ ! -f "$runtime_config_file" ]]; then
    _error "Failed to find or create Dashy config at $runtime_config_file"
    return 1
fi

sed -i "s|{{DASHY_ADMIN_PASSWORD_HASH}}|$admin_hash|g" "$runtime_config_file"
if [[ $? -ne 0 ]]; then
    _error "Failed to inject Dashy auth hash into conf.yml"
    return 1
fi

chmod 600 "$runtime_config_file" 2>/dev/null

{
    echo "DASHY_ADMIN_USER=admin"
    echo "DASHY_ADMIN_PASSWORD=$admin_password"
} > "$credentials_file"

chmod 600 "$credentials_file" 2>/dev/null
_loading3 "Dashy admin credentials saved to: $credentials_file"
