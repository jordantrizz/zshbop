# -- ip
_debug " -- Loading ${(%):-%N}"
help_files[ip]="IP Address commands"
typeset -gA help_ip # Init help array.

# -- ip-info
help_ip[ip-info]="Get IP information via a few different methods"
function ip-info() {
    local IP_PROVIDERS=(ipinfo.io) IP=$1
    
    # -- Usage
    function _ip_info_usage () {
        echo "Usage: ip-info <ip>"
        echo ""
        echo "You can set the IP provider by setting the ZSH_IP_PROVIDER variable and the API key via ZSH_IP_API_KEY"
        echo ""
        echo "Supported providers:"
        echo "  - ipinfo.io"        
        echo ""
    }

    # -- Do the actual work
    function _ip_info_do () {
        local IP=$1
        case $ZSH_IP_PROVIDER in
            ipinfo.io)
                if [[ -z $ZSH_IP_API_KEY ]]; then
                    _error "No API key set for ipinfo.io"
                    return 1
                else
                    _loading2 "Getting IP information from ipinfo.io"
                    curl -s "https://ipinfo.io/$IP?token=$ZSH_IP_API_KEY"
                fi
                ;;
        esac
    }

    # -- Check what provider is set
    if [[ -z $ZSH_IP_PROVIDER ]]; then
        _ip_info_usage
        _error "No IP provider set"
        return 1
    fi
    # -- Check if API key is set
    if [[ -z $ZSH_IP_API_KEY ]]; then
        _ip_info_usage
        _error "No API key set for $ZSH_IP_PROVIDER"
        return 1
    fi

    # -- Check if the provider is supported
    if [[ ! ${IP_PROVIDERS[(r)$ZSH_IP_PROVIDER]} == $ZSH_IP_PROVIDER ]]; then
        _ip_info_usage
        _error "IP provider $ZSH_IP_PROVIDER is not supported"
        return 1
    else
        _loading "Getting IP information from $ZSH_IP_PROVIDER"
        _ip_info_do $IP
    fi
}