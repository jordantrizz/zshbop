# --
# SSH commands
#
# Example help: help_wordpress[wp]='Generate phpinfo() file'
#
# --
_debug " -- Loading ${(%):-%N}"
help_files[ssh]='SSH related commands'
typeset -gA help_ssh

# ==================================================================
# -- Setup completion for pk using _pk
# ==================================================================
compdef _pk pk
function _pk () {
    # -- Get all public keys
    local SSHKEY_FILES=$(find ~/.ssh -type f -name "*.pub")
    local SSHKEYS=("${(@f)${SSHKEY_FILES}}")
    _describe 'pk' SSHKEYS    
}

# ==================================================================
# -- _pk_select_sshkeys_fzf $SSHKEY_FILES
# -- List public keys with fzf
# ==================================================================
function _pk_select_sshkeys_fzf () {
    local SSHKEY_FILES=$1 
    local HEADERS="$(_loading "Listing public keys from ~/.ssh") \n Select a public key file"
    local SELECTED_FILE=$(echo "$SSHKEY_FILES" | fzf --reverse --header "$(echo -e "$HEADERS")")

    if [[ -n $SELECTED_FILE ]]; then
        echo "$SELECTED_FILE"
    else
        echo "No file selected."        
    fi
}

# ==================================================================
# -- _pk_select_sshkeys_echo $SSHKEY_FILES_ARRAY
# -- List public keys with echo
# ==================================================================
function _pk_select_sshkeys_echo () {
    local SSHKEY_FILES_ARRAY=($@)
    local COUNTER=1

    for PUBKEY in ${SSHKEY_FILES_ARRAY}; do
        echo "$COUNTER) $PUBKEY"
        COUNTER=$((COUNTER+1))
    done
    echo ""
}

# ==================================================================
# ==================================================================
# ==================================================================

# ==================================================================
# -- pk 
# -- List public ssh-keys
# ==================================================================
help_ssh[pk]='List public ssh-keys'
function pk () {
    local ACTION=$1 
    local SELECT_METHOD="default" 
    local SSHKEY_FILE
    local SSHKEY_FILES=$(find ~/.ssh -type f -name "*.pub")

    # sort SSHKEY_FILES
    SSHKEY_FILES=$(echo $SSHKEY_FILES | tr ' ' '\n' | sort)

    # Set list_keys method if fzf is installed
    if _cmd_exists fzf; then
        _loading3 "fzf found, using fzf for selection"
        SELECT_METHOD="fzf"
    else
        _loading3 "fzf not found, using echo for selection"
        SELECT_METHOD="echo"
    fi

    function _pk_usage() {
        echo "Usage: pk (<ssh-key>|all)"
        echo "   -h : help"
        echo "   Examples:"
        echo "      pk ~/.ssh/id_rsa"
        echo "      pk all"
        return
    }

    function _pk_list_keys () {
        local SSH_KEY_SELECTED
        if [[ $SELECT_METHOD == "fzf" ]]; then
            SSH_KEY_SELECTED=$(_pk_select_sshkeys_fzf $SSHKEY_FILES)
            if [[ $SSH_KEY_SELECTED == "No file selected." ]]; then            
                _error "No file selected."
            else
                _loading "Priting SSH Key: $SSH_KEY_SELECTED"
                cat "$SSH_KEY_SELECTED"
            fi
        else
            _pk_list_keys_echo
        fi
    }

    function _pk_list_keys_echo () { 
        _loading "Listing public keys from ~/.ssh"
        for PUBKEY in ${SSHKEY_FILES}; do
            echo "$PUBKEY"
            echo ""
        done	
    }

    # -- Check Vars
    if [[ $SSHKEY_FILE == "-h" ]]; then
        _pk_usage
        return
    fi

    # -- Check if print    
    if [[ $ACTION == "all" ]]; then    
        _pk_list_keys       
    elif [[ $ACTION == "echo" ]]; then
        _pk_list_keys_echo
    elif [[ $ACTION == "select" ]]; then
        _pk_list_keys_select
    elif  [[ -n $ACTION ]]; then
        if [[ ! -f $ACTION ]]; then
            _error "Can't find $ACTION"
            _pk_usage
            return
        else
            _loading "Priting SSH Key: $ACTION"
            cat "$ACTION"
            return
        fi        

    elif [[ -z $ACTION ]]; then
        _pk_list_keys
    fi
	# | xargs -L 1 -I {} sh -c 'echo {};cat {};_banner_grey '-----------------------------''
}

