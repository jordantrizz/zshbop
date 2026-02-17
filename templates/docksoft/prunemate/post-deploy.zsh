compose_file="$DOCKSOFT_CONTAINERS/{{CONTAINER_NAME}}/docker-compose.yml"
credentials_file="$DOCKSOFT_CONTAINERS/{{CONTAINER_NAME}}/admin-credentials.txt"
default_config_source="$DOCKSOFT_CONTAINERS/{{CONTAINER_NAME}}/config.json"
runtime_config_dir="$DOCKSOFT_DATA/{{CONTAINER_NAME}}/data/config"
runtime_config_file="$runtime_config_dir/config.json"

if (( ! $+commands[docker] )); then
    _error "Docker is required to generate PruneMate auth hash"
    return 1
fi

admin_password=""
if (( $+commands[openssl] )); then
    admin_password=$(openssl rand -base64 48 | tr -dc 'A-Za-z0-9#@%*&^' | head -c 24)
else
    admin_password=$(LC_ALL=C tr -dc 'A-Za-z0-9#@%*&^' < /dev/urandom | head -c 24)
fi

if [[ -z "$admin_password" ]]; then
    _error "Failed to generate random PruneMate admin password"
    return 1
fi

hash_output=$(docker run --rm anoniemerd/prunemate:latest python prunemate.py --gen-hash "$admin_password" 2>/dev/null)
admin_hash=$(echo "$hash_output" | tr -d '\r' | grep -E '^[A-Za-z0-9+/=]+$' | tail -n 1)

if [[ -z "$admin_hash" ]]; then
    _error "Failed to generate PruneMate password hash"
    return 1
fi

sed -i "s|{{PRUNEMATE_AUTH_PASSWORD_HASH}}|$admin_hash|g" "$compose_file"
if [[ $? -ne 0 ]]; then
    _error "Failed to inject PruneMate auth hash into docker-compose.yml"
    return 1
fi

{
    echo "PRUNEMATE_ADMIN_USER=admin"
    echo "PRUNEMATE_ADMIN_PASSWORD=$admin_password"
} > "$credentials_file"

chmod 600 "$credentials_file" 2>/dev/null
_loading3 "PruneMate admin credentials saved to: $credentials_file"

mkdir -p "$runtime_config_dir"
if [[ ! -f "$runtime_config_file" ]] && [[ -f "$default_config_source" ]]; then
    cp "$default_config_source" "$runtime_config_file"
    chmod 600 "$runtime_config_file" 2>/dev/null
    _loading3 "PruneMate default config installed at: $runtime_config_file"
fi
