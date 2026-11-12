---
title: Docksoft
description: How docksoft deploys containers from templates in templates/docksoft, the placeholders it replaces, and the conventions a new template follows.
---

`docksoft` deploys a container by copying a template directory from
`templates/docksoft/<name>` into `/root/containers/<name>` and rewriting a few placeholders. The
templates shipped today include `traefik`, `uptime-kuma`, `n8n`, `dozzle`, `prunemate`, `dashy`,
`watchtower`, and `zerobyte`.

The authoring rules live in
[`templates/docksoft/AGENTS.md`](https://github.com/jordantrizz/zshbop/blob/next-release/templates/docksoft/AGENTS.md);
this page is the reader's summary. The `docksoft` commands themselves are in the
[command reference](../commands/index.md).

## Template layout

```text
templates/docksoft/<container-name>/
    docker-compose.yml    required
    docksoft.conf         optional, sourced at deploy time
    post-deploy.zsh       optional, sourced at deploy time
```

`docksoft.conf` and `post-deploy.zsh` are removed from the deployed copy after they run.

## `docksoft.conf`

| Key | Effect |
|-----|--------|
| `DOCKSOFT_SUBDOMAIN` | Subdomain used in **multi** mode to build `<subdomain>.<base_domain>` |
| `DOCKSOFT_REQUIRES_TRAEFIK` | Defaults to `true`; set `false` for an internal-only service |

## Placeholders

Deploy replaces these strings anywhere in the deployed files, and nothing else:

| Placeholder | Becomes |
|-------------|---------|
| `{{CONTAINER_NAME}}` | the container instance name chosen for this deploy |
| `{{FQDN}}` | the computed or overridden FQDN |
| `{{DOMAIN}}` | the base domain from the docksoft config |
| `{{EMAIL}}` | the docksoft email, or its override |
| `{{NETWORK}}` | the Docker network used for proxy routing |

## Compose conventions

- Prefer `container_name: <container-name>` and a matching service key, so port allocation state and
  `docker ps` checks stay predictable.
- Docksoft prefers an existing `traefik-proxy` or `traefik` network, and creates `proxy` when neither
  exists. Reference it as `networks: [{{NETWORK}}]` with `networks.{{NETWORK}}.external: true`.
- Non-Traefik templates assume Traefik routes by hostname (`Host({{FQDN}})`, `websecure`, the
  `letsencrypt` resolver, `loadbalancer.server.port`). `prunemate` is the deliberate exception: it is
  localhost-only, publishes to `127.0.0.1`, and carries no Traefik labels.
- Published host ports must be explicit and numeric (`"127.0.0.1:9999:8080"` or `"9999:8080"`), because
  docksoft rewrites them to avoid conflicts. Behind Traefik, prefer no `ports:` at all.
- Persistent data belongs under `/srv/containers/<container-name>/data`, which docksoft creates.

## Adding a template

1. Name the folder after the command: `docksoft <folder-name>`.
2. Write `docker-compose.yml` with the proxy network and Traefik labels, unless the service is
   intentionally localhost-only.
3. Use only the placeholders above.
4. Keep published ports explicit and numeric.
5. Mount persistent volumes under `/srv/containers/<folder-name>/data`.
