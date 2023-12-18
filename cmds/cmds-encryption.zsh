# ==================================================
# -- encryption commands
# ==================================================
_debug " -- Loading ${(%):-%N}"
typeset -gA help_encryption
help_files[encryption]="Encryption commands"

# ==================================================
# -- cryptomator-check
# ==================================================
help_encryption[cryptomator-check]="Check if cryptomator-cli is installed"
function cryptomator-check() {
    _loading "Checking if cryptomator-cli is installed"
    if [[ -f $CRYPTOMATOR_CLI_JAR ]]; then
        _success "Cryptomator CLI found"
        return 0
    else
        _error "Cryptomator CLI not found, run software cryptomator-cli"
        return 1
    fi
}

# ==================================================
# -- cryptomator
# ==================================================
help_encryption[cryptomator]="Mount a Cryptomator vault"
function cryptomator () {
    local ACTION=${1} VAULT_NAME=${2} VAULT_PATH=${3} MOUNT_POINT=${4}

        function _cryptomator_usage () {
            echo "Usage: cryptomator (mount <vault-name>|unmount <vault-name>|list)"
            echo ""
            echo "Commands:"
            echo "    mount <vault-name> <vault-path> [mountpoint]  - Mount a Cryptomator vault"
            echo "    unmount <vault-name>                          - Unmount a Cryptomator vault"
            echo "    list                                          - List all Cryptomator vaults"
            echo ""
            return 1
        }

    # -- _cryptomator_mount_usage $VAULT_NAME $VAULT_PATH $MOUNT_POINT
    function _cryptomator_mount() {    
        local CRYPTOMATOR_VAULT_NAME=${1} 
        local CRYPTOMATOR_VAULT_PATH=${2}
        local CRYPTOMATOR_MOUNT_POINT=${3:=$HOME/mnt/${CRYPTOMATOR_VAULT_NAME}}    
        local CRYPTOMATOR_MOUNT_STATUS="$(mount | grep $CRYPTOMATOR_MOUNT_POINT)"
        
        local EXIT_CODE
        local CRYPTOMATOR_VAULT_PASSWORD=""
        local CRYPTOMATOR_PID_FILE="$HOME/tmp/cryptomator-${CRYPTOMATOR_VAULT_NAME}.pid"    
        _loading "Mounting Cryptomator $CRYPTOMATOR_VAULT_NAME from $CRYPTOMATOR_VAULT_PATH to $CRYPTOMATOR_MOUNT"

        if [[ -z $CRYPTOMATOR_VAULT_PATH ]]; then
            _crptomator_mount_usage
        else
            # -- Check if we have cryptomator-cli
            if ! cryptomator-check; then            
                return 1
            fi
            
            # -- Check if the vault is already mounted    
            if [[ -n $CRYPTOMATOR_MOUNT_STATUS ]]; then
                _success "Cryptomator vault already mounted at $CRYPTOMATOR_MOUNT_POINT"
                return 0
            fi

            # - Check if last pid is running
            if [[ -f $CRYPTOMATOR_PID_FILE ]]; then
                _loading3 "Checking if cryptomator-cli is running"
                CRYPTOMATOR_PID=$(cat $CRYPTOMATOR_PID_FILE)
                if \ps -p $CRYPTOMATOR_PID > /dev/null; then
                    _loading3 "cryptomator-cli is running with PID $CRYPTOMATOR_PID"
                    return 0
                else
                    _loading3 "cryptomator-cli is not running"
                    rm $CRYPTOMATOR_PID_FILE
                fi
            fi
            
            # -- Start mounting process.
            if [[ ! -d $CRYPTOMATOR_MOUNT_POINT ]]; then
                _loading3 "Creating mount point $CRYPTOMATOR_MOUNT_POINT"
                mkdir -p $CRYPTOMATOR_MOUNT_POINT        
            fi
            # -- Get password
            _loading3 "Enter Cryptomator vault password"
            read -s CRYPTOMATOR_VAULT_PASSWORD

            # -- Mount the vault
            _loading3 "exec: nohup java -jar $HOME/bin/cryptomator-cli.jar --vault $CRYPTOMATOR_VAULT_NAME=$CRYPTOMATOR_VAULT_PATH --fusemount $CRYPTOMATOR_VAULT_NAME=$CRYPTOMATOR_MOUNT_POINT --password $CRYPTOMATOR_VAULT_NAME=***** > $HOME/tmp/cryptomator-$CRYPTOMATOR_VAULT_NAME.log 2>&1 &"
            nohup java -jar $HOME/bin/cryptomator-cli.jar --vault $CRYPTOMATOR_VAULT_NAME=$CRYPTOMATOR_VAULT_PATH --fusemount $CRYPTOMATOR_VAULT_NAME=$CRYPTOMATOR_MOUNT_POINT --password $CRYPTOMATOR_VAULT_NAME=$CRYPTOMATOR_VAULT_PASSWORD > $HOME/tmp/cryptomator-$CRYPTOMATOR_VAULT_NAME.log 2>&1 &
            CRYPTOMATOR_PID="$!"                
            EXIT_CODE=$?
            _loading3 "Launched cryptomator-cli with PID $CRYPTOMATOR_PID"
            
            # -- Check if the vault is mounted
            if [[ -n $EXIT_CODE ]]; then
                # -- Check if process is running
                if \ps -p $CRYPTOMATOR_PID > /dev/null; then
                    _loading3 "Cryptomator vault mounted and runng with PID $CRYPTOMATOR_PID"
                    echo $CRYPTOMATOR_PID > $CRYPTOMATOR_PID_FILE
                else
                    _error "Failed to mount Cryptomator vault"
                    return 1
                fi
                _loading2 "Cryptomator vault mounted at $CRYPTOMATOR_MOUNT_POINT"
                return 0
            else
                _loading2 "Failed to mount Cryptomator vault"
                return 1
            fi
        fi
    }

    # -- _cryptomator_list
    function _cryptomator_list() {    
        local VAULT_NAME=${1}
        local CRYPTOMATOR_PROCESSES PROCESS PID
    
        _loading3 "Listing cryptomator vaults"
        unsetopt nomatch
        CRYPTOMATOR_PROCESSES="$(ls -1 $HOME/tmp/cryptomator-*.pid 2>/dev/null)"
        [[ $? -ne 0 ]] && { _error "No cryptomator pids"; return 1;} 
        setopt nomatch
        
        for PROCESS in $CRYPTOMATOR_PROCESSES; do            
            PID=$(cat $PROCESS)            
            if \ps -p $PID > /dev/null; then
                echo "$PROCESS - $PID"
            else
                _error "Cryptomator vault not running, removing $PROCESS"
                rm $PROCESS
            fi
        done
        return 0
    }

    # -- _cryptomator_unmount
    function _cryptomator_unmount () {
        local VAULT=${1}
        _loading "Unmounting Cryptomator vaults"
        # -- Check if we have cryptomator-cli
        cryptomator-check

        # -- Check if cryptomator process is running for vault
        if [[ -f $HOME/tmp/cryptomator-${VAULT}.pid ]]; then
            _loading3 "Checking if cryptomator-cli is running"
            PID=$(cat $HOME/tmp/cryptomator-${VAULT}.pid)
            if \ps -p $PID > /dev/null; then
                _loading3 "cryptomator-cli is running with PID $PID"
                # -- kill the process
                _loading3 "Killing cryptomator-cli with PID $PID"
                \kill $PID
                if [[ $? -eq 0 ]]; then
                    _loading3 "Cryptomator vault unmounted"
                    rm $HOME/tmp/cryptomator-${VAULT}.pid
                    return 0
                else
                    _error "Failed to unmount Cryptomator vault"
                    return 1
                fi
            else
                _loading3 "cryptomator-cli is not running"
                rm $HOME/tmp/cryptomator-${VAULT}.pid
            fi
        else
            _error "Cryptomator vault not found"
            return 1
        fi              
    }

    # -- Main
    if [[ -z $ACTION ]]; then
        _cryptomator_usage
    elif [[ $ACTION == "mount" ]]; then
        _cryptomator_mount $VAULT_NAME $VAULT_PATH $MOUNT_POINT
    elif [[ $ACTION == "unmount" ]]; then
        _cryptomator_unmount $VAULT_NAME
    elif [[ $ACTION == "list" ]]; then
        _cryptomator_list
    else
        _cryptomator_usage
    fi
}