---
title: Installation
description: Install zshbop with the guided installer into your home directory, a system location, or a git checkout, and install the prompt font.
---

zshbop ships a guided installer that installs the packages it needs — zsh first — and then lays out
the configuration.

## Quick install

| Method | Command |
|--------|---------|
| Quick install | `bash <(curl -sL https://zshrc.pl)` |
| Fallback | `bash <(curl -sL https://raw.githubusercontent.com/jordantrizz/zshbop/master/install.sh)` |
| Next release | `bash <(curl -sL https://raw.githubusercontent.com/jordantrizz/zshbop/next-release/install.sh)` |

## Installer usage

```bash
Usage: install -h|-s (clean|skipdeps|default|home|git|)|(custom <branch> <location>)

  Options
    -h          - This help screen
    -s          - Skip all dependencies
    -o          - Skip optional software check
    -d          - Debug mode

  Commands

    clean                         - Remove zshbop
    default                       - Default install
    home                          - Install in home directory
    git                           - Install in ~/git with dev branch
    custom <branch> <location>    - Custom install

  Custom Install: * Note: Custom install skips optional software check
    branch (main|next-release)
    location (home|system|git)
        - home = $HOME/zshbop
        - system = /usr/local/sbin/zshbop
        - git = $HOME/git/zshbop
```

## Examples

```bash
# main branch into the home directory
bash <(curl -sL https://zshrc.pl) custom main home

# next-release into the system directory
bash <(curl -sL https://zshrc.pl) custom next-release system

# main branch as a git checkout in ~/git
bash <(curl -sL https://zshrc.pl) custom main git

# next-release into the system directory, skipping the optional software check
bash <(curl -sL https://zshrc.pl) -o custom next-release system
```

`custom main git` is the layout used for development: a real git checkout in `~/git/zshbop`, so the
next release can be tracked without touching a production shell.

## Requirements

- **zsh.** The installer installs it unless you pass `-s`.
- **git** and **curl.** The installers clone the repository with git and are themselves fetched with
  curl.
- **A patched font** for the Powerlevel10k prompt (below).

## Prompt font

The prompt needs a Nerd Font. Powerlevel10k recommends **MesloLGS NF**; the upstream instructions are
in the [powerlevel10k font guide](https://github.com/romkatv/powerlevel10k/blob/master/font.md).

Automatic: if you use iTerm2 or Termux, `p10k configure` offers to install the recommended font.

Manual, macOS:

```bash
cp fonts/* ~/Library/fonts
```

WSL: the font must be installed in Windows, not inside the distribution. The script below is the
one used here:

```bash
bash -c "$(curl -fsSL https://gist.githubusercontent.com/romkatv/aa7a70fe656d8b655e3c324eb10f6a8b/raw/install_meslo_wsl.sh)"
```

Windows Terminal: import the `windows_terminal.json` from the repository as a profile, then select
the MesloLGS NF face.

## Next

- [First run](./first-run.md) — what initialization does and the first commands to try.
- [Platforms](./platforms.md) — macOS, Windows, WSL, and CentOS notes.
