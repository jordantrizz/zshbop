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
# -- _zshbop_bind_menu_complete_tab
# -- Bind Tab late so autosuggestions wraps the final widget once
# ==============================================
function _zshbop_bind_menu_complete_tab () {
  [[ $- != *i* ]] && return 0

  export ZSH_AUTOSUGGEST_MANUAL_REBIND=1
  bindkey '^I' menu-complete

  if whence -f _zsh_autosuggest_bind_widgets >/dev/null 2>&1; then
    _zsh_autosuggest_bind_widgets
  fi
}
INIT_LAST_CORE+=("_zshbop_bind_menu_complete_tab")