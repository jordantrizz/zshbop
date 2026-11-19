---
title: traefik-status
description: Read the Traefik labels declared by running containers — container, router, enabled, network, host, TLS, certresolver and port — and understand how each column is derived.
---

`traefik-status` answers two different questions, and it is worth keeping them apart:

- **What did Traefik load?** Routers, services, entrypoints, ACME certificates, the `traefik`
  container's own health. This comes from the Traefik API and is what the command prints by default.
- **What did each container declare?** The `traefik.*` labels on every running container. This comes
  from Docker, is shown by `traefik-status -l`, and needs neither the Traefik API nor a running
  `traefik` container.

The second question is the pre-flight view of a deployment: a 404 or an unreachable service is
usually a label that is missing, misspelled or pointing at the wrong port, and the API cannot tell
you that because a router that was never parsed does not exist there.

## `traefik-status -l`

```bash
traefik-status -l
```

```text
CONTAINER           ROUTER            ENABLED  NETWORK        HOST                    TLS  CERTRESOLVER  PORT
librechat           librechat-secure  yes      traefik-proxy  librechat.unixmail.org  yes  cloudflare    3080
nas-storage-report  nas               yes      traefik-proxy  nas.unixmail.org        yes  cloudflare    8080
openwebui           openwebui         yes      traefik-proxy  openwebui.unixmail.org  yes  cloudflare    8080
  3 container(s), 3 router row(s), 3 enabled
```

One row per router, not one row per container: a container can declare several routers with
different hosts, resolvers and ports, and collapsing them into one row would have to hide one of them.
A container that carries `traefik.*` labels but declares no router still gets one row with `ROUTER`
set to `-`, so `traefik.enable=false` and network-only declarations stay visible.

| Column | Source | Notes |
|--------|--------|-------|
| `CONTAINER` | `docker ps` | Running containers only; Traefik's Docker provider does not route to stopped ones |
| `ROUTER` | `traefik.http.routers.<name>.…` | The router's own name, not the container's |
| `ENABLED` | `traefik.enable` | `yes` / `no`; `-` when the label is unset, which leaves the decision to `providers.docker.exposedByDefault` |
| `NETWORK` | `traefik.docker.network` | Falls back to the container's attached networks when the label is unset, which is what Traefik guesses from |
| `HOST` | `Host(...)` in `traefik.http.routers.<name>.rule` | Multiple hosts are comma-joined; a rule with no `Host()` renders `-` |
| `TLS` | `traefik.http.routers.<name>.tls` | `yes` when the router has a `tls` or `tls.*` key |
| `CERTRESOLVER` | `traefik.http.routers.<name>.tls.certresolver` | `-` when unset; with `tls` unset that means plain HTTP, with `tls` set it means Traefik's default resolver |
| `PORT` | `traefik.http.services.<service>.loadbalancer.server.port` | The router's `service` label picks the service; without one, the first service port on the container is used; `-` means Traefik falls back to the image's `EXPOSE` |

## Flags

| Flag | Effect |
|------|--------|
| `-l`, `--labels` | Print the label table and nothing else |
| `-a`, `--all` | With `-l`, also list containers that declare no `traefik.*` label — the way to find a service nobody labeled |
| `-r`, `--raw` | Print raw JSON from the Traefik API; refused together with `-l` |
| `-h`, `--help` | Usage |

`traefik-status -l` makes exactly two Docker calls — `docker ps -q` and one batched
`docker inspect` over every id — so the cost does not grow with the number of containers. That is
also why it is safe to run on a busy host.

## Output fallbacks

The table is rendered from `jq` when it is installed, from `python3` when it is not, and otherwise
the command prints a warning and the raw container label JSON instead of a table it would have to
guess at. Alignment uses `column -t`; without it the rows are printed tab-separated.

## Related

- [`docksoft`](./docksoft.md) — deploys containers from templates and writes these labels.
- `docksoft gen-labels` — generates the label block for a new service; this table is how you read it
  back once the service is running.
