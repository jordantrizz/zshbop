---
title: Release
description: How zshbop is versioned and released — the VERSION file, tags, the changelog convention, and the branch model.
---

## Version source

`VERSION` at the repository root holds the current version (for example `4.4.9`), and releases are
tagged with the same number (`4.4.9`). The tag is the release: there is no build artifact, because
`install.sh` fetches the repository directly.

This repository ships no release script of its own. The steps below are performed by hand; if a
script is added, document it here and in `AGENTS.md`.

## Branch model

| Branch | Purpose |
|--------|---------|
| `main` | Production releases, fully functional. The docs site publishes from here. |
| `next-release` | The next release. May be broken. |

## Changelog

`CHANGELOG.md` follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/). Every user-visible
change gets a line under `## [Unreleased]`, in the matching heading:

| Heading | For |
|---------|-----|
| `Added` | new commands, options, and behaviour |
| `Changed` | different behaviour of something that already existed |
| `Fixed` | bugs |
| `Removed` | things that are gone |
| `Deprecated` | things that will go |

Write for the person upgrading: name the command or variable, say what changed, and name the switch
that restores the old behaviour when there is one.

## Release steps

1. Confirm the tree is clean and `main` is current.
2. Move the `Unreleased` entries under a new `## [<version>] - <date>` heading and leave
   `## [Unreleased]` empty.
3. Set `VERSION` to `<version>`.
4. Commit both files together.
5. Tag the commit with the bare version (`git tag 4.4.10`) and push the commit and the tag.
6. Check that the published docs match the release: the site deploys from `main`, and the generated
   pages are rebuilt by CI.

## Documentation is part of the release

A change that adds a command, an option, or a variable updates the documentation in the same
commit: the generated command reference picks up new `help_*` entries, `reference/configuration.md`
carries the option, and `CHANGELOG.md` explains the change.

## See also

- [Contributing](./development.md) — conventions for the code in a release.
- [Testing](./testing.md) — what to run before tagging.
