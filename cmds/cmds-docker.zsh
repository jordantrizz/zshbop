# --
# docker
# --
_debug " -- Loading ${(%):-%N}"
help_files[docker]="Docker commands" # Help file description
typeset -gA help_docker # Init help array.

# -- paths
help_docker[dps]='Docker ps -a'
dps () {
	if (( $+commands[dops] )); then
        dops -a ${*}
    else
        docker ps -a ${*}
    fi
}

help_docker[dops]='Mikescher/better-docker-ps'
alias dops=dops_linux-amd64