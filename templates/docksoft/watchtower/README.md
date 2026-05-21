# Watchtower Docksoft Template

This Docksoft template deploys `nickfedor/watchtower:latest` as an internal-only
service for automated container update checks. It does not publish ports or rely
on Traefik.

## Deploy Behavior

During `docksoft watchtower`, the post-deploy hook prompts for an optional Slack
webhook URL.

- If you provide a webhook URL, Docksoft adds these environment variables to the
  deployed `docker-compose.yml`:
  - `WATCHTOWER_NOTIFICATIONS=slack`
  - `WATCHTOWER_NOTIFICATION_SLACK_HOOK_URL=https://hooks.slack.com/services/...`
- If you leave it blank, Docksoft removes the notification placeholders and deploys
  watchtower without Slack notifications.

## Shoutrrr Format

Watchtower also supports the newer Shoutrrr-style notification URL format via
`WATCHTOWER_NOTIFICATION_URL`.

For Slack, the equivalent format looks like:

```env
WATCHTOWER_NOTIFICATION_URL=slack://hook:TOKEN_A-TOKEN_B-TOKEN_C@webhook?botname=watchtower
```

Format notes:

- A standard Slack webhook looks like `https://hooks.slack.com/services/TOKEN_A/TOKEN_B/TOKEN_C`.
- The Shoutrrr form rewrites those three token segments into a single
  `TOKEN_A-TOKEN_B-TOKEN_C` value after `hook:`.
- Optional query parameters such as `botname`, `icon`, `channel`, and `color`
  can be appended to further customize messages.

If you prefer the Shoutrrr format, replace the legacy Slack environment variables
in the deployed compose file with `WATCHTOWER_NOTIFICATION_URL=slack://...`.