# Changelog

All notable changes to zshbop are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Fixed
- Preserve shell history when `ZSHBOP_BOOT_SKIP` skips plugins: `HISTFILE`,
  `HISTSIZE`, `SAVEHIST` and the history options are now configured in
  `lib/history.zsh`, independently of oh-my-zsh/antidote loading.

### Added
- `zsh-check-history` diagnostic (also run by `zshbop check`) reporting
  `HISTFILE`/`HISTSIZE`/`SAVEHIST` and warning when history is disabled.
