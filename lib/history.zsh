# =============================================================================
# -- history.zsh -- plugin-independent zsh history configuration
# =============================================================================
# -- Sets HISTFILE/HISTSIZE/SAVEHIST and the history options regardless of
# -- whether the plugin manager (oh-my-zsh/antidote) is loaded. This keeps
# -- history working under ZSHBOP_BOOT_SKIP levels that skip the plugins
# -- component, where oh-my-zsh's lib/history.zsh never runs.

# -- History file and sizes (defaults only; user overrides win)
# -- HISTFILE is unset by default, but HISTSIZE/SAVEHIST are not: zsh gives
# -- them the non-empty defaults 30/0, so ${VAR:=...} would never apply. Only
# -- replace those two when they still hold the stock zsh defaults.
[[ -z "$HISTFILE" ]] && HISTFILE="$HOME/.zsh_history"
(( HISTSIZE == 30 )) && HISTSIZE=5000
(( SAVEHIST == 0 )) && SAVEHIST=10000
export HISTFILE HISTSIZE SAVEHIST

# -- History options
setopt extended_history       # record timestamp of command in HISTFILE
setopt hist_expire_dups_first # delete duplicates first when HISTFILE size exceeds HISTSIZE
setopt hist_ignore_all_dups   # remove older duplicate entries from the history
setopt hist_ignore_dups       # ignore duplicated commands history list
setopt hist_ignore_space      # ignore commands that start with space
setopt hist_reduce_blanks     # remove superfluous blanks from history items
setopt hist_save_no_dups      # do not write a duplicate event to the history file
setopt hist_verify            # show command with history expansion to user before running it
setopt share_history          # share command history data
setopt inc_append_history     # allow multiple terminal sessions to append to one history
