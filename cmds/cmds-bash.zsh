# -- bash
_debug " -- Loading ${(%):-%N}"
help_files[bash]="Bash Commands and scripts"
typeset -gA help_bash
_debug " -- Loading ${(%):-%N}"


# =====================================
# -- bash-add-history
# =====================================
help_bash[bash-add-history]='Update $HOME/.bashrc or file to add history tracking'
bash-add-history () {
    # Check if file was provided via $1
    if [[ -n "$1" ]]; then
        local BASHRC="$1"
    else
        # Default to $HOME/.bashrc if no file is provided
        local BASHRC="$HOME/.bashrc"
    fi

    if [[ -f $BASHRC ]]; then
        echo "Adding history tracking to $BASHRC"
        echo 'export HISTCONTROL=ignoredups:erasedups' >> $BASHRC
        echo 'export HISTSIZE=10000' >> $BASHRC
        echo 'export HISTFILESIZE=20000' >> $BASHRC
        echo 'shopt -s histappend' >> $BASHRC
        echo 'PROMPT_COMMAND="history -a; history -n"' >> $BASHRC
        echo "History tracking added. Please restart your terminal or source $BASHRC."
    else
        echo "Error: $BASHRC not found."
    fi
}