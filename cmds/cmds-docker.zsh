# --
# docker
# --
_debug " -- Loading ${(%):-%N}"
help_files[docker]="Docker commands" # Help file description
typeset -gA help_docker # Init help array.

# -- paths
help_docker[dps]='Docker ps -a'
dps () {
	if alias dops >/dev/null 2>&1; then
        eval "dops -a ${*}"
    else
        docker ps -a ${*}
    fi
}

# -- dops
help_docker[dops]='Mikescher/better-docker-ps'
alias dops=dops_linux-amd64

# -- dc
help_docker[dc]='docker-compose'
alias dc='docker-compose ${*}'
help_docker[dcu]='docker-compose up -d'
alias dcu='docker-compose up -d ${*}'
help_docker[dcd]='docker-compose down'
alias dcd='docker-compose down ${*}'
help_docker[dcr]='docker-compose restart'
alias dcr='docker-compose restart ${*}'
help_docker[dcl]='docker-compose logs'
alias dcl='docker-compose logs -f ${*}'
help_docker[dce]='docker-compose exec'
alias dce='docker-compose exec ${*}'
help_docker[dcs]='docker-compose stop'
alias dcs='docker-compose stop ${*}'
help_docker[dcb]='docker-compose build'
alias dcb='docker-compose build ${*}'
help_docker[dcp]='docker-compose pull'
alias dcp='docker-compose pull ${*}'
help_docker[dci]='docker-compose images'
alias dci='docker-compose images ${*}'
help_docker[dcv]='docker-compose version'
alias dcv='docker-compose version ${*}'
help_docker[dcrc]='docker-compose up --force-recreate -d'
alias dcrc='docker-compose up --force-recreate -d ${*}'
