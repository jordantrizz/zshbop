# --------------------------------------------------
# -- plik-conf
# --------------------------------------------------
help_software[plik-conf]='Print out .plikrc'
function plik-conf () {
    if [[ ! -f $HOME/.plikrc ]]; then
        _error "No $HOME/.plikrc exists"
        return 1
    else
        PLIKRC=$(cat $HOME/.plikrc)
        echo "echo '${PLIKRC}' > \$HOME/.plikrc"
    fi
}
