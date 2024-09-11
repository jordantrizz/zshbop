# ===============================================
# -- ip
# ===============================================
_debug " -- Loading ${(%):-%N}"
help_files[ip]="IP Address commands"
typeset -gA help_ip # Init help array.

# ===============================================
# -- ip-info
# ===============================================
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
        case $ZSHBOP_IP_PROVIDER in
            ipinfo.io)
                if [[ -z $ZSHBOP_IP_API_KEY ]]; then
                    _error "No API key set for ipinfo.io"
                    return 1
                else                
                    [[ -z $IP ]] && _error "No IP address given, using system IP" || _loading2 "Getting IP information for $IP from ipinfo"
                    curl -s "https://ipinfo.io/$IP?token=${ZSHBOP_IP_API_KEY}"
                fi
                ;;
        esac
    }

    # -- Check what provider is set
    if [[ -z $ZSHBOP_IP_PROVIDER ]]; then
        _ip_info_usage
        _error "No IP provider set"
        return 1
    fi
    # -- Check if API key is set
    if [[ -z $ZSHBOP_IP_API_KEY ]]; then
        _ip_info_usage
        _error "No API key set for $ZSHBOP_IP_PROVIDER"
        return 1
    fi

    # -- Check if the provider is supported
    if [[ ! ${IP_PROVIDERS[(r)$ZSHBOP_IP_PROVIDER]} == $ZSHBOP_IP_PROVIDER ]]; then
        _ip_info_usage
        _error "IP provider $ZSHBOP_IP_PROVIDER is not supported"
        return 1
    else
        _loading "Using provider $ZSHBOP_IP_PROVIDER for IP information"
        _ip_info_do $IP
    fi
}

# ===============================================
# -- ip-scam
# ===============================================
help_ip[ip-scam]="Check if an IP is a known scammer"
function ip-scam() {
    local IP=$1
    [[ -z $IP ]] && _error "No IP address given" && return 1
    [[ -z $ZSHBOP_IP_SCAM ]] && _error "No API key set for scamalytics, set via \$ZSHBOP_IP_SCAM" && return 1
    _loading "Checking if $IP is a known scammer against scamalytics.com"
    curl -s "https://api11.scamalytics.com/lmt/?key=${ZSHBOP_IP_SCAM}&ip=$IP" | jq
}

# ===============================================
# -- cidr
# ===============================================
help_ip[cidr]="Print CIDR notations"
function cidr() {
    _loading "CIDR Notation"
    # Print out all possible cidr notations with number of hosts, cidr and subnet mask in a table
    local CIDR_DATA=(
        "1 /32 255.255.255.255"
        "2 /31 255.255.255.254"
        "4 /30 255.255.255.252"
        "8 /29 255.255.255.248"
        "16 /28 255.255.255.240"
        "32 /27 255.255.255.224"
        "64 /26 255.255.255.192"
        "128 /25 255.255.255.128"
        "256 /24 255.255.255.0"
        "512 /23 255.255.254.0"
        "1K /22 255.255.252.0"
        "2K /21 255.255.248.0"
        "4K /20 255.255.240.0"
        "8K /19 255.255.224.0"
        "16K /18 255.255.192.0"
        "32K /17 255.255.128.0"
        "64K /16 255.255.0.0"
        "128K /15 255.254.0.0"
        "256K /14 255.252.0.0"
        "512K /13 255.248.0.0"
        "1M /12 255.240.0.0"
        "2M /11 255.224.0.0"
        "4M /10 255.192.0.0"
        "8M /9 255.128.0.0"
        "16M /8 255.0.0.0"
        "32M /7 254.0.0.0"
        "64M /6 252.0.0.0"
        "128M /5 248.0.0.0"
        "256M /4 240.0.0.0"
        "512M /3 224.0.0.0"
        "1024M /2 192.0.0.0"
        "2048M /1 128.0.0.0"
        "4096M /0 0.0.0.0"
    )
    
    echo -e "Hosts\tCIDR\tSubnet Mask"
    for ENTRY in "${CIDR_DATA[@]}"; do
        echo -e "${ENTRY// /\\t}"
    done
}