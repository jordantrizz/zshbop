#!/usr/bin/env zsh
# -----------------------------------------------------------------------------------
# -- checks-docker.zsh -- Checks for docker
# -----------------------------------------------------------------------------------
_debug " -- Loading ${(%):-%N}"

# ==================================================
# -- docker-checks
# ==================================================
help_checks[docker-checks]='Run all checks for docker'
function docker-checks () {
    # Check if docker is installed
    docker-check-installed
}

# ==================================================
# -- docker-check-installed () - Checks if docker is installed
# ==================================================
help_checks[docker-check-installed]='Checks if docker is installed'
function docker-check-installed () {
    # -- Docker
    if (( $+commands[docker] )); then        
        # Count docker running containers
        DOCKER_RUNNING=$(docker ps -q 2>/dev/null)
        if [[ $? == "0" ]]; then
            # Fix count when no containers are running
            if [[ -z "$DOCKER_RUNNING" ]]; then
                DOCKER_RUNNING=0
            else
                DOCKER_RUNNING=$(echo "$DOCKER_RUNNING" | wc -l | tr -d ' ')
            fi

            # Count docker containers with errors
            DOCKER_ERRORS=$(docker ps -a --format "{{.ID}} {{.Names}} {{.Status}}" 2>/dev/null | grep "Exited" | wc -l | tr -d ' ')

            # Single combined status line
            if [[ $DOCKER_ERRORS -gt 0 ]]; then
                _warning "Docker: $(docker --version) - Running containers: $DOCKER_RUNNING - $DOCKER_ERRORS containers with errors"
            else
                _success "Docker: $(docker --version) - Running containers: $DOCKER_RUNNING - No container errors"
            fi
            return 0
        else        
            _warning "Docker: Command exists but daemon reporting error."
            return 1
        fi
    else
        _log "Docker not installed"
        return 1
    fi
}

# ==================================================
# -- docker-check-errors () - Checks for docker containers with errors
# ==================================================
help_checks[docker-check-errors]='Checks for docker containers with errors'
function docker-check-errors () {
    # -- Docker
    if (( $+commands[docker] )); then
        # Count docker containers with errors
        DOCKER_ERRORS=$(docker ps -a --format "{{.ID}} {{.Names}} {{.Status}}" | grep "Exited" | wc -l)
        if [[ $DOCKER_ERRORS -gt 0 ]]; then
            _warning "Docker: $DOCKER_ERRORS containers with errors"
        else
            _success "Docker: No containers with errors"
        fi
    else
        _log "Docker not installed"
    fi
}