# ==================================================================
# -- ssh-fingerprint
# -- List public keys fingerprint 
# ==================================================================
help_ssh[ssh-fingerprint]='List SSH Key Fingerprint'
ssh-fingerprint () { 
    # If you created using AWS console - openssl pkcs8 -in path_to_private_key -inform PEM -outform DER -topk8 -nocrypt | openssl sha1 -c
    # (RSA key pairs only) If you imported the public key to Amazon EC2 - openssl rsa -in path_to_private_key -pubout -outform DER | openssl md5 -c
    # If you created an OpenSSH key pair using OpenSSH 7.8 or later and imported the public key to Amazon EC2
    #  RSA: ssh-keygen -ef path_to_private_key -m PEM | openssl rsa -RSAPublicKey_in -outform DER | openssl md5 -c
    #  ssh-keygen -l -f path_to_private_key
    function _ssh_fingerprint_usage() {
        echo "Usage: ssh-fingerprint -aws <ssh-key>|<ssh-key>"
        echo "   -aws: use AWS format"
        echo "   -h : help"
        echo "   Examples:"
        echo "      ssh-fingerprint ~/.ssh/id_rsa"
        echo "      ssh-fingerprint -aws ~/.ssh/id_rsa"
        return
    }
    
    local SSHKEY_FINGERPRINT_FILE=$1
    local SSHKEY_FINGERPRINT_MODE="default"
	
    # -- Check if aws format
    if [[ $1 == "-aws" ]]; then
        SSHKEY_FINGERPRINT_FILE=$2
        SSHKEY_FINGERPRINT_MODE="aws"
    fi

    if [[ -z $SSHKEY_FINGERPRINT_FILE ]]; then
        _error "Missing <ssh-key> or -aws"
        _ssh_fingerprint_usage
        return
    elif [[ $SSHKEY_FINGERPRINT_FILE == "-h" ]]; then
        _ssh_fingerprint_usage
        return
    elif [[ ! -f $SSHKEY_FINGERPRINT_FILE ]]; then
        _error "Can't find $SSHKEY_FINGERPRINT_FILE"
        _ssh_fingerprint_usage
        return
    fi
    
    # -- remove (stdin)=
    if [[ $SSHKEY_FINGERPRINT_MODE == "aws" ]]; then    
        OPENSSL_DATA=$(openssl pkcs8 -in $SSHKEY_FINGERPRINT_FILE -inform PEM -outform DER -topk8 -nocrypt | openssl sha1 -c | sed 's/^.* //')
        echo "$SSHKEY_FINGERPRINT_FILE,$OPENSSL_DATA"
    else
        SSHKEY_FINGERPRINT=$(ssh-keygen -ef $SSHKEY_FINGERPRINT_FILE -m PEM | openssl rsa -RSAPublicKey_in -outform DER | openssl md5 -c)
        echo $SSHKEY_FINGERPRINT_FILE,$SSHKEY_FINGERPRINT
    fi
}

# ==================================================================
# -- ssh-addkey
# - Add SSH Key to keychain
# ==================================================================
help_ssh[ssh-addkey]='add ssh private key to keychain'
ssh-addkey () {
        echo "-- Adding $1 to keychain"
        keychain -q --eval --agents ssh $HOME/.ssh/$1
}

# ==================================================================
# -- ssh-keygen-ed25519
# -- Generate ssh key as ed25519
# ==================================================================
help_ssh[ssh-keygen-ed25519]="Generate ssh key as ed25519"
ssh-keygen-ed25519 () {
	ssh-keygen -t ed25519
}

