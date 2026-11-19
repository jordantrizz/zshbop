---
title: Configuration
description: The $HOME/.zshbop.conf file, every documented ZSHBOP_ option, exbin settings, internal variables, and custom startup hooks.
---

Copy the example and edit it:

```bash
cp .zshbop.conf.example "$HOME/.zshbop.conf"
```

The file is sourced early, before zshbop's helper commands exist. Change `PATH` directly there:

```zsh
PATH="$PATH:$HOME/my/bin"
```

Use `add-path` interactively after startup instead; it relies on helpers the config file cannot call
yet.

When `ZBC` is set, zshbop sets `ZBC_ROOT` to the same value, adds `$ZBC/zbc.zsh` to
`ZSHBOP_CUSTOM_SOURCES` (deduplicated), and syncs it during `zb update` through the quiet repo sync
helper: a git checkout reports one line (`up to date`, `updated (+N commits)`, `reset to
origin/<branch>`), and a plain directory is reported as skipped instead of producing a
`fatal: not a git repository`.

## Options

| Variable | Description | Values | Default |
|----------|-------------|--------|---------|
| `ZSHBOP_ROOT` | Location of the zshbop installation | String | Detected |
| `ZSHBOP_CUSTOM_SSHKEY` | Custom SSH key to load | String | Detected |
| `ZSHBOP_PLUGIN_MANAGER` | Override the plugin manager: `init_antidote` or `init_antigen` | String | `init_antidote` |
| `ZSHBOP_PLUGIN_ZSH_AI_ENABLE` | Enable the `matheusml/zsh-ai` plugin | 0 or 1 | 0 |
| `ZSHBOP_PLUGIN_ZSH_AI_ACCEPT_LINE_ENABLE` | Let zsh-ai own Enter for `# query` mode; when 0, `zsh-ai "query"` still works | 0 or 1 | 0 |
| `ZSHBOP_PLUGIN_ZSH_AUTOCOMPLETE_ENABLE` | Enable `marlonrichert/zsh-autocomplete` | 0 or 1 | 0 |
| `ZSHBOP_ANTIDOTE_BUNDLES` | Extra antidote bundles (`owner/repo`) appended to the plugin list | Array | `()` |
| `ZSHBOP_GIT_CHECK` | On logout, check `$GIT_HOME` repositories for uncommitted code | Number | 1 |
| `GIT_HOME` | Where your git repositories live | String | `$HOME/git` |
| `ZSHBOP_UPDATE_GIT` | Repositories to update on `zbu`; synced in a detached background worker by default | Array | `${HOME}/git/cloudflare-cli ${GIT_HOME}/plik` |
| `ZSHBOP_UPDATE_GIT_BACKGROUND` | Sync `$ZSHBOP_UPDATE_GIT` in the background; `0` restores the blocking foreground loop | 0 or 1 | 1 |
| `ZSHBOP_UPDATE_GIT_NOTIFY` | Print one summary line at the next prompt when the background sync finishes | 0 or 1 | 1 |
| `ZSHBOP_UPDATE_GIT_TIMEOUT` | Seconds after which a background sync is treated as dead | Number | 300 |
| `ZSHBOP_UPDATE_PROMPT` | Prompt to update in the MOTD when an update is available | 0 or 1 | 1 |
| `ZSH_IP_PROVIDER` | IP provider used by zshbop | String | e.g. `ipinfo.io` |
| `ZSH_IP_API_KEY` | API key for the `ip-info` command | String | |
| `ZSHBOP_TERMINAL` | Detected terminal environment (read-only) | String | `vscode`, `iterm`, `wezterm`, `windows-terminal`, `unknown` |
| `ZSHBOP_DISABLE_VSCODE_SHELL` | Disable VSCode shell integration | 0 or 1 | not set |
| `ZSHBOP_AI_PAGER` | Re-enable `less` paging in VSCode AI/agent terminals | 0 or 1 | not set (disabled) |
| `ZSHBOP_BOOT_SKIP` | Quick boot level: `1` skips MOTD and system checks, `2` also skips checks/plugins/ssh/kb | 1 or 2 | not set (full boot) |
| `ZSHBOP_BOOT_SKIP_ITEMS` | Items to skip (`motd checks plugins ssh kb software`); overrides the level | Array | `()` |
| `ZSHBOP_BOOT_FULL` | Force a full boot regardless of the skip settings | 0 or 1 | not set |
| `ZSHBOP_P10K_QUICK_BOOT` | Load powerlevel10k during quick boot, standalone; `0` restores the plain prompt | 0 or 1 | 1 |
| `ZSHBOP_TAB_COMPLETE_MODE` | Tab behaviour: `select`, `cycle`, or `expand` | String | `select` |
| `ZSHBOP_NVM_ENABLE` | Enable NVM initialization | 1 | not set |
| `ZSHBOP_NVM_LAZY` | Lazy-load NVM on first use of `nvm`/`node`/`npm`/`npx` | 0 or 1 | 1 (when enabled) |
| `NVM_DIR` | Override the NVM directory | String | `$HOME/.nvm` |
| `ZSHBOP_BASHER_DISABLE` | Disable Basher auto-initialization | 1 | not set (auto-enabled when `~/.basher` exists) |

Two behaviours are independent of `ZSHBOP_BOOT_SKIP`:

- **History** (`HISTFILE`, `HISTSIZE`, `SAVEHIST` and the history options) is configured outside the
  plugin manager, so it survives every quick-boot level, including level 2 which skips plugins. Run
  `zsh-check-history` (also part of `zshbop check`) to inspect it.
- **The prompt** stays active at every level. When the `plugins` component is skipped, p10k is loaded
  standalone; set `ZSHBOP_P10K_QUICK_BOOT=0` for the plain prompt instead.

## Exbin

[Exbin](https://exbin.call-cc.be) uploads text to a paste service.

| Variable | Description | Values | Default |
|----------|-------------|--------|---------|
| `EXBIN_TYPE` | `netcat` or `api` | String | `netcat` |
| `EXBIN_HOST` | Hostname for netcat, full URL for api | String | `exbin.call-cc.be` |
| `EXBIN_PORT` | Non-standard netcat port | Number | `9999` |

## Internal variables

Set by zshbop and available to scripts and functions.

| Variable | Description | Set by |
|----------|-------------|--------|
| `WINDOWS_USER` | Windows username, detected through `cmd.exe` or `powershell.exe` (WSL only) | `_wsl_get_windows_user` |

## Custom startup

Uncomment `init_custom_startup` in `$HOME/.zshbop.conf` to run your own code when zshbop starts:

```zsh
function init_custom_startup () {

}
```

## See also

- [First run](../getting-started/first-run.md) — what initialization does with these settings.
- [Updating](../guides/updating.md) — the update and repository sync switches in practice.
- [Tab completion](../guides/tab-completion.md) — `ZSHBOP_TAB_COMPLETE_MODE` in detail.
