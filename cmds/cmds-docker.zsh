# --
# docker
# --
_debug " -- Loading ${(%):-%N}"
help_files[docker]="Docker commands" # Help file description
typeset -gA help_docker # Init help array.

# ==============================================================================
# dps
# ==============================================================================
help_docker[dps]='Docker PS, either docker ps or dops'
function _dps_replace () {
    # Only run if docker is installed
    (( $+commands[docker] )) || return 0
    
    if _cmd_exists dops; then
        # Check if dps is an alias
        if [[ $(type dps) == "dps is an alias for docker ps" ]]; then
            _log "dps is an omz alias, removing"
            unalias dps
            function dps () {                
                dops $@
            }
        else
            docker ps $@
        fi
    fi

}
INIT_LAST_CORE+=("_dps_replace")

# ==============================================================================
# -- dops
# ==============================================================================
help_docker[dops]='Mikescher/better-docker-ps'
function dops () {
    dops_linux-amd64-static $@
}

# -- dc
help_docker[dc]='docker compose'
alias dc='docker compose ${*}'
help_docker[dcu]='docker compose up -d'
alias dcu='docker compose up -d ${*}'
help_docker[dcd]='docker compose down'
alias dcd='docker compose down ${*}'
help_docker[dcr]='docker compose restart'
alias dcr='docker compose restart ${*}'
help_docker[dcl]='docker compose logs'
alias dcl='docker compose logs -f ${*}'
help_docker[dce]='docker compose exec'
alias dce='docker compose exec ${*}'
help_docker[dcs]='docker compose stop'
alias dcs='docker compose stop ${*}'
help_docker[dcb]='docker compose build'
alias dcb='docker compose build ${*}'
help_docker[dcp]='docker compose pull'
alias dcp='docker compose pull ${*}'
help_docker[dci]='docker compose images'
alias dci='docker compose images ${*}'
help_docker[dcv]='docker compose version'
alias dcv='docker compose version ${*}'
help_docker[dcrc]='docker compose up --force-recreate -d'
alias dcrc='docker compose up --force-recreate -d ${*}'
help_docker[dcrca]='docker compose up --force-recreate'
alias dcrca='docker compose up --force-recreate ${*}'

help_docker[dip]='Find docker ip address'
function dip () {
    # List all Docker containers and their IPs
    for container in $(docker ps -q)
    do
        container_ip=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $container)
        container_name=$(docker inspect -f '{{.Name}}' $container | sed 's/\///')
        echo "Container: $container_name / $container_ip"        
    done
}

help_docker[docker-ports]='List all docker ports'
function docker-ports () {
    _loading "Going through all docker containers running and printing their ports"
    # Find all currently running Docker containers and their ports
    containers=$(docker ps --format "{{.Names}}")

    # Initialize an array to store all used TCP ports
    used_tcp_ports=()

    # Extract and collect the TCP ports used by running Docker containers
    while IFS= read -r container; do
    # Get the ports used by the container
    ports=($(docker port $container 2>/dev/null | awk -F '->' '{print $2}' | tr -d ' ' | grep -v '\[::\]'))

    # Print the container name and its ports
    _loading2 "Container '$container' is listening on TCP ports:"
        if [[ -z $ports ]]; then
            echo "- NONE"
        else
            for cport in ${ports[@]}; do
                echo " - $cport"
            done
        fi

    # Split the ports by space and iterate over them
    for port in "${ports[@]}"; do
        # Check if the port is TCP (contains a dot) and not UDP (doesn't contain "/udp")
        if [[ $port == *.* && $port != */udp ]]; then
        port_number=$(echo "$port" | awk -F ':' '{print $2}')
        used_tcp_ports+=("$port_number")
        fi
    done
    done <<< "$containers"

    # Sort the used TCP ports numerically
    sorted_tcp_ports=($(printf "%s\n" "${used_tcp_ports[@]}" | sort -n))

    _loading "Sorted Ports:"
    echo " - ${sorted_tcp_ports[@]}"

    # Find the next available TCP port
    next_tcp_port=$((sorted_tcp_ports[-1] + 1))

    _loading2 "Next available TCP port: $next_tcp_port"
}

# ==================================================
# -- docker-networks
# ==================================================
help_docker[docker-networks]='List all docker networks'
function docker-networks () {
    _loading "Listing all docker networks"
    
    # Get network list and store in an array
    local networks_output
    networks_output=$(docker network ls --format "table {{.Name}}\t{{.ID}}\t{{.Driver}}\t{{.Scope}}")
    
    # Process each line using a here-string to avoid subshell
    while IFS= read -r line; do
        if [[ $line != "NAME"* && -n "$line" ]]; then
            network_name=$(echo "$line" | awk '{print $1}')
            network_id=$(echo "$line" | awk '{print $2}')
            network_driver=$(echo "$line" | awk '{print $3}')
            network_scope=$(echo "$line" | awk '{print $4}')

            # Skip if network name is empty
            if [[ -z "$network_name" ]]; then
                continue
            fi

            # Get the subnet and IP range for the network
            network_info=$(docker network inspect "$network_id" --format '{{range .IPAM.Config}}{{.Subnet}} {{.Gateway}}{{end}}' 2>/dev/null)
            subnet=$(echo "$network_info" | awk '{print $1}')
            gateway=$(echo "$network_info" | awk '{print $2}')

            # Get containers connected to this network
            containers=$(docker network inspect "$network_id" --format '{{range .Containers}}{{.Name}} {{end}}' 2>/dev/null)

            _loading2 "Network: $network_name (ID: $network_id, Driver: $network_driver, Scope: $network_scope)"
            _loading2 "  Subnet: $subnet"
            _loading2 "  Gateway: $gateway"
            
            if [[ -n "$containers" && "$containers" != " " ]]; then
                _loading3 "Containers: $containers"
            else
                echo "  Containers: None"
            fi
            echo ""
        fi
    done <<< "$networks_output"
}

