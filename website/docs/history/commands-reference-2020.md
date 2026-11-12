---
title: Command reference (2020, retired)
description: The 2020 commands and aliases reference, kept for history. It predates the generated command reference and is no longer maintained.
---

This page is the retired `help/commands.md`, dated 2020. It lists the commands and aliases that
existed then, under headings that no longer match the `cmds/` files, and it predates the generated
command reference that replaced it.

:::warning[Superseded]
Use the generated command reference instead. It is built from the `help_*` arrays in `cmds/` and
`checks/`, so it always matches the code.
:::

The original text began: "Type `commands` or `aliases` to get a list of commands and aliases.
Doesn't work yet."

## Core

| Alias | Description |
|-------|-------------|
| `update` | Update this repository and pull down any updates from sub-modules |
| `setupenv` | Install the necessary packages |
| `pk` | Print out all public keys in the `.ssh` folder |

## General

| Alias | Description |
|-------|-------------|
| `fdcount` | Count of files and directories in the current directory |
| `update` | Update this repository and pull down any updates from sub-modules |
| `setup-environment` | Install the necessary packages |
| `whatismyip` | Check OpenDNS and report the external IP address |
| `listen` | What's listening on what port |
| `vh` | Use curl to test virtual hosts before a migration |

## Coding

| Command | Description |
|---------|-------------|
| `toc` | Run the patched `gh-md-toc` with `--nobackup-insert` on the current directory's `README.md` |

## Binaries

- `check-if-email-exists` — [reacherhq/check-if-email-exists](https://github.com/reacherhq/check-if-email-exists)

## Web

| Command | Description |
|---------|-------------|
| `ttfb` | Time to first byte, using curl |
| `error_log` | Recursively find `error_log` files and tail them |
| `rm_error_log` | Recursively find `error_log` files and prompt to delete them |
| `phpinfo` | Generate a `phpinfo.php` file |
| `dhparam` | Generate a Diffie-Hellman key exchange |
| `msds` | MySQL dump search |

## Ubuntu/Debian specific

| Command | Description |
|---------|-------------|
| `apt-select` | Get the fastest Ubuntu/Debian mirror |
| `setup-cloud` | Update hostname, preserve the address in `cloud.cfg`, fix the resolv.conf bug (written in bash) |

## Exim

| Command | Description |
|---------|-------------|
| `eximcq` | Clear the Exim queue of messages |

## WSL

| Command | Description |
|---------|-------------|
| `wsl-screen-fix` | Fix the screen error "Cannot make directory '/var/run/screen': Permission denied" after a reboot |
