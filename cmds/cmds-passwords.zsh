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
# -- genpass-apple - pronounceable pseudoword passphrase (cvccvc)
# ==================================================
help_passwords[genpass-apple]='Generate pronounceable pseudoword passphrase'
function genpass-apple () {
    local -a opts_help
    zparseopts -D -E -- h=opts_help -help=opts_help
    if [[ -n $opts_help ]]; then
        echo "Usage: genpass-apple [count]"
        return 0
    fi

    local count=${1:-1}
    if [[ $count != <1-1000> ]]; then
        _genpass_error "genpass-apple: invalid count: $count (must be 1-1000)"
        return 1
    fi

    local -r vowels=aeiouy
    local -r consonants=bcdfghjklmnpqrstvwxz
    local -r digits=0123456789
    local REPLY chars c pwd digit
    local -a words
    local i j k
    for (( i = 0; i < count; i++ )); do
        words=()
        for (( j = 0; j < 6; j++ )); do
            words+=('')
            for (( k = 0; k < 2; k++ )); do
                for chars in $consonants $vowels $consonants; do
                    _genpass_rand $#chars || return 1
                    words[-1]+=$chars[REPLY]
                done
            done
        done
        pwd=${(j:-:)words}
        # Replace either the first or the last character in one of the words with a digit
        _genpass_rand $#digits || return 1
        digit=$digits[REPLY]
        _genpass_rand $((2 * $#words)) || return 1
        pwd[REPLY/2*7+2*(REPLY%2)-1]=$digit
        # Convert one lower-case character to upper case (locale-safe via octal printf)
        while true; do
            _genpass_rand $#pwd || return 1
            [[ $vowels$consonants == *$pwd[REPLY]* ]] && break
        done
        c=$pwd[REPLY]
        printf -v c '%o' $((#c - 32))
        printf "%s\\$c%s" "$pwd[1,REPLY-1]" "$pwd[REPLY+1,-1]"
        print -r -- " $(_genpass_entropy 5760000 6)"
    done
}

# ==================================================
# -- genpass-monkey - unambiguous base32-style password (26 chars)
# ==================================================
help_passwords[genpass-monkey]='Generate unambiguous base32-style password (26 chars)'
function genpass-monkey () {
    local -a opts_help
    zparseopts -D -E -- h=opts_help -help=opts_help
    if [[ -n $opts_help ]]; then
        echo "Usage: genpass-monkey [count]"
        return 0
    fi

    local count=${1:-1}
    if [[ $count != <1-1000> ]]; then
        _genpass_error "genpass-monkey: invalid count: $count (must be 1-1000)"
        return 1
    fi

    local -r chars=abcdefghjkmnpqrstvwxyz0123456789
    local REPLY i j
    for (( i = 0; i < count; i++ )); do
        for (( j = 0; j < 26; j++ )); do
            _genpass_rand $#chars || return 1
            print -rn -- $chars[REPLY]
        done
        print -r -- " $(_genpass_entropy $#chars 26)"
    done
}

# ==================================================
# -- genpass-xkcd - word passphrase from /usr/share/dict/words
# ==================================================
help_passwords[genpass-xkcd]='Generate word passphrase (xkcd style)'
function genpass-xkcd () {
    local -a opts_help
    zparseopts -D -E -- h=opts_help -help=opts_help
    if [[ -n $opts_help ]]; then
        echo "Usage: genpass-xkcd [count]"
        return 0
    fi

    local count=${1:-1}
    if [[ $count != <1-1000> ]]; then
        _genpass_error "genpass-xkcd: invalid count: $count (must be 1-1000)"
        return 1
    fi

    local dict=${GENPASS_DICT:-/usr/share/dict/words}
    if [[ ! -e $dict ]]; then
        for dict in /usr/share/dict/words /usr/share/dict/american-english /usr/share/dict/linux.words; do
            [[ -e $dict ]] && break
        done
    fi
    if [[ ! -e $dict ]]; then
        _genpass_error "genpass-xkcd: no word list found (tried \$GENPASS_DICT, /usr/share/dict/words, /usr/share/dict/american-english, /usr/share/dict/linux.words)"
        return 1
    fi

    setopt local_options extended_glob
    local -a words
    words=(${(M)${(f)"$(<$dict)"}:#[a-zA-Z](#c1,6)}) || return 1
    if (( $#words < 2 )); then
        _genpass_error "genpass-xkcd: not enough suitable words in $dict"
        return 1
    fi

    # Each word adds log2($#words) bits; need at least 128 bits of security margin
    local -i n=$((ceil(128. / (log($#words) / log(2)))))
    local c rnd i j k
    for (( i = 0; i < count; i++ )); do
        print -rn -- $n
        for (( j = 0; j < n; j++ )); do
            while true; do
                # Generate a random number in [0, 2**31) and avoid bias
                rnd=0
                for (( k = 0; k < 4; k++ )); do
                    sysread -s1 c < /dev/urandom || return 1
                    (( rnd = (~(1 << 23) & rnd) << 8 | #c ))
                done
                (( rnd < 16#7FFFFFFF / $#words * $#words )) && break
            done
            print -rn -- -$words[rnd%$#words+1]
        done
        print -r -- " $(_genpass_entropy $#words $n)"
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