# ===================================================
# -- docker-prune
# ===================================================
help_docker[docker-prune]='Prune unused Docker resources'
function docker-prune () {
    _loading "Pruning unused Docker resources"
    # Prune unused Docker resources
    docker system prune -a --volumes --force
    if [[ $? -eq 0 ]]; then
        _loading2 "Docker resources pruned successfully"
    else
        _loading2 "Failed to prune Docker resources"
    fi
}

# ===================================================
# -- docker-storage
# ===================================================
help_docker[docker-storage]='Show Docker storage usage'
function docker-storage () {
    _loading "Showing Docker storage usage"    
    # Check if Docker is running
    if ! docker info &>/dev/null; then
        _loading2 "Docker is not running. Please start Docker first."
        return 1
    fi
    
    # Show Docker storage usage
    _loading2 "Running 'docker system df' to display storage usage"
    docker system df

    # Show detailed information about Docker images
    _loading2 "Running 'docker system df -v' for detailed image information"
    docker system df -v

    # Show overlay2 filesystem usage
    _loading2 "Running 'du -h /var/lib/docker/overlay2' to show overlay2 filesystem usage"
    STORAGE_OVERLAY2="$(sudo du -h /var/lib/docker/overlay2 --max-depth=1 | sort -hr | head -20)"
    echo "$STORAGE_OVERLAY2"

    # Get container storage usage and correlate with overlay2 data
    _loading2 "Top storage consuming containers with overlay2 details:"
    
    # Check if jq is available
    if ! command -v jq &>/dev/null; then
        _warning "jq not available, showing basic container info" 0
        docker ps -a --size --format "{{.Names}} ({{.ID}}): {{.Size}}" | head -5
    else
        # Get the top 5 containers by overlay2 size
        echo "$STORAGE_OVERLAY2" | head -n 6 | tail -n +2 | while read overlay_size overlay_path; do
            if [[ -n "$overlay_path" && "$overlay_path" != "/var/lib/docker/overlay2" ]]; then
                overlay_id=$(basename "$overlay_path")
                
                _loading3 "Overlay2 Path: $overlay_path ($overlay_size)"
                
                # Find container using this overlay2 directory
                CONTAINER_FOUND=""
                CONTAINER_ID=""
                CONTAINER_NAME=""
                CONTAINER_IMAGE=""
                
                # Search through all containers to find which one uses this overlay2
                for container in $(docker ps -aq 2>/dev/null); do
                    # Get the container's overlay2 directories
                    CONTAINER_OVERLAYS=$(docker inspect "$container" 2>/dev/null | jq -r '.[] | .GraphDriver.Data.MergedDir // .GraphDriver.Data.WorkDir // empty' 2>/dev/null | grep -o '[a-f0-9]\{64\}' | head -1)
                    
                    if [[ "$CONTAINER_OVERLAYS" == "$overlay_id" ]] || docker inspect "$container" 2>/dev/null | jq -r '.[] | .GraphDriver.Data | to_entries[] | .value' 2>/dev/null | grep -q "$overlay_id"; then
                        CONTAINER_ID="$container"
                        CONTAINER_NAME=$(docker inspect --format '{{.Name}}' "$container" 2>/dev/null | sed 's|/||')
                        CONTAINER_IMAGE=$(docker inspect --format '{{.Config.Image}}' "$container" 2>/dev/null)
                        CONTAINER_STATUS=$(docker inspect --format '{{.State.Status}}' "$container" 2>/dev/null)
                        CONTAINER_FOUND="yes"
                        break
                    fi
                done
                
                if [[ "$CONTAINER_FOUND" == "yes" ]]; then
                    echo "  Container: $CONTAINER_NAME ($CONTAINER_ID)"
                    echo "  Image: $CONTAINER_IMAGE"
                    echo "  Status: $CONTAINER_STATUS"
                    
                    # Get container size information
                    CONTAINER_SIZE=$(docker ps -a --size --format "{{.ID}}|{{.Size}}" | grep "^$CONTAINER_ID" | cut -d'|' -f2 | awk '{print $1}')
                    echo "  Container Layer Size: $CONTAINER_SIZE"
                    echo "  Overlay2 Size: $overlay_size"
                    
                    # Show mount information
                    MOUNTS=$(docker inspect --format '{{range .Mounts}}{{.Type}}:{{.Source}}->{{.Destination}} {{end}}' "$CONTAINER_ID" 2>/dev/null)
                    if [[ -n "$MOUNTS" ]]; then
                        echo "  Mounts: $MOUNTS"
                    fi
                else
                    echo "  Container: Unknown (overlay2 may be from deleted container)"
                    echo "  Overlay2 Size: $overlay_size"
                    echo "  Note: This overlay2 directory doesn't match any current container"
                fi
                echo ""
            fi
        done
    fi

}