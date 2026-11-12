---
title: Roadmap
description: Where zshbop's backlog lives — the TODO file, GitHub issues, and the plans directory kept outside the public repository.
---

zshbop keeps its work in three places, deliberately separate from this site.

## TODO.md

The root `TODO.md` is the live backlog: current work, docksoft options, variables, testing notes, and
future ideas. It changes weekly, so it is linked rather than copied:

- [TODO.md on GitHub](https://github.com/jordantrizz/zshbop/blob/next-release/TODO.md)

## Issues

Bugs and requests belong in the issue tracker, not in the TODO file:

- [jordantrizz/zshbop issues](https://github.com/jordantrizz/zshbop/issues)

`zb issue` opens a new issue from the shell.

## Plans

Larger changes are planned as PGF (Plan Generation File) documents. The `plans/` entry in the
repository is a symlink to an external plans directory and is gitignored, so plan history is not part
of the public tree. A plan records the problem, the decisions, the phases, and the verification steps
before any code is written.

## See also

- [Release](./release.md) — how planned work becomes a version.
