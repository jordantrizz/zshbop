# ==================================================
# -- password generation commands
# ==================================================
_debug " -- Loading ${(%):-%N}"
help_files[passwords]='Password generation commands'
typeset -gA help_passwords

zmodload zsh/system zsh/mathfunc 2>/dev/null

# ==============================================
# -- _genpass_error - print error to stderr (works standalone)
# ==============================================
function _genpass_error () {
    if (( $+functions[_error] )); then
        _error "$@"
    else
        print -ru2 -- "$@"
    fi
}

# ==============================================
# -- _genpass_rand - set REPLY to a uniform random integer in [1, max]
# ==============================================
function _genpass_rand () {
    local max=$1 c
    while true; do
        sysread -s1 c < /dev/urandom || return 1
        # Avoid bias towards smaller numbers (rejection sampling)
        (( #c < 256 / max * max )) && break
    done
    typeset -g REPLY=$(( #c % max + 1 ))
}

# ==============================================
# -- _genpass_entropy - print entropy in bits for a charset size and length
# ==============================================
function _genpass_entropy () {
    local charset_size=$1 length=$2
    local -F 1 bits
    bits=$(( length * log(charset_size) / log(2) ))
    if (( bits == int(bits) )); then
        print -rn -- "(${bits%.*} bits)"
    else
        print -rn -- "(${bits} bits)"
    fi
}

# ==================================================
# -- genpass-alnum - generate alphanumeric password (no special chars)
# ==================================================
help_passwords[genpass-alnum]='Generate alphanumeric password (no special chars)'
function genpass-alnum () {
    local -a opts_help
    zparseopts -D -E -- h=opts_help -help=opts_help
    if [[ -n $opts_help ]]; then
        echo "Usage: genpass-alnum [length] [count]"
        return 0
    fi

    local length=${1:-32} count=${2:-1}
    if [[ $length != <1-10000> ]]; then
        _genpass_error "genpass-alnum: invalid length: $length (must be 1-10000)"
        return 1
    fi
    if [[ $count != <1-1000> ]]; then
        _genpass_error "genpass-alnum: invalid count: $count (must be 1-1000)"
        return 1
    fi

    local -r chars='abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
    local REPLY i j pwd
    for (( i = 0; i < count; i++ )); do
        pwd=''
        for (( j = 0; j < length; j++ )); do
            _genpass_rand $#chars || return 1
            pwd+=$chars[REPLY]
        done
        print -r -- "$pwd $(_genpass_entropy $#chars $length)"
    done
}

# ==================================================
# -- genpass-special - generate password with special chars (printable ASCII)
# ==================================================
help_passwords[genpass-special]='Generate password with special chars (printable ASCII)'
function genpass-special () {
    local -a opts_help
    zparseopts -D -E -- h=opts_help -help=opts_help
    if [[ -n $opts_help ]]; then
        echo "Usage: genpass-special [length] [count]"
        return 0
    fi

    local length=${1:-32} count=${2:-1}
    if [[ $length != <1-10000> ]]; then
        _genpass_error "genpass-special: invalid length: $length (must be 1-10000)"
        return 1
    fi
    if [[ $count != <1-1000> ]]; then
        _genpass_error "genpass-special: invalid count: $count (must be 1-1000)"
        return 1
    fi

    local -r chars=$'!\"#$%&\'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~'
    local REPLY i j pwd
    for (( i = 0; i < count; i++ )); do
        pwd=''
        for (( j = 0; j < length; j++ )); do
            _genpass_rand $#chars || return 1
            pwd+=$chars[REPLY]
        done
        print -r -- "$pwd $(_genpass_entropy $#chars $length)"
    done
}

# ==================================================
# -- genpass - generate passwords of multiple types
# ==================================================
help_passwords[genpass]='Generate passwords (alnum|special|apple|monkey|xkcd)'
function genpass () {
    local -a opts_help
    zparseopts -D -E -- h=opts_help -help=opts_help
    if [[ -n $opts_help ]]; then
        echo "Usage: genpass <type> [args...]"
        echo ""
        echo "Types:"
        echo "    alnum [length] [count]    Alphanumeric only (no special chars), default 32 chars"
        echo "    special [length] [count]  Printable ASCII incl. special chars, default 32 chars"
        echo "    apple [count]             Pronounceable pseudowords (default type)"
        echo "    monkey [count]            Unambiguous base32-style, 26 chars"
        echo "    xkcd [count]              Word passphrase from /usr/share/dict/words"
        echo ""
        echo "Each password is printed with its entropy in bits."
        return 0
    fi

    local type=${1:-apple}
    shift 2>/dev/null || true
    case $type in
        alnum)   genpass-alnum "$@" ;;
        special) genpass-special "$@" ;;
        apple)   genpass-apple "$@" ;;
        monkey)  genpass-monkey "$@" ;;
        xkcd)    genpass-xkcd "$@" ;;
        *)
            _genpass_error "genpass: unknown type: $type"
            echo "Usage: genpass <type> [args...] (alnum|special|apple|monkey|xkcd)"
            return 1
            ;;
    esac
}