---
title: Updating
description: How zbu and zb update work, the branch rules, background repository sync, and what the update check compares.
---

`zbu` and `zb update` update zshbop itself, then reload the shell. `zb check-updates` only reports.

## Update rules

- Updates are allowed on `main` and `next-release`. Any other branch is refused.
- If uncommitted changes are present — tracked or untracked — the update exits and asks you to commit
  or stash first.
- The update runs a force-sync flow (`fetch` + `reset --hard`) so a diverged checkout never stops on a
  merge or rebase prompt.

`zb` also offers `zbr` (reload), `zbqr` (quick reload), `zbuf` (update and reset), and `zbuqr` (update
and quick reload).

## Background repository sync

`$ZSHBOP_UPDATE_GIT` names extra repositories to sync during an update. By default `zbu` starts a
detached worker for them, so the shell — and the MOTD update prompt — is never blocked on a slow
remote.

The update transcript shows one line:

```text
Syncing 2 extra repositories in the background
```

A single summary appears at the next prompt, once, and nothing at all when every repository was
already current:

```text
Extra repositories: 2 updated · 3 current (12s)
```

A failure reads `1 failed · 3 current - 'zb update-status' for details`.

Each repository reports one line (`up to date`, `updated (+N commits)`, `reset to origin/<branch>`)
and never streams git progress, `remote:` lines, or the multi-line `hint:` advice block. A diverged
mirror is reset to its upstream; a dirty worktree blocks that reset instead of discarding the work.

State lives in `$ZSHBOP_CACHE_DIR/repo-update/`, so it survives a reload.

### `zb update-status`

```bash
zb update-status              # running or idle, with per-repository results
zb update-status -l           # the run log
zb update-status -j           # machine-readable JSON
```

### Switches

| Variable | Default | Effect |
|----------|---------|--------|
| `ZSHBOP_UPDATE_GIT_BACKGROUND` | `1` | `0` restores the blocking foreground loop (and its non-zero exit on failure) |
| `ZSHBOP_UPDATE_GIT_NOTIFY` | `1` | `0` silences the prompt summary; `zb update-status` still reports |
| `ZSHBOP_UPDATE_GIT_TIMEOUT` | `300` | Seconds after which a stuck worker is treated as dead |
| `ZSHBOP_UPDATE_VERBOSE` | unset | `1` shows the raw git output instead of the one-line reports |
| `ZSHBOP_UPDATE_PROMPT` | `1` | `0` disables the MOTD update prompt |

## The update check

`zb check-updates` is pure git: no GitHub API calls, no `curl`/`jq` dependency, no rate limits.

| Branch | The check compares |
|--------|--------------------|
| `main` | Release tags. The latest tag on `origin/main` can be ahead by one, two, or many releases ("N release(s) behind") |
| `next-release` | Commits on `origin/next-release`. Tags and single commits in between are all detected ("N commit(s) behind") |

The MOTD runs the check in `--motd` mode at login: fully silent when up to date, and one warning
(`run 'zbu' to update`) when an update is available.

## See also

- [Boot timing](./boot-timing.md) — how the shell measures its own startup.
- [Debugging](./debugging.md) — when an update or a repository sync misbehaves.
