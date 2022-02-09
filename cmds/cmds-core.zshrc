# --
# Core commands
#
# Example help: help_wordpress[wp]='Generate phpinfo() file'
#
# --
_debug " -- Loading ${(%):-%N}"

# What help file is this?
help_files[core]='Core commands'

# - Init help array
typeset -gA help_core

# - Don't know what cmd was for?
cmd () { }; help_core[cmd]='broken and needs to be fixed'

# -- cc - clear cache for various tools
help_core[cc]='Clear cache for antigen + more'
cc () {
        antigen reset; rm ~/.zshrc.zwc
}

# -- kb - A built in knowledge base.
help_core[kb]='knowledge base'
kb () {
	# Check if mdv exists if not use cat
        if _cexists mdv; then mdv_reader=mdv; else mdv_reader=cat fi

        if [[ -a $ZSH_ROOT/kb/$1.md ]]; then
                echo "Opening $ZSH_ROOT/kb/$1.md"
                $mdv_reader $ZSH_ROOT/kb/$1.md
        else
                ls -l $ZSH_ROOT/kb
        fi
        if [[ $mdv_reader == cat ]]; then
                echo "\n\n"
                echo "---------------------------------------"
                echo "mdv not avaialble failing back to cat"
                echo "trying installing mdv by typing"
                echo "---------------------------------------"
        fi
}

# -- checkenv - Check Environment for installed software
help_core[checkenv]='check environment for installed software and tools'
checkenv () {
        echo "---------------------------"
        echo "Looking for default tools.."
        echo "---------------------------"
        echo ""
        for i in $default_tools; do
                if _cexists $i; then
                        echo "$i is $BGGREEN INSTALLED. $RESET"
                else
                        echo "$i is $BGRED MISSING. $RESET"
                fi
        done
        echo "---------------------------"
        echo "Looking for default tools.."
        echo "---------------------------"
        echo ""
        for i in $extra_tools; do
        if _cexists $i; then
                echo "$i is $BGGREEN INSTALLED. $RESET"
        else
                echo "$i is $BGRED MISSING. $RESET"
        fi
        done
        echo "--------------------------------------------"
        echo "Run installenv to install above tools"
        echo "--------------------------------------------"

}

# -- installenv - Install tools into environment.
help_core[installenv]='Install tools into environment'
installenv () {
        echo "---------------------------"
        echo "Installing default tools.."
        echo "---------------------------"
        sudo apt-get update
        sudo apt install $default_tools
        echo "---------------------------"
        echo "Installing extra tools.."
        echo "---------------------------"
        sudo apt install $extra_tools
        echo "---------------------------"
        echo "Manual installs"
        echo "---------------------------"
        echo " mdv       - pip install mdv"
        echo " gnomon    - via npm"
        echo " lsd       - https://github.com/Peltoche/lsd"
        echo ""
}


# -- update - Update ZSHBOP
help_core[update]='Update zshbop'
update () {
        # Pull zshbop
        echo "--- Pulling zshbop updates"
        git -C $ZSH_ROOT pull

        # Update Personal ZSH
        if [ ! -z $ZSH_PERSONAL_DIR ]; then
                echo "--- Pulling Personal ZSH repo"
                git -C $ZSH_PERSONAL_DIR pull
        fi

        # Update repos
        for name in $ZSH_ROOT/repos/*
        do
                echo "-- Updating repo $name"
                git -C $name pull
        done

        # Reload scripts
        echo "--- Type rld to reload zshbop"
}

# -- repos - Install popular github.com Repositories
help_core[repos]='Install popular github.com repositories.'
repos () {
        declare -A GIT_REPOS
        GIT_REPOS[jordantrizz/gp-tools]="GridPane Tools by @Jordantrizz"
        GIT_REPOS[jordantrizz/github-markdown-toc]="Add markdown table of contents to README.md"
        GIT_REPOS[jordantrizz/cloudflare-cli]="Interface with Cloudflares API"
        GIT_REPOS[lmtca/site24x7-custom-install]="Custom Site24x7 install"


        if [ ! $1 ]; then
                echo "--------------------------"
                echo "-- Popular Github Repos --"
                echo "--------------------------"
                echo ""
                echo "This command pulls down popular Github repositories."
                echo ""
                echo "To pull down a repo, simply type \"repo <reponame>\" and the repository will be installed into ZSHBOP/repos"
                echo ""
                echo "-- Repositories --"
                echo ""
                for key value in ${(kv)GIT_REPOS}; do
                        printf '%s\n' "  ${(r:40:)key} - $value"
                done
                echo ""
        else
                echo "-- Start repo install --"
                if [ $1 ]; then
                        echo " - Installing $1 repo"
                                git -C $ZSH_ROOT/repos clone https://github.com/$1
                else
                        echo "Uknown repo $1"
                fi
        fi
}

# -- help-template
help_core[help-template]='Create help template'
help-template () {
	help_template_file=$ZSH_ROOT/cmds/cmds-$1.zshrc
	if [[ -z $1 ]]; then
		echo "-- Provide a name for the new help file"
	elif [[ -f $help_template_file ]]; then
		echo "-- File exists $help_template_file, exiting."
	else
		echo "-- Writting cmds file $help_template_file"
cat > $help_template_file <<TEMPLATE
# --
# $1 commands
#
# Example help: help_$1[wp]='Generate phpinfo() file'
#
# --
_debug " -- Loading \${(%):-%N}"

# - Init help array
typeset -gA help_$1

# What help file is this?
help_files[$1_description]="-- To install, run software <cmd>"
help_files[$1]='Software related commands'

TEMPLATE
	fi

}

# -- kbe
help_core[kbe]='Edit a KB with $EDITOR'
kbe () {
        _debug "\$EDITOR is $EDITOR and \$EDITOR_RUN is $EDITOR_RUN"
	if [[ $1 ]]; then
		${=EDITOR_RUN} $ZSHBOP_ROOT/kb/$1.md
	else
		echo "Usage: $funcstack <name of KB>"
	fi
}

# -- ce
help_core[ce]='Edit a cmd file with $EDITOR'
ce () {
        _debug "\$EDITOR is $EDITOR and \$EDITOR_RUN is $EDITOR_RUN"
        if [[ $1 ]]; then        
                ${=EDITOR_RUN} $ZSHBOP_ROOT/cmds/cmds-$1.zshrc
        else
                echo "Usage: $funcstack[1] <name of command file>"
        fi
}