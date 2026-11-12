---
title: What zshbop is
description: An overview of zshbop — a custom Zsh configuration built on Antidote and Powerlevel10k, with checks, commands, and a knowledge base.
---

zshbop is a custom Zsh configuration. It exists to improve one person's workflow and is published in
case the same problems are yours: a shell that loads quickly, knows which terminal it is in, and
carries the commands used to run servers.

It is built on:

- [Oh My Zsh](https://ohmyz.sh/) for the plugin ecosystem and conventions
- [Antidote](https://github.com/mattmc3/antidote) for plugin loading
- [Antigen](https://github.com/zsh-users/antigen) alongside it for compatibility
- [Powerlevel10k](https://github.com/romkatv/powerlevel10k) for the prompt

## What it adds

- **A knowledge base.** The `kb` command opens short articles on topics such as Docker, CSF, SSL,
  WordPress, Proxmox, and GridPane. The same articles are published in the
  [knowledge base](../kb/index.md).
- **Commands and aliases.** Cloudflare, Docker, Git, WordPress, Linux, AWS, curl, and PHP workflows,
  each registered in a help array so `help <category>` lists them. They are all listed in the
  [command reference](../commands/index.md).
- **Checks.** Environment checks for Docker, terminal, security, updates, VMs, and Zsh, run from
  `zb check`.
- **Boot timing.** Optional tracking of how long the shell takes to start, with microsecond
  precision.
- **Terminal detection.** VSCode, iTerm2, WezTerm, and Windows Terminal are recognised.
- **Selectable Tab completion.** Tab completes, lists, then opens a menu you move through.

## Branches

| Branch | Purpose |
|--------|---------|
| `main` | Production releases, fully functional |
| `next-release` | Next release, may be broken |

## Where to go next

- [Tab completion](../guides/tab-completion.md) — the completion flow this configuration installs.