# ==================================================================
# -- ssh-key-audit
# -- Find all SSH Keys on System
# ==================================================================
help_ssh[ssh-key-audit]="Find all SSH Keys on System"
ssh-key-audit () {
    $file=""
    _banner_yellow "** START root/.ssh/authorized_keys          *"
    cat ~/.ssh/authorized_keys
    _banner_yellow "** END root/.ssh/authorized_keys            *"
    USER_SSH_KEYS_CMD=$(find /home/*/.ssh/authorized_keys)
    _debug "$USER_SSH_KEYS"
    USER_SSH_KEYS=("${(@f)${USER_SSH_KEYS_CMD}}")
    _banner_yellow "** START User SSH Keys                      *"

    for file in ${USER_SSH_KEYS}; do
        _banner_grey "------------ $file";
        cat $file;
    done;
    _banner_yellow "** END User SSH Keys                      *"
}

# ==================================================================
# -- ak
# -- Display ~/.ssh/authorized_keys
# ==================================================================
help_ssh[ak]="Display ~/.ssh/authorized_keys"
ak () {
	cat ~/.ssh/authorized_keys
}

# ==================================================================
# -- ssh-key
# -- Login with -o "IdentitiesOnly yes" when too may keys in keychain
# ==================================================================
help_ssh[ssh-key]='Login with -o "IdentitiesOnly yes" and select ssh key to use'
function ssh-key () {
    local SSH_KEY_SELECTED
    local SSH_CMD=($@)
    local SSHKEY_FILES=$(find ~/.ssh -type f -name "*.pub")
    local SSHKEY_FILES_STR=$(echo $SSHKEY_FILES | sed 's/.pub//g') # Remove .pub from keys
    # Sort SSHKEY_FILES by name
    SSHKEY_FILES=$(echo $SSHKEY_FILES_STR | tr ' ' '\n' | sort)

    _ssh-key_usage() {
        echo "Usage: ssh-key <ssh-command>"
        echo "   -h : help"
        echo "   -e : echo mode"
        echo "   -f : fzf mode"
        echo "   Examples:"        
        echo "      ssh-key user@host"
        echo "      ssh-key -e user@host"
        echo "      ssh-key -f user@host"
        return
    }

    _ssh-key_echo () {
        SSHKEY_FILES_ARRAY=("${(@f)${SSHKEY_FILES}}")
        _pk_select_sshkeys_echo $SSHKEY_FILES_ARRAY
        read "?Enter number: " SSH_KEY_SELECTED_READ

        if [[ -n $SSH_KEY_SELECTED_READ ]]; then
            SSH_KEY_SELECTED=${SSHKEY_FILES_ARRAY[$SSH_KEY_SELECTED_READ]}                      
            _loading "Running ssh -o \"IdentitiesOnly yes\" -i $SSH_KEY_SELECTED $SSH_CMD"
            ssh -o "IdentitiesOnly yes" -i $SSH_KEY_SELECTED "${SSH_CMD[@]}"
        else
            echo "No file selected."
        fi
    }

    _ssh-key_fzf () {
        SSH_KEY_SELECTED=$(_pk_select_sshkeys_fzf $SSHKEY_FILES)
        if [[ $SSH_KEY_SELECTED == "No file selected." ]]; then            
            _error "No file selected."
        else
            _loading "Running ssh -o \"IdentitiesOnly yes\" -i $SSH_KEY_SELECTED $SSH_CMD"
            ssh -o "IdentitiesOnly yes" -i $SSH_KEY_SELECTED "${SSH_CMD[@]}"
        fi
    }
        
    # -- Check if no keys
    if [[ -z $SSHKEY_FILES ]]; then
        _error "No keys found in ~/.ssh"
        return
    elif [[ -z $SSH_CMD ]]; then
        _error "Missing <ssh-command>"
        _ssh-key_usage
    fi

    # -- Check if -e or -f in args
    if [[ $1 == "-e" ]]; then
        SSH_KEY_SELECT="echo"
        shift
        SSH_CMD=($@)
    elif [[ $1 == "-f" ]]; then
        SSH_KEY_SELECT="fzf"
        shift
        SSH_CMD=($@)
    else 
        if _cmd_exists fzf; then
            SSH_KEY_SELECT="fzf"
        else
            SSH_KEY_SELECT="echo"
        fi
    fi
    
    # -- Help
    if [[ $1 == "-h" ]]; then
        _ssh-key_usage
        return
    fi
        
    # Set list_keys method if fzf is installed
    if [[ $SSH_KEY_SELECT == "fzf" ]]; then
        _ssh-key_fzf
    elif [[ $SSH_KEY_SELECT == "echo" ]]; then
        _ssh-key_echo        
    fi
}

# ==================================================================
# -- ssh-clear-known-host
# ==================================================================
help_ssh[ssh-remove-kh]='Clear known_hosts file of specific line number'
ssh-remove-kh () {
    local LINE=$1
    if [[ -z $LINE ]]; then
        _error "Missing line number"
        return
    else
        _loading "Removing line $LINE"
        sed -i '$LINE' $HOME/.ssh/known_hosts
    fi
}

# ==================================================================
# -- ssh-get-pubkey-from-private
# ==================================================================
help_ssh[ssh-get-pubkey-from-private]='Get public key from private key'
ssh-get-pubkey-from-private () {
    local SSHKEY_FILE=$1
    if [[ -z $SSHKEY_FILE ]]; then
        _error "Missing <ssh-key>"
        return
    else
        _loading "Getting public key from $SSHKEY_FILE"
        ssh-keygen -y -f $SSHKEY_FILE
    fi
}

# ==================================================================
# -- ssh-password - Force ssh password authentication versus default
# ==================================================================
help_ssh[ssh-password]='Force ssh password authentication versus default'
ssh-password () {
        ssh -o PreferredAuthentications=password -o PubkeyAuthentication=no ${@}    
}

# ==================================================================
# -- ssh-config
# ==================================================================
help_ssh[ssh-config-view]='Print ssh config'
ssh-config-view () {
    # -- Print ssh config and zbc ssh config and view with default $PAGER
    _loading "Viewing ssh config"
    if [[ ! -f $ZBC_SSH_CONFIG ]]; then
        eval "${PAGER:-less} ~/.ssh/config"
    else
        eval "cat ~/.ssh/config $ZBC_SSH_CONFIG | ${PAGER:-less} "
    fi
}

# ==================================================================
# -- ssh-config-edit
# ==================================================================
help_ssh[ssh-config-edit]='Edit ssh config'
ssh-config-edit () {
    local SSH_CONFIG_FILE
    
    # List each ssh config and ask with one to edit
    _loading "Editing ssh config"
    echo "Which config file would you like to edit?"
    echo "1) ~/.ssh/config"
    echo "2) $ZBC_SSH_CONFIG"
    echo ""
    read "?Enter number: " SSH_CONFIG_FILE

    # -- Edit config with default shell editor
    if [[ $SSH_CONFIG_FILE == "1" ]]; then
        ${EDITOR:-vi} ~/.ssh/config
    elif [[ $SSH_CONFIG_FILE == "2" ]]; then
        ${EDITOR:-vi} $ZBC_SSH_CONFIG
    else
        _error "Invalid option"
    fi   
}