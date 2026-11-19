---
title: Tab completion
description: How zshbop binds Tab to complete, list, then a selectable menu, and how ZSHBOP_TAB_COMPLETE_MODE changes that flow.
---

Tab is bound to a completion flow that lets you pick a candidate instead of silently taking the
first one.

1. The first Tab completes the word as far as it is unambiguous (`vm2` becomes `vm2-`).
2. The next Tab lists the candidates.
3. The next Tab opens a menu: Tab or the down/up arrows move the highlight, Enter accepts it, and
   `Ctrl-G` cancels back to what you typed.

This needs `zsh/complist` (loaded for you) and the `menu select` completion style; `AUTO_MENU` is
turned on because menu selection does not engage without it.

## Modes

Set `ZSHBOP_TAB_COMPLETE_MODE` before zshbop loads to choose a different flow:

| Value | Behaviour |
|-------|-----------|
| unset (default) | complete, list, then a selectable menu |
| `cycle` | each Tab inserts the next candidate (the previous `menu-complete` behaviour) |
| `expand` | plain zsh behaviour: complete and list, never insert from a menu |

```zsh
# ~/.zshrc.local or any file sourced before zshbop
export ZSHBOP_TAB_COMPLETE_MODE=cycle
```

## The `#` line

Lines starting with `#` are not completed: they are handed to the opencode query instead.
