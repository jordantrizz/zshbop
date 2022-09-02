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
pk () { ls -1 ~/.ssh/*.pub | xargs -L 1 -I {} sh -c 'echo {};cat {};echo '-----------------------------''}

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