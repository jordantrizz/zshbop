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
