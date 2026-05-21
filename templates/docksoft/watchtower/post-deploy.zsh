compose_file="$DOCKSOFT_CONTAINERS/{{CONTAINER_NAME}}/docker-compose.yml"
notifications_placeholder='^[[:space:]]*- {{WATCHTOWER_NOTIFICATIONS_LINE}}$'
slack_hook_placeholder='^[[:space:]]*- {{WATCHTOWER_SLACK_HOOK_LINE}}$'
slack_webhook=""

if [[ ! -f "$compose_file" ]]; then
    _error "Failed to find watchtower compose file at $compose_file"
    return 1
fi

while true; do
    read "slack_webhook?Enter Slack webhook URL for watchtower notifications (leave blank to skip): "

    if [[ -z "$slack_webhook" ]]; then
        sed -i "/$notifications_placeholder/d" "$compose_file"
        sed -i "/$slack_hook_placeholder/d" "$compose_file"
        _loading3 "Skipping Slack notification configuration for {{CONTAINER_NAME}}"
        break
    fi

    if [[ ! "$slack_webhook" =~ '^https://hooks\.slack\.com/services/[A-Za-z0-9._-]+/[A-Za-z0-9._-]+/[A-Za-z0-9._-]+/?$' ]]; then
        _warning "Invalid Slack webhook URL. Expected https://hooks.slack.com/services/..."
        continue
    fi

    sed -i "s|{{WATCHTOWER_NOTIFICATIONS_LINE}}|WATCHTOWER_NOTIFICATIONS=slack|g" "$compose_file"
    sed -i "s|{{WATCHTOWER_SLACK_HOOK_LINE}}|WATCHTOWER_NOTIFICATION_SLACK_HOOK_URL=$slack_webhook|g" "$compose_file"
    _loading3 "Configured Slack notifications for {{CONTAINER_NAME}}"
    break
done