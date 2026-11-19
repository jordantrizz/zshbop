<!-- Top Image -->
<p align="center"><img src="https://user-images.githubusercontent.com/345869/228565610-dbd52f13-ee2a-454a-84f8-9d3e0b2438c7.png" alt="ZSHBOP"></p>

This is my custom ZSH configuration. It uses antidote to install ZSH plugins.

<a href="https://jordantrask.com/coffee" target="_blank"><img src="https://cdn.buymeacoffee.com/buttons/default-orange.png" alt="Buy Me A Coffee" style="height: 51px !important;width: 217px !important;" ></a>
<!-- Top Image -->

**Documentation:** https://jordantrizz.github.io/zshbop/

<!-- BEGIN docs-index -->
| Section | Start here |
|---------|------------|
| Getting started | [What zshbop is](https://jordantrizz.github.io/zshbop/getting-started/what-is-zshbop) |
| Guides | [Tab completion](https://jordantrizz.github.io/zshbop/guides/tab-completion) |
| Command reference | [All commands](https://jordantrizz.github.io/zshbop/commands) |
| Configuration | [Options and variables](https://jordantrizz.github.io/zshbop/reference/configuration) |
| Contributing | [Development](https://jordantrizz.github.io/zshbop/contributing/development) |
| Knowledge base | [Articles](https://jordantrizz.github.io/zshbop/kb) |
| Changelog | [Release history](https://jordantrizz.github.io/zshbop/history/changelog) |
<!-- END docs-index -->

## Quick start

```bash
bash <(curl -sL https://zshrc.pl)
```

The guided installer asks its questions, installs zsh and the required packages, and lays out the
configuration. For a development checkout instead:

```bash
bash <(curl -sL https://zshrc.pl) custom main git
```

Then reload the shell and look around:

```bash
zbr        # reload zshbop
zb check   # environment check
help       # the zshbop help screen
kb docker  # a knowledge base article
```

## What it adds

- A customized Powerlevel10k prompt (it needs a patched font; see the installation page).
- Selectable Tab completion: Tab completes, lists, then opens a menu you move through.
- A knowledge base of short articles, readable with `kb <article>` and published on the site.
- Commands and aliases for Cloudflare, Docker, Git, WordPress, Linux, AWS, curl, and PHP.
- Environment checks, boot-time tracking, and terminal detection (VSCode, iTerm2, WezTerm, Windows
  Terminal).
- Docksoft container templates deployed from `templates/docksoft/`.

## Branches

| Branch | Purpose |
|--------|---------|
| `main` | Production releases, fully functional |
| `next-release` | Next release, may be broken |

## Contributing

- Conventions — file naming, help arrays, output functions, and the function template — are in
  `AGENTS.md` and on the site's development page.
- Tests: `zsh tests/test-*.zsh`, each printing a `N passed, N failed` summary.
- The documentation lives in `website/docs`. Before committing a change that touches it:

  ```bash
  cd website && npm run gen && npm run build
  cd .. && bash scripts/check-docs-site.sh --site website --repo-root .
  ```

- Bugs and requests: https://github.com/jordantrizz/zshbop/issues, or `zb issue` from the shell.
- Backlog: `TODO.md`.
