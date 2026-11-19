---
title: Documentation
description: The contract for zshbop's documentation site — where pages live, what is generated, the front-matter and link rules, and the gate every docs change runs.
---

The manual is this site, not the README. The README is a doorway; pages here are the manual. `kb/` and
the command reference are generated from their real sources so the shell and the site cannot drift.

## Where things live

| Path | Holds |
|------|-------|
| `website/` | The Docusaurus project: config, sidebar, generators' output |
| `website/docs/` | Every page. Curated pages are hand-written; `commands/`, `kb/`, and `history/changelog.md` are generated |
| `website/sidebars.ts` | The one sidebar. Curated entries by hand, generated blocks between markers |
| `kb/` | The shell knowledge base (`kb <article>`) — the source the site mirrors |
| `cmds/`, `checks/`, `lib/` | Command sources; the reference is built from their `help_*` arrays |
| `CHANGELOG.md` | The curated changelog mirrored into `history/changelog.md` |
| `scripts/docs/` | The generators (`gen-commands`, `gen-kb`, `gen-changelog`, `gen-readme`, shared `lib.sh`) |
| `scripts/check-docs-site.sh` | The gate: it decides whether the site is publishable |

## Curated and generated pages

A generated page says so at the top and carries a marker pair:

```text
<!-- BEGIN GENERATED: kb-docker -->
...
<!-- END GENERATED: kb-docker -->
```

Editing between those markers is a defect: the next `npm run gen` reverts it. Change the source
instead, and regenerate:

| Generated page | Source | Regenerate |
|----------------|--------|------------|
| `commands/**` | `help_*` arrays in `cmds/`, `checks/`, `lib/` | `npm run gen:commands` |
| `kb/**` | `kb/*.md` and the article index | `npm run gen:kb` |
| `history/changelog.md` | `CHANGELOG.md` | `npm run gen:changelog` |
| README `docs-index` block | the section map | `npm run gen:readme` |
| `sidebars-commands`, `sidebars-kb` | the same command and kb sources | the two generators above |

`npm run gen` runs all four in order. CI reruns them and fails when the committed output differs.

## Writing a page

1. Create the file under `website/docs/<section>/<page>.md` with front matter:

   ```markdown
   ---
   title: Installing the CLI
   description: One sentence a search result can show.
   ---
   ```

   `title` becomes the page heading; do not add a body `# Title` under it. `description` is required —
   the gate fails without it.

2. Register the page in `website/sidebars.ts`, in exactly one category, in reading order. A page that
   is not in the sidebar fails the gate as an orphan; an entry without a page fails as dangling.

3. Link other pages relatively and keep the extension: `./installation.md`,
   `../reference/configuration.md`. Never start a link with `/` — the project site is served from
   `/zshbop/`, so a root-absolute link 404s. Repository files are linked on GitHub
   (`https://github.com/jordantrizz/zshbop/blob/next-release/<path>`).

4. Use `.md` for prose. It is parsed as CommonMark, so braces and angle brackets are literal text.
   `.mdx` is available when a page genuinely needs JSX.

## When the source changes

| Change | Do this |
|--------|---------|
| New or changed command, or its `help_*` entry | Edit the array, then `npm run gen:commands` |
| New or edited article in `kb/` | Edit the article, then `npm run gen:kb` |
| New option, variable, or default | Add it to `reference/configuration.md` |
| Behaviour change | Update the guide that describes it **and** `CHANGELOG.md`, then `npm run gen:changelog` |
| Retired page | Move the content to `history/` with the date in the title; do not delete it |
| Release | Add `CHANGELOG.md` entries under `## [Unreleased]` |

## The gate

```bash
cd website && npm run gen && npm run build && npm run typecheck
cd .. && bash scripts/check-docs-site.sh --site website --repo-root .
```

It checks, among other things: `url`/`baseUrl` and all three broken-link guards set to `throw`, exact
Docusaurus pins and a committed lockfile, ignored build output, front matter on every page, the sidebar
in both directions, relative links and no slash-leading links, the README budget and its marker pair,
the Pages workflow's permissions, and that the search index exists with URLs under `baseUrl`.

The build itself is strict: a broken link, a broken anchor, or a broken markdown link fails it. A
green build with a warning is not the goal — `onBrokenLinks`, `onBrokenAnchors`, and
`onBrokenMarkdownLinks` all throw.

## Publishing

`.github/workflows/docs.yml` runs the gate on every push to `main` or `next-release` and on pull
requests. Only `main` deploys, to `https://jordantrizz.github.io/zshbop/`. The artifact upload does not
run Jekyll, so there is no `.nojekyll` file and there should not be one.

## See also

- [Development](./development.md) — the Zsh conventions behind the commands these pages describe.
- [Release](./release.md) — where the changelog and version come from.
