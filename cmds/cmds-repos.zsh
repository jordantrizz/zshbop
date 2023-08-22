# --
# Core commands
#
# Example help: help_wordpress[wp]='Generate phpinfo() file'
#
# --
_debug " -- Loading ${(%):-%N}"

# -- repos - Install popular github.com Repositories
help_core[repos]='Install popular github.com repositories.'

function repos () {
	# debug
	_debug_all $@

	# list of repositories
	declare -A GIT_REPOS GIT_REPOS_URL
    # =====================================
    # -- Arguments
    # =====================================
	zparseopts -D -E - d+=DEBUG_FLAG
	if [[ -n "$DEBUG_FLAG" ]]; then local ZSH_DEBUG="1";_debug "Debug enabled";fi
    

    # =====================================
    # -- Repositories
    # =====================================

    # -- gp-tools
    GIT_REPOS[wp-shelltools]="WordPress Shell Tools"
    GIT_REPOS_URL[wp-shelltools]="https://github.com/managingwp/wp-shelltools"
    
    # -- mwp-scan-malware
    GIT_REPOS[mwp-scan-malware]="Scan malware with Yara using custom signatures"
    GIT_REPOS_URL[mwp-scan-malware]="https://github.com/managingwp/mwp-scan-malware"

	# -- github-markdown-toc
	GIT_REPOS[github-markdown-toc]="Add markdown table of contents to README.md"
	GIT_REPOS_URL[github-markdown-toc]="https://github.com/jordantrizz/github-markdown-toc"
	
	# -- cloudflare-cli
	GIT_REPOS[cloudflare-cli]="Interface with Cloudflares API"
    GIT_REPOS_URL[cloudflare-cli]="https://github.com/jordantrizz/cloudflare-cli"
    
    # -- site24x7-custom-install
	GIT_REPOS[site24x7-custom-install]="Custom Site24x7 install"
    GIT_REPOS_URL[site24x7-custom-install]="https://github.com/lmtca/site24x7-custom-install"
    
    # -- forwardemail-api-bash
    GIT_REPOS[forwardemail-cli-bash]="forwardemail.net api bash script"
    GIT_REPOS_URL[forwardemail-cli-bash]="https://github.com/jordantrizz/forwardemail-cli-bash"

	# -- chatgpt-cli
	GIT_REPOS[chatgpt-cli]="A chatgpt implementation in CLI 0xacx/chatGPT-shell-cli"
    GIT_REPOS_URL[chatgpt-cli]="https://github.com/0xacx/chatGPT-shell-cli"
    
    # -- zsh-installs
    GIT_REPOS[zsh-installs]="zsh installs"
    GIT_REPOS_URL[zsh-installs]="https://github.com/jordantrizz/zsh-installs"

    # -- zsh-sweep
    GIT_REPOS[zsh-sweep]="zsh-sweep"
    GIT_REPOS_URL[zsh-sweep]="https://github.com/psprint/zsh-sweep"

    # -- wp-umbrella-cli-bash
    GIT_REPOS[wp-umbrella-cli-bash]="wp-umbrella-cli-bash"
    GIT_REPOS_URL[wp-umbrella-cli-bash]="https://github.com/managingwp/wp-umbrella-cli-bash"
    
    # -- docker-autocompose
    GIT_REPOS[docker-autocompose]="docker-autocompose"
    GIT_REPOS_URL[docker-autocompose]="https://github.com/Red5d/docker-autocompose.git"

    # =====================================
    # -- Functions
    # =====================================

    # -------------
	# -- repos pull
    # -------------

    if [[ $1 == 'pull' ]] && [[ -n "$2" ]]; then
		_debug "Checking if $2 is in \$GIT_REPO"
       	_if_marray "$2" GIT_REPOS
       	REPODIR=$2
       	
       	if [[ -z $3 ]]; then BRANCH=$3; fi
       	_debug "Installing branch $BRANCH"
       	
		if [[ $MARRAY_VALID == "0" ]]; then
			_debug "Found repository - pulling via url ${GIT_REPOS_URL[$2]}"
	        echo "-- Pulling repository $2 into $REPOS_DIR/$REPODIR"
	        REPO="$REPOS_DIR/$REPODIR"
			if [[ ! -d "$REPO" ]]; then
				if [[ -z $BRANCH ]]; then
					echo "branch specified, so pulling using branch $BRANCH"
					git clone ${GIT_REPOS_URL[$2]} ${REPO} ${BRANCH}
					init_path
				else
				    git clone ${GIT_REPOS_URL[$2]} ${REPO}
                    init_path
				fi
				
				
			else
				_error "Repo already pulled or ${REPO} folder exists..exiting"
			fi
		else
			echo "No such repository $2"
			return 1
		fi		
    # -------------
	# -- repos list
    # -------------
	elif [[ $1 == 'list' ]]; then
		_loading "Listing repos pulled"
		if [ "$(find "$REPOS_DIR" -mindepth 1 -maxdepth 1 -not -name '.*')" ]; then
            _debug "Found repositories"
            for REPO in $REPOS_DIR/*; do
            	REPO_BRANCH=$(git -C $REPO rev-parse --abbrev-ref HEAD)
                _debug "Found $REPO with $REPO_BRANCH"
                if [[ -d $REPO ]]; then
                    _success "$REPO - $REPO_BRANCH"
                else
                    _error "No repos pulled"
                fi
            done
        else
            _error "No repos pulled"
        fi
        echo ""
	# ---------------
	# -- repos update
    # ---------------
	elif [[ $1 == 'update' ]]; then
        [[ $funcstack[2] == "zshbop_update" ]] && _loading2 "Updating repos" || _loading "Updating repos"
		if [ "$(find "$REPOS_DIR" -mindepth 1 -maxdepth 1 -not -name '.*')" ]; then
			_debug "Found repositories"
			for REPO in $REPOS_DIR/*; do
		    	_debug "Found $REPO"
	        	if [[ -d $REPO ]]; then
	        		_loading2 "Updating repo $REPO"
	                git --git-dir=$REPO/.git --work-tree=$REPO pull
		        else
		        	_loading2 "No repos to update"
	       		fi
			done
		else
			_loading2 "No repos to update"
		fi
	# ---------------
	# -- repos dir
	# ---------------
	elif [[ $1 == 'dir' ]]; then
		_debug "Changing directory to $REPOS_DIR"
		cd $REPOS_DIR
	else
    	echo "Usage: repos <pull <repo>|list|update>"
        echo ""
        echo "This command pulls down popular Github repositories."
        echo "To pull down a repo, simply type 'repo <reponame>'"
        echo "The repo will be pulled into \$ZSHBOP/repos"
        echo ""
		echo "Commands:"
		echo "    pull <repo> (branch)     - Pull  repository"
		echo "    list                     - List pulled repositories"
		echo "    branch <repo> <branch>   - Change branch for repository"
		echo "    update                   - Update repositories"
		echo "    dir  				       - Change directory to repos directory"
        echo ""
        echo "Available Repositories"
        echo ""
        for key in ${(kon)GIT_REPOS}; do
        	printf '%s\n' "  ${(r:40:)key} - $GIT_REPOS[$key]"
        done
        echo ""
	fi
}
