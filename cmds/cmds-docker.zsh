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
help_docker[dc]='Docker compose'
alias dc='docker-compose ${*}'
alias dcu='docker-compose up -d ${*}'
alias dcd='docker-compose down ${*}'
alias dcr='docker-compose restart ${*}'
alias dcl='docker-compose logs -f ${*}'
alias dce='docker-compose exec ${*}'