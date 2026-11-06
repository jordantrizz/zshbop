# Changelog

All notable changes to zshbop are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Added
- `zshbop update`/`zbu` now sync `$ZSHBOP_UPDATE_GIT` repositories in a detached
  background worker instead of blocking the update (and the MOTD update prompt) on
  every mirror. The shell returns immediately with one line, and a single summary
  appears at the next prompt — silent when every repository was already current.
  `ZSHBOP_UPDATE_GIT_BACKGROUND=0` restores the blocking loop,
  `ZSHBOP_UPDATE_GIT_NOTIFY=0` silences the summary, and
  `ZSHBOP_UPDATE_GIT_TIMEOUT` (default 300s) decides when a stuck worker is
  treated as dead.
- `zb update-status` reports the background sync: running or idle state, per-repository
  results, counts, and — with `-l`/`--log` or `-j`/`--json` — the run log or a
  machine-readable document.
- Quiet repo sync helper: every synced repository reports one line
  (`up to date`, `updated (+N commits)`, `reset to origin/<branch>`) and never
  streams git fetch progress or `hint:` advice; failures produce one error line.
  Diverged mirrors are reset to their upstream, and a dirty worktree blocks the
  reset instead of discarding work.

### Fixed
- Full reloads (`zbr`/`zbur`) now re-read `.zshbop.conf` so additional packages
  registered through `ZSHBOP_CUSTOM_SOURCES` keep their commands after the shell restarts.
- `dom`/`domain-info` no longer print a blank `Nameservers:` line when a domain's
  authoritative nameservers are down. They now fall back to the parent-zone registry
  delegation (tagged `registry delegation; nameservers not responding`), warn on
  `SERVFAIL`/`REFUSED`, and show `DNS UNAVAILABLE` instead of a spurious "No record
  found" for SPF, DMARC and DKIM.
- `software glint` now installs an arm64 build on linux-arm64 (via `cargo install glint`) instead of
  downloading the x86_64 `glint-linux` binary, which failed with `exec format error` on arm64 hosts.
  Glint binaries now use arch-suffixed `os-binary` naming (`glint-linux_x86_64`, `glint-mac_x86_64`),
  and `os-binary` no longer falls back to a generic `-linux` binary on linux-arm64.
- Preserve shell history when `ZSHBOP_BOOT_SKIP` skips plugins: `HISTFILE`,
  `HISTSIZE`, `SAVEHIST` and the history options are now configured in
  `lib/history.zsh`, independently of oh-my-zsh/antidote loading.

### Known Issues
- **WSL arm64:** the glint arm64 fix does not apply inside WSL, because `init.zsh` overwrites
  `MACHINE_OS2` to `wsl` (instead of `linux-arm64`), so a WSL arm64 host still downloads the x86_64
  `glint-linux` binary and hits `exec format error`. Follow-up tracked in
  `plans/20260911-glint-wsl-arm64-fallback.md`.

### Added
- `genpass alnumnix` (alias `genpass-alnumnix`): generates passwords from alphanumerics
  plus special characters that are inert to POSIX shells even when unquoted and without
  history expansion (`% + , - . / : @ _`). Quotes, backslash, backtick, `$`, `!`, `#`,
  `~`, `=`, `;`, `&`, `|`, redirection, brackets, braces, parentheses, glob and
  whitespace are excluded. Length defaults to 32; accepts `[length] [count]`. Also
  included in the untyped `genpass` summary.
- Interactive MOTD update prompt: on an interactive full boot, when an update is
  available `zshbop_update_prompt` asks whether to update and, on confirmation, runs
  the full update and reloads zshbop. It is skipped for non-interactive shells,
  non-writable (system) installs, and repositories with uncommitted changes.
  Disable with `ZSHBOP_UPDATE_PROMPT=0`.
- `zsh-check-history` diagnostic (also run by `zshbop check`) reporting
  `HISTFILE`/`HISTSIZE`/`SAVEHIST` and warning when history is disabled.
