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
pk () { 
	#SSH_PUBLIC_KEYS=$(ls -1 ~/.ssh/*.pub)
	SSH_PUBLIC_KEYS=("${(@f)$(\ls -1 ~/.ssh/*.pub)}")
	_loading "Listing all public keys in /$HOME/.ssh"
	for PUBKEY in ${SSH_PUBLIC_KEYS}; do
		 _banner_grey "-- $PUBKEY --"
		cat "$PUBKEY"
		echo ""
	done	
	# | xargs -L 1 -I {} sh -c 'echo {};cat {};_banner_grey '-----------------------------''
}

# -- List public keys fingerprint 
awsfp () { 
	openssl pkcs8 -in $1 -inform PEM -outform DER -topk8 -nocrypt | openssl sha1 -c
}


# - Add SSH Key to keychain
help_ssh[addsshkey]='add ssh private key to keychain'
addsshkey () {
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