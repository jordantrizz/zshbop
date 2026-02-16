# Docksoft Templates - Agent Notes

This repo’s `docksoft` command deploys containers by copying a template directory from `templates/docksoft/<name>` into `/root/containers/<name>` and doing a small amount of rewriting.

## Template Folder Layout
A docksoft template lives at:
- `templates/docksoft/<container-name>/`

Recommended files:
- `docker-compose.yml` (required)
- `docksoft.conf` (optional; used only at deploy time)
- `post-deploy.zsh` (optional; sourced at deploy time)

Notes:
- `docksoft.conf` is sourced during deploy and then removed from the deployed copy.
- `post-deploy.zsh` (if present) is sourced during deploy and then removed from the deployed copy.

## `docksoft.conf` Convention
If present, `docksoft.conf` can set:
- `DOCKSOFT_SUBDOMAIN="<subdomain>"`

This is used in **multi** mode to compute the deployed FQDN as `<subdomain>.<base_domain>`.

## Supported Placeholders
During deploy, docksoft replaces these placeholders anywhere in the deployed files:
- `{{FQDN}}` (the computed/overridden FQDN for this service)
- `{{DOMAIN}}` (the base domain from docksoft config)
- `{{EMAIL}}` (docksoft email, or override)
- `{{NETWORK}}` (the Docker network name used for proxy routing)

Keep templates limited to those placeholders; no other templating engine runs.

## Compose Conventions
### Container and service names
- Prefer `container_name: <container-name>`.
- Prefer the service key in compose to match the container name.

This keeps port allocation state and `docker ps` checks predictable.

### Networking
Docksoft uses a shared external network for reverse-proxy routing.

At runtime it will prefer an existing network named `traefik-proxy` or `traefik` when present; otherwise it uses/creates `proxy`.

Use:
- `networks: [{{NETWORK}}]`
- `networks.{{NETWORK}}.external: true`

### Traefik labels
All non-traefik templates assume Traefik is deployed and can route by hostname.

Exception:
- `prunemate` is intentionally localhost-only and is **not** exposed via Traefik labels.
- Keep its published port bound to `127.0.0.1`.

Typical pattern:
- Enable Traefik for the container
- Route by `Host(`{{FQDN}}`)`
- Use `websecure` + Let’s Encrypt resolver `letsencrypt`
- Set the service’s internal port via `loadbalancer.server.port`

### Ports (host publishing)
Docksoft automatically rewrites *published* host ports in `docker-compose.yml` to avoid conflicts.

To be compatible with this allocator:
- Use explicit numeric mappings like `"127.0.0.1:9999:8080"` or `"9999:8080"`.
- Avoid complex forms that don’t include a host port.

Best practice for web apps behind Traefik:
- Publish only to localhost (`127.0.0.1:...`) if you need a host port at all.
- Otherwise omit `ports:` and rely solely on Traefik.

### Data paths
At deploy time, docksoft creates:
- `/srv/containers/<container-name>/data`

If the container needs persistence, mount volumes under that path, e.g.:
- `/srv/containers/<container-name>/data:/app/data`

## Quick Checklist (when adding a new template)
- Folder name matches the deploy command: `docksoft <folder-name>`
- `docker-compose.yml` uses the `proxy` network and Traefik labels (unless intentionally localhost-only, like `prunemate`)
- Uses only `{{FQDN}}`, `{{DOMAIN}}`, `{{EMAIL}}` placeholders
- Any published ports are explicit and numeric (so allocator can rewrite)
- Persistent volumes live under `/srv/containers/<folder-name>/data`
