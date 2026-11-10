# ==============================================
# zsh commands
# ==============================================
_debug " -- Loading ${(%):-%N}"
help_files[zsh]='ZSH commands'
typeset -gA help_zsh

# -- Hide hostname and turn off ZSH autocomplete for recording
# ===============================================
# -- anonymize-shell
# ===============================================
help_zsh[anonymize-shell]='Hide hostname and turn off ZSH autocomplete for recording'
function anonymize-shell () {
	export HIDE_HOSTNAME=1
	export ZSH_AUTOSUGGEST_HISTORY_IGNORE="*"
	export EXCLUDE_P10K=(public_ip ip vpn_ip)
	export POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(${POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS:|EXCLUDE_P10K})

	p10k reload
	echo "Shell Anonymized"
}

# ===============================================
# -- debugz - return alias if binary exists for os
# ===============================================
help_zsh[debugz]='Debug ZSH Function'
function debugz() {
  local func_name="$1"
  shift

  PS4='+ ${FUNCNAME[0]}: line %l: '
  set -x
  $func_name "$@"
  set +x
}

# ===============================================
# -- zsh-list-comps
# ===============================================
help_zsh[zsh-list-comps]='List all zsh completions'
function zsh-list-comps() {
  for command in ${(k)_comps}; do
    completions=${_comps[$command]}
    printf "%-32s %s\n" $command $completions
  done
}

# ==============================================
# -- _zshbop_tab_complete_widget
# -- Widget name for $ZSHBOP_TAB_COMPLETE_MODE (cycle keeps the old behaviour)
# ==============================================
function _zshbop_tab_complete_widget () {
  case "${ZSHBOP_TAB_COMPLETE_MODE:-select}" in
    cycle) print -r -- menu-complete ;;
    *)     print -r -- expand-or-complete ;;
  esac
}

# ==============================================
# -- _zshbop_bind_tab_completion
# -- Bind Tab late so autosuggestions wraps the final widget once
# -- select/expand complete to the common prefix and list; select then opens a
# -- menu where Tab/Down move the highlight and Enter accepts
# ==============================================
function _zshbop_bind_tab_completion () {
  [[ $- != *i* ]] && return 0

  export ZSH_AUTOSUGGEST_MANUAL_REBIND=1

  local tab_mode="${ZSHBOP_TAB_COMPLETE_MODE:-select}"
  case "$tab_mode" in
    select|cycle|expand) ;;
    *)
      _warning "ZSHBOP_TAB_COMPLETE_MODE='$tab_mode' is not select|cycle|expand, using select"
      tab_mode="select"
      export ZSHBOP_TAB_COMPLETE_MODE="select"
      ;;
  esac

  # -- Menu selection needs zsh/complist; without it the mode degrades to a listing.
  # -- AUTO_MENU is required for `menu select` to engage at all: it drives the
  # -- sequence - complete as far as possible, list, then start menu selection.
  # -- expand turns it off so a repeated Tab only lists, never inserts a candidate.
  if [[ "$tab_mode" == "select" ]] && zmodload zsh/complist 2>/dev/null; then
    setopt auto_menu
    # -- Never override a menu zstyle the user set in .zshbop.conf
    if [[ -z "$(zstyle -L ':completion:*' menu 2>/dev/null)" ]]; then
      zstyle ':completion:*' menu select
    fi
  elif [[ "$tab_mode" == "expand" ]]; then
    unsetopt auto_menu
  fi

  local tab_widget="$(_zshbop_tab_complete_widget)"

  if (( $+commands[opencode] )) && whence -f _zshbop_opencode_query >/dev/null 2>&1; then
    # Integrate opencode AI: handle # lines with shared query function,
    # fall through to the configured completion widget for normal completion.
    function _zshbop_tab_handler() {
      if [[ "$BUFFER" == \#* ]]; then
        local prompt="${BUFFER#\#}"
        prompt="${prompt#"${prompt%%[![:space:]]*}"}"
        local cmd
        cmd="$(_zshbop_opencode_query "$prompt")"
        if [[ -n "$cmd" ]]; then
          BUFFER="$cmd"
          CURSOR=$#cmd
        else
          zle kill-whole-line
        fi
        zle reset-prompt
      else
        zle "$(_zshbop_tab_complete_widget)"
      fi
    }
    zle -N _zshbop_tab_handler
    bindkey '^I' _zshbop_tab_handler
  else
    bindkey '^I' "$tab_widget"
  fi

  if whence -f _zsh_autosuggest_bind_widgets >/dev/null 2>&1; then
    _zsh_autosuggest_bind_widgets
  fi
}
INIT_LAST_CORE+=("_zshbop_bind_tab_completion")