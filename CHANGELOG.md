# Changelog

All notable changes to zshbop are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Fixed
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
- `zsh-check-history` diagnostic (also run by `zshbop check`) reporting
  `HISTFILE`/`HISTSIZE`/`SAVEHIST` and warning when history is disabled.
