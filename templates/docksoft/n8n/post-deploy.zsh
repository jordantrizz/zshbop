compose_file="$DOCKSOFT_CONTAINERS/{{CONTAINER_NAME}}/docker-compose.yml"
data_dir="$DOCKSOFT_DATA/{{CONTAINER_NAME}}/data"
encryption_key=""

mkdir -p "$data_dir"

if (( $+commands[chown] )); then
    chown -R 1000:1000 "$data_dir" 2>/dev/null
    if [[ $? -ne 0 ]]; then
        _warning "Unable to set ownership on $data_dir (expected uid/gid 1000:1000 for n8n)"
    else
        _loading3 "Set ownership on $data_dir to 1000:1000 for n8n"
    fi
fi

if (( $+commands[openssl] )); then
    encryption_key=$(openssl rand -hex 32)
else
    encryption_key=$(LC_ALL=C tr -dc 'A-Za-z0-9' < /dev/urandom | head -c 64)
fi

if [[ -z "$encryption_key" ]]; then
    _error "Failed to generate N8N_ENCRYPTION_KEY"
    return 1
fi

sed -i "s|{{N8N_ENCRYPTION_KEY}}|$encryption_key|g" "$compose_file"
if [[ $? -ne 0 ]]; then
    _error "Failed to inject N8N_ENCRYPTION_KEY into docker-compose.yml"
    return 1
fi

_loading3 "Generated and set N8N_ENCRYPTION_KEY for {{CONTAINER_NAME}}"
