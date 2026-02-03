#!/usr/bin/env zsh
# -----------------------------------------------------------------------------------
# -- checks-docker.zsh -- Checks for docker
# -----------------------------------------------------------------------------------
_debug " -- Loading ${(%):-%N}"

# =============================================================================
# -- docker-checks
# ===============================================
help_checks[docker-checks]='Run all checks for docker'
function docker-checks () {
    # Check if docker is installed and then check if errors
    if docker-check-installed; then
        docker-check-errors
    fi
}

# ===============================================
# -- docker-check-installed () - Checks if docker is installed
# ===============================================
help_checks[docker-check-installed]='Checks if docker is installed'
function docker-check-installed () {
    # -- Docker
    if (( $+commands[docker] )); then        
        # Count docker running containers
        DOCKER_RUNNING=$(docker ps -q 2>/dev/null)
        if [[ $? == "0" ]]; then
            DOCKER_RUNNING=$(echo $DOCKER_RUNNING | wc -l)        
            _success "Docker: $(docker --version) - Running containers: $DOCKER_RUNNING"
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

# ===============================================
# -- docker-check-errors () - Checks for docker containers with errors
# ===============================================
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
