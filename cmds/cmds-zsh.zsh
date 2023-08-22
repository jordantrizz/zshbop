# ==============================================
# zsh commands
# ==============================================
_debug " -- Loading ${(%):-%N}"
help_files[zsh]='ZSH commands'
typeset -gA help_zsh

# -- Hide hostname and turn off ZSH autocomplete for recording
help_zsh[anonymize-shell]='Hide hostname and turn off ZSH autocomplete for recording'
function anonymize-shell () {
	export HIDE_HOSTNAME=1
	export ZSH_AUTOSUGGEST_HISTORY_IGNORE="*"
	export EXCLUDE_P10K=(public_ip ip vpn_ip)
	export POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(${POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS:|EXCLUDE_P10K})

	p10k reload
	echo "Shell Anonymized"
}

# -- debugz - return alias if binary exists for os
help_zsh[debugz]='Debug ZSH Function'
function debugz() {
  local func_name="$1"
  shift

  PS4='+ ${FUNCNAME[0]}: line %l: '
  set -x
  $func_name "$@"
  set +x
}