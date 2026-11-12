---
title: zshbop-cli
description: Use the bash-compatible zshbop-cli wrapper to run zshbop commands from bash or a script without sourcing zshbop into your shell.
---

`zshbop-cli` runs zshbop commands from a plain bash shell, without making zsh your login shell and
without sourcing zshbop into `.zshrc`.

## Requirements

- **zsh** — zshbop commands are zsh functions, so zsh executes them.
- **bash** — runs the wrapper itself.

## Install

The script sits in the root of a zshbop installation and is executable by default.

```bash
chmod +x /path/to/zshbop/zshbop-cli

# optional: system-wide access
sudo ln -s /path/to/zshbop/zshbop-cli /usr/local/bin/zshbop-cli
```

## Usage

```bash
./zshbop-cli <command> [arguments...]
```

```bash
./zshbop-cli domain google.com
./zshbop-cli dir-dircount /tmp
./zshbop-cli redis-info
./zshbop-cli check-dns-record example.com
./zshbop-cli docker-networks
./zshbop-cli whmcs-expiry-list -c /path/to/whmcs/configuration.php
./zshbop-cli whmcs-expiry-set -c /path/to/whmcs/configuration.php -i 112 -y 2029 -m 10
```

## Discovery

```bash
./zshbop-cli list-commands    # every command it can reach
./zshbop-cli help dir-dircount
./zshbop-cli version
./zshbop-cli --help
```

## Environment

| Variable | Effect |
|----------|--------|
| `DEBUG=1` | Debug output |
| `QUIET=1` | Suppress loading messages |

```bash
DEBUG=1 ./zshbop-cli dir-dircount /tmp
QUIET=1 ./zshbop-cli domain example.com
```

## How it works

1. The wrapper is bash, so it runs anywhere.
2. It scans the `cmds/` directory to find the available command files.
3. For a command, it writes a temporary zsh script that sets up the zshbop environment, sources the
   file containing the command, and runs it with your arguments.
4. The temporary script is removed afterwards.

## Limitations

- Features that need shell integration (prompt changes, interactive widgets) are unavailable.
- Commands that permanently modify a shell environment do not persist.
- Messages about help arrays during startup are normal and do not affect the command.

## Troubleshooting

```bash
# Is the command there at all?
./zshbop-cli list-commands | grep your-command

./zshbop-cli help your-command

# Permission and interpreter
chmod +x ./zshbop-cli
which zsh

# Ask it what it is doing
DEBUG=1 ./zshbop-cli your-command
```

## Adding a command

A command is visible to the wrapper as soon as it exists with a help entry:

1. Create the function in the matching `cmds/cmds-<category>.zsh` file.
2. Register it: `help_<category>[command-name]='Description'`.
3. Test with `./zshbop-cli your-new-command`.
