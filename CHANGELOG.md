# Changelog

All notable changes to zshbop are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Added
- A documentation site at https://jordantrizz.github.io/zshbop/, built with Docusaurus 3 in `website/`:
  getting started, guides, a generated command reference, a configuration reference, contributing,
  a generated knowledge-base mirror, and history — with client-side search and a GitHub Pages workflow
  that publishes from `main`.
- `npm run gen` and `scripts/docs/` generate the command reference (from the `help_*` arrays in
  `cmds/`, `checks/`, and `lib/`), the knowledge-base pages (from `kb/`), the changelog page, and the
  README's docs index. `scripts/check-docs-site.sh` gates every documentation change, and CI fails when
  a generator's committed output differs from a fresh run.
- `AGENTS.md` documents the contract — what is generated, what to update for a given change, and the
  gate to run — with the full version on the site at `contributing/documentation`.
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

### Changed
- `README.md` is a 75-line doorway to the site (was 505 lines): command tables, install variants,
  configuration, platform notes, and debugging detail now live there.
- `doc/`, `help/commands.md`, `help/ls.md`, `README-zshbop-cli.md`, and `TESTING.md` were retired —
  their content moved to the site, `doc/todo.md` merged into `TODO.md`, and `temp.md` was removed as a
  stale copy of an older `AGENTS.md`.
- Tab completion now lets you pick a candidate instead of inserting the first one. Tab completes as
  far as possible, the next Tab lists the matches, and the next opens a menu where Tab or the arrows
  move the highlight and Enter accepts it; `Ctrl-G` cancels back to what you typed. The old
  `menu-complete` behaviour is one setting away with `ZSHBOP_TAB_COMPLETE_MODE=cycle` (`expand` gives
  the plain complete-and-list flow). This loads `zsh/complist` and sets the `menu select` completion
  style, and enables `AUTO_MENU` because menu selection does not engage without it. The `#`-line
  opencode query is unchanged.

### Fixed
- `kb/azure.kb` is now `kb/azure.md`, so `kb azure` finds the article and the site includes it.
- Removed dead table-of-contents links in `kb/enhance.md` and `kb/gridpane.md`, and backticked four
  placeholder lines (`<antidote>`, `<profile_name>`, `<patch_file>`, `<title> <data>`) that rendered as
  invisible HTML tags.
- The README's boot-timing link pointed at `doc/BOOT_TIMING.md`, which never existed; it now points at
  the published guide.
- `zshbop update` and `repos update` now sync every repository through one quiet helper:
  each repository reports a single line (`up to date`, `updated (+N commits)`,
  `reset to origin/<branch>`) and never streams git fetch progress, `remote:` lines or
  the multi-line `hint:` advice block. Failures produce one error line carrying the
  reason, `repos update` returns non-zero when a repository failed, and a `$ZBC`
  directory that is not a checkout is reported as skipped instead of
  `fatal: not a git repository`. Diverged mirrors are reset to their upstream, a dirty
  worktree blocks that reset instead of discarding work, and `ZSHBOP_UPDATE_VERBOSE=1`
  restores the raw git output.
- `$ZSHBOP_UPDATE_GIT` entries are resolved against both `$HOME` and `$GIT_HOME`; the old
  probe tested `$GIT_HOME/$entry` but assigned the `$HOME` path, so a relative entry never
  resolved correctly.
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
- `backup` takes `-g`/`--gb <size>` to split the archive into parts of that many gigabytes, and
  `-p`/`--part <size>` now sizes its parts the same way: a bare number is megabytes (unchanged
  default), while a `k`, `m`, `g` or `t` suffix sets the unit explicitly (`backup -p 1536m`,
  `backup -g 2`). Also adds `-h`/`--help`, rejects a missing folder or a non-numeric size before
  touching the disk, warns before overwriting parts from an earlier run of the same day, and fails
  the run when `tar` fails mid-pipeline instead of leaving a partial set of parts.
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
