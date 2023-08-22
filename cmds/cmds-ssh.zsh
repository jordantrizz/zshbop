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

# - List public ssh-keys
help_ssh[pk]='List public ssh-keys'
function pk () {
    function _pk_usage() {
        echo "Usage: pk <ssh-key>"
        echo "   -p : print public key"
        echo "   -h : help"
        echo "   Examples:"
        echo "      pk ~/.ssh/id_rsa"
        echo "      pk -p ~/.ssh/id_rsa"
        return
    }
	
    local SSHKEY_FILE SSHKEY_MODE="echo"

    # -- Check Vars
    if [[ $SSHKEY_FILE == "-h" ]]; then
        _pk_usage
        return
    fi

    # -- Check if print
    if [[ $1 == "-p" ]]; then
        SSHKEY_MODE="cat"
        SSHKEY_FILE="$2"
    fi

    # -- Check if file
    if [[ -z $2 ]]; then
        SSHKEY_FILE=("${(@f)$(\ls -1 $HOME/.ssh/*.pub)}")                 
    else        
        if [[ ! -f $SSHKEY_FILE ]]; then
            _error "Can't find $SSHKEY_FILE"
            _pk_usage
            return
        fi
    fi

    # -- Print    
    _loading "Action listing public keys"
	for PUBKEY in ${SSHKEY_FILE}; do
		if [[ $SSHKEY_MODE == "cat" ]]; then
            _banner_grey "-- $PUBKEY --"
            $SSHKEY_MODE "$PUBKEY"
            echo ""
		else            
            $SSHKEY_MODE "$PUBKEY"
        fi
	done	
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
