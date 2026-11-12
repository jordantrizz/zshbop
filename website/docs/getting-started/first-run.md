---
title: First run
description: What zshbop does when a shell starts, how VSCode and agent terminals are detected, and the first commands to run.
---

After installation, a new shell sources zshbop once and initializes the prompt, plugins, checks, and
the MOTD.

## Initialization

- VSCode shells are detected when `TERM_PROGRAM=vscode` or `VSCODE_IPC_HOOK_CLI` is set.
- In VSCode, zshbop does not force a reload; full initialization runs unless a reload is explicitly
  requested.
- Reload sessions skip `init_motd` and `init_sshkeys`.
- In normal shells, initialization runs once per shell; later re-sources are skipped unless a reload
  is explicitly requested.
- If `AUTO_LS_CHPWD=false`, auto-listing happens on Enter (`accept-line`) rather than on directory
  change hooks.

To see what the shell decided:

```bash
echo $TERM_PROGRAM
echo $VSCODE_IPC_HOOK_CLI
echo $ZSHBOP_RELOAD
echo $ZSHBOP_INITIALIZED
```

Set `ZSHBOP_DISABLE_VSCODE_SHELL=1` in `$HOME/.zshbop.conf` before initialization to opt out of the
VSCode-specific behaviour.

## Agent and AI terminals

AI/agent terminals (VS Code Copilot agent-host terminals) are detected through `AI_AGENT` or
`COPILOT_AGENT`. VS Code spawns them with paging disabled (`PAGER`, `GIT_PAGER`, and `GH_PAGER`
empty), so `git log` and similar commands dump everything instead of using `less`. Set
`ZSHBOP_AI_PAGER=1` in your config before initialization to restore `less` paging there; it is off by
default.

## The first commands

| Command | What it does |
|---------|--------------|
| `zb` | The main entry point; lists the available `zb` subcommands |
| `zb check` | Checks the environment for installed software and tools |
| `help` | The zshbop help screen; `help <category>` lists that category's commands |
| `kb list` | Lists the knowledge base articles |
| `zb report` | Prints the errors and warnings collected at startup |
| `zbr` | Reloads zshbop (`zbqr` for a quick reload) |
| `zbu` | Updates zshbop, then reloads |

Commands are registered in `help_<category>` arrays, so `help docker` lists the Docker commands and
`help checks` lists the available environment checks.

## Where things live

| Path | Holds |
|------|-------|
| `cmds/` | Command files, one per category (`cmds-git.zsh`, `cmds-docker.zsh`, …) |
| `checks/` | Environment checks (`checks-docker.zsh`, `checks-security.zsh`, …) |
| `lib/` | Initialization, logging, help, and shared functions |
| `kb/` | Knowledge base articles, readable with `kb <article>` and published on this site |
| `$HOME/.zshbop.conf` | Your configuration overrides |

## Next

- [Configuration](../reference/configuration.md) — the `$HOME/.zshbop.conf` options.
- [Updating](../guides/updating.md) — `zbu`, the update checks, and background repository sync.
- [Tab completion](../guides/tab-completion.md) — the completion flow you just installed.
