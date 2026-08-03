# 20260803-software-raid-check-motd-and-log-review

**Status:** ✅ Implemented (2026-08-03)
**Commit:** `9c9774a` — `feat: add motd mode and 48h raid log review`

## Phases

### Phase 1: Add MOTD-Safe Execution Mode

**Goal:** Preserve the existing MOTD behavior while introducing an explicit mode that only prints the status summary.

#### Tasks
- [x] Add `--motd` option to `software-raid-check`.
- [x] Keep MOTD output status-only in `--motd` mode.
- [x] Update MOTD initialization to call `software-raid-check --motd`.
- [x] **Validation:** Run shell syntax checks and confirm MOTD path still prints status summary without extended log output.

### Phase 2: Extend Default Command Behavior With 48-Hour RAID Log Review

**Goal:** Make normal `software-raid-check` runs include RAID-related diagnostics from the last 48 hours.

#### Tasks
- [x] Add journal review using `journalctl --since "48 hours ago"` and RAID-related filters.
- [x] Add additional log-source checks via `dmesg` and common system log files.
- [x] Keep output bounded with `tail` to avoid overwhelming terminal output.
- [x] **Validation:** Run command in a shell and confirm log sections are shown for non-MOTD runs and skipped for MOTD runs.

### Phase 3: Hardening And CLI Consistency

**Goal:** Align command option parsing with project conventions and improve resilience.

#### Tasks
- [x] Replace `getopts` usage with `zparseopts` for this function.
- [x] Add `-h|--help` usage output.
- [x] Improve parsing of `/proc/mdstat` and RAID status extraction via `awk`.
- [x] **Validation:** Verify command handles missing/empty values cleanly and exits successfully when no arrays are present.
