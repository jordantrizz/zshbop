---
title: Testing
description: The zshbop test scripts, what each one covers, how to run them, and how to check the shell environment.
---

Tests are Zsh scripts under `tests/`, each self-contained and safe to run from the repository root.

## Running them

```bash
cd /path/to/zshbop
zsh tests/test-tab-completion.zsh
```

Each script prints one `ok`/`FAIL` line per case and a summary:

```text
Results: 23 passed, 0 failed
```

The exit status is `0` only when every case passed, so a loop can stop on the first failure:

```bash
for t in tests/test-*.zsh; do
    zsh "$t" || { echo "FAILED: $t"; break; }
done
```

## What exists

| Script | Covers |
|--------|--------|
| `tests/test-tab-completion.zsh` | the three `ZSHBOP_TAB_COMPLETE_MODE` flows, `Ctrl-G`, the `#` query branch, and the unknown-mode fallback |
| `tests/test-update-prompt.zsh` | the MOTD update prompt: yes, no, failed update, and reload behaviour |
| `tests/test-repo-update-background.zsh` | the background `$ZSHBOP_UPDATE_GIT` worker and its summary |
| `tests/test-git-sync-repo.zsh` | the quiet repository sync helper: one line per repository, failures, and skipped paths |
| `tests/test-glint-install.zsh` | the glint installation path |

Two standalone timing scripts live at the repository root:

| Script | Covers |
|--------|--------|
| `test-init-os-timing.zsh` | `_time_step` entries and microsecond precision during OS initialization |
| `test-boot-timing.zsh` | boot-time measurement end to end |

## Environment checks

The automated tests cover behaviour; `zshbop check` covers the machine.

```bash
zb check              # installed software and tools
zb check-system       # errors and warnings
zsh-check-history     # history settings at the current boot level
```

## Testing on a clean host

When a change touches the installer or startup, test it in a throwaway container rather than on your
own shell: see [Test containers](../guides/test-containers.md).

## See also

- [Development](./development.md) — the conventions a new test should follow.
- [Boot timing](../guides/boot-timing.md) — what the timing scripts measure.
