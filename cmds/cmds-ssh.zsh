# --
# SSH commands
#
# Example help: help_wordpress[wp]='Generate phpinfo() file'
#
# --
_debug " -- Loading ${(%):-%N}"

# What help file is this?
help_files[ssh]='SSH related commands'

# - Init help array
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
# - List public ssh-keys
# ==================================================================

help_ssh[pk]='List public ssh-keys'
function pk () {
    local ACTION=$1
    function _pk_usage() {
        echo "Usage: pk (<ssh-key>|all)"
        echo "   -h : help"
        echo "   Examples:"
        echo "      pk ~/.ssh/id_rsa"
        echo "      pk all"
        return
    }
	
    local SSHKEY_FILE

    # -- Check Vars
    if [[ $SSHKEY_FILE == "-h" ]]; then
        _pk_usage
        return
    fi

    # -- Check if print    
    if [[ $ACTION == "all" ]]; then    
        local SSHKEY_FILES=($(find ~/.ssh -type f -name "*.pub"))
        for PUBKEY in ${SSHKEY_FILES}; do
            _banner_grey "-- $PUBKEY --"
            cat "$PUBKEY"
            echo ""            
        done         
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
        _loading "Action listing public keys"
        local SSHKEY_FILES=$(find ~/.ssh -type f -name "*.pub")
        for PUBKEY in ${SSHKEY_FILES}; do
            echo "$PUBKEY"
            echo ""
        done	
    fi
	# | xargs -L 1 -I {} sh -c 'echo {};cat {};_banner_grey '-----------------------------''
}

# -- List public keys fingerprint 
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

# - Add SSH Key to keychain
help_ssh[ssh-addkey]='add ssh private key to keychain'
ssh-addkey () {
        echo "-- Adding $1 to keychain"
        keychain -q --eval --agents ssh $HOME/.ssh/$1
}

# -- ssh-keygen-ed25519
help_ssh[ssh-keygen-ed25519]="Generate ssh key as ed25519"
ssh-keygen-ed25519 () {
	ssh-keygen -t ed25519
}

# -- ssh-key-audit
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

# -- ak
help_ssh[ak]="Display ~/.ssh/authorized_keys"
ak () {
	cat ~/.ssh/authorized_keys
}

# -- ssho
help_ssh[ssho]='Login with -o "IdentitiesOnly yes" when too may keys in keychain'
ssho () {
	ssh -o "IdentitiesOnly yes" $@
}

# -- ssh-clear-known-host
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