---
title: Environment checks
description: Every environment check registered in checks/, grouped by the file that defines it.
---

<!-- BEGIN GENERATED: commands-checks -->
:::info[Generated page]
Generated from `checks/checks-*.zsh` by `npm run gen:commands`. Edit the `help_checks`
entries in the source files, not this page.
:::

## Docker

Source: [`checks/checks-docker.zsh`](https://github.com/jordantrizz/zshbop/blob/next-release/checks/checks-docker.zsh) — 3 checks.

| Command | Description |
|---------|-------------|
| `docker-check-errors` | Checks for docker containers with errors |
| `docker-check-installed` | Checks if docker is installed |
| `docker-checks` | Run all checks for docker |

## Mac

Source: [`checks/checks-mac.zsh`](https://github.com/jordantrizz/zshbop/blob/next-release/checks/checks-mac.zsh) — 3 checks.

| Command | Description |
|---------|-------------|
| `mac-check-bash` | Checks if the current version of bash is above 4.0 |
| `mac-check-brew` | Checks if brew is installed |
| `mac-checks` | Run all checks for macOS |

## Security

Source: [`checks/checks-security.zsh`](https://github.com/jordantrizz/zshbop/blob/next-release/checks/checks-security.zsh) — 1 checks.

| Command | Description |
|---------|-------------|
| `hardcheck` | Security hardening audit (ssh, fail2ban, accounts, report) |

## Terminal

Source: [`checks/checks-terminal.zsh`](https://github.com/jordantrizz/zshbop/blob/next-release/checks/checks-terminal.zsh) — 5 checks.

| Command | Description |
|---------|-------------|
| `terminal-check-ai-pager` | Re-enable less paging in AI/agent terminals (VS Code Copilot) when ZSHBOP_AI_PAGER=1 |
| `terminal-check-detect` | Detects terminal emulator environment |
| `terminal-check-vscode` | Enables VSCode shell integration if available |
| `terminal-checks` | Run all checks for terminal environment |
| `terminal-disable-vscode-shell` | Disable VSCode shell integration when requested |

## Update

Source: [`checks/checks-update.zsh`](https://github.com/jordantrizz/zshbop/blob/next-release/checks/checks-update.zsh) — 2 checks.

| Command | Description |
|---------|-------------|
| `update-checks` | Run all checks for zshbop updates |
| `zshbop-check-update` | Check for zshbop updates (tags on main, commits on next-release) |

## Vm

Source: [`checks/checks-vm.zsh`](https://github.com/jordantrizz/zshbop/blob/next-release/checks/checks-vm.zsh) — 3 checks.

| Command | Description |
|---------|-------------|
| `vm-check-detect` | Am I in a VM? |
| `vm-check-detect-2` | Am I in a VM2? |
| `vm-checks` | Run all checks for VM |

## Zsh

Source: [`checks/checks-zsh.zsh`](https://github.com/jordantrizz/zshbop/blob/next-release/checks/checks-zsh.zsh) — 3 checks.

| Command | Description |
|---------|-------------|
| `zsh-check-history` | Check zsh history configuration |
| `zsh-check-version` | Check zsh version |
| `zsh-checks` | Run all checks for VM |

<!-- END GENERATED: commands-checks -->
