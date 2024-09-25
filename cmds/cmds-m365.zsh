# --
# powershell commands
# --
_debug " -- Loading ${(%):-%N}"

# What help file is this?
help_files[m365]="Microsoft 365 Powershell commands"

# - Init help array
typeset -gA help_m365

_debug " -- Loading ${(%):-%N}"

# ===============================================
# -- _m365-check
# ===============================================
_m365-check () {
    _cmd_exists m365
    if [[ $? -ne 0 ]]; then
        _error "Microsoft 365 CLI is not installed. Run m365-install-npm"
        return 1
    else
        _loading "Microsoft 365 CLI is installed."        
    fi

    # Check if logged in
    M365_STATUS=$(m365 status)
    if [[ $M365_STATUS == "Logged in" ]]; then    
        _loading "Microsoft 365 CLI is logged in. Run m365-npm-setup"        
    else
        _error "Microsoft 365 CLI is not logged in."
        return 1
    fi
}

# ===============================================
# -- m365-install-npm
# ===============================================
help_m365[m365-npm-cli]='Install Microsoft 365 nodejs cli.'
m365-npm-cli () {
    # check if node is available
    _cmd_exists node
    if [[ $? -ne 0 ]]; then
        _error "Node is not installed."
        return 1
    fi
    _loading "Installing Microsoft 365 CLI - npm install -g @pnp/cli-microsoft365"
    npm install -g @pnp/cli-microsoft365
}

# ===============================================
# -- m365-npm-setup
# ===============================================
help_m365[m365-npm-setup]='Setup Microsoft 365 nodejs cli.'
m365-npm-setup () {
    _loading "Setting up Microsoft 365 CLI - m365 cli setup"
    m365 setup
}


# ===============================================
# -- m365-npm-login
# ===============================================
help_m365[m365-npm-login]='Login to Microsoft 365 nodejs cli.'
m365-npm-login () {
    _m365-npm-login () {
        echo "Usage: m365-npm-login -u <username>"
    }
    
    zparseopts -D -E u:=ARG_USERNAME

    if [[ -n $ARG_USERNAME ]]; then
        USERNAME=${ARG_USERNAME[2]}
        _loading "Logging in to Microsoft 365 CLI - m365 login"
        m365 login -u $USERNAME
    else
        _error "You must specify a username."
        _m365-npm-login
        return 1
    fi
    

}
# ===============================================
# -- m365-add-user-group
# ===============================================
help_m365[m365-add-user-group]='Add a user to a group in Microsoft 365.'
m365-add-user-group () {
    m365_add_user_group_usage () {
        echo "Usage: m365-add-user-group -u <username> -g <group>"
    }

    zparseopts -D -E u:=ARG_USERNAME g:=ARG_GROUP

    _debugf "ARG_USERNAME: $ARG_USERNAME ARG_GROUP: $ARG_GROUP"
    if [[ -z $ARG_USERNAME || -z $ARG_GROUP ]]; then
        _error "You must specify a username and a group."
        m365_add_user_group_usage
        return 1
    fi

    _loading "Adding $ARG_USERNAME to $ARG_GROUP"
    pwsh -c "Add-DistributionGroupMember -Identity $ARG_GROUP -Member $ARG_USERNAME"
}


# ===============================================
# -- m365-add-email
# ===============================================
help_m365[m365-add-email]='Add an email to a Microsoft 365 account.'
m365-add-email () {
    m365_add_email_usage () {
        echo "Usage: m365-add-email [-e <email> -u <username>|-d <domain>]"
    }

    zparseopts -D -E e:=ARG_EMAIL u:=ARG_USERNAME d:=ARG_DOMAIN a:=ARG_ALL

    _debugf "ARG_EMAIL: $ARG_EMAIL ARG_USERNAME: $ARG_USERNAME ARG_DOMAIN: $ARG_DOMAIN ARG_ALL: $ARG_ALL"
    if [[ -n $ARG_EMAIL ]]; then
        MODE="email"
        EMAIL=$ARG_EMAIL
    elif [[ -n $ARG_DOMAIN ]]; then
        MODE="domain"
        DOMAIN=$ARG_DOMAIN
    fi

    if [[ $MODE == "email" ]]; then
        _loading "Adding email $EMAIL to $ARG_USERNAME"
        pwsh -c "Set-Mailbox -Identity $ARG_USERNAME -EmailAddresses @{Add=\"$EMAIL\"}"
    elif [[ $MODE == "domain" ]]; then
        _loading "Adding domain $DOMAIN to all users"
        m365 entra user list --query "[].userPrincipalName" --output text | while read user; do
            _loading2 "Adding $DOMAIN to $user"
            pwsh -c "Set-Mailbox -Identity $user -EmailAddresses @{Add=\"$user@$DOMAIN\"}"
        done
    else
        _error "You must specify either an email or a domain."
        m365_add_email_usage
        return 1
    fi
}

# ===============================================
# -- m365-set-primary-email
# ===============================================
help_m365[m365-set-primary-email]='Set the primary email for a Microsoft 365 account.'
m365-set-primary-email () {
    m365_set_primary_email_usage () {
        echo "Usage: m365-set-primary-email [-e <email> -u <username>|-all <domain>]"
    }

    zparseopts -D -E e:=ARG_EMAIL u:=ARG_USERNAME a:=ARG_ALL

    _debugf "ARG_EMAIL: $ARG_EMAIL ARG_USERNAME: $ARG_USERNAME ARG_ALL: $ARG_ALL"
    if [[ -n $ARG_EMAIL ]]; then
        MODE="email"
        EMAIL=${ARG_EMAIL[2]}
        USERNAME=${ARG_USERNAME[2]}
    elif [[ -n $ARG_ALL ]]; then
        MODE="all"
        DOMAIN=${ARG_ALL[2]}
    fi

    if [[ $MODE == "email" ]]; then
        _loading "Setting primary email to $EMAIL for $USERNAME"
        _loading3 "Running: m365 entra user set --userName $USERNAME --mailNickname $USERNAME --userPrincipalName $USERNAME@$DOMAIN"
        m365 entra user set --userName $EMAIL --mailNickname $USERNAME --userPrincipalName $USERNAME@$DOMAIN
    elif [[ $MODE == "all" ]]; then
        _loading "Setting primary email to $DOMAIN for all users"
        m365 entra user list --query "[].userPrincipalName" --output text | while read user; do
            _loading2 "Setting primary email to $user@$DOMAIN for $user"
            pwsh -c "Set-Mailbox -Identity $user -PrimarySmtpAddress $user@$DOMAIN"
        done
    else
        _error "You must specify either an email or a domain."
        m365_set_primary_email_usage
        return 1
    fi
}

# ===============================================
# -- m365-get-user-groups
# ===============================================
help_m365[m365-get-user-groups]='Get the groups a user is a member of in Microsoft 365.'
m365-get-user-groups () {
    m365_get_user_groups_usage () {
        echo "Usage: m365-get-user-groups -u <username>"
    }

    zparseopts -D -E u:=ARG_USERNAME

    _debugf "ARG_USERNAME: $ARG_USERNAME"
    if [[ -z $ARG_USERNAME ]]; then
        _error "You must specify a username."
        m365_get_user_groups_usage
        return 1
    fi

    _loading "Getting groups for $ARG_USERNAME"
    pwsh -c "Get-DistributionGroupMember -Identity $ARG_USERNAME"
}

# ===============================================
# -- m365-get-user
# ===============================================
help_m365[m365-get-user]='Get a user in Microsoft 365.'
m365-get-user () {
    m365_get_user_usage () {
        echo "Usage: m365-get-user -u <username>"
    }

    zparseopts -D -E u:=ARG_USERNAME

    _debugf "ARG_USERNAME: $ARG_USERNAME"
    if [[ -z $ARG_USERNAME ]]; then
        _error "You must specify a username."
        m365_get_user_usage
        return 1
    fi

    _loading "Getting user $ARG_USERNAME"
    pwsh -c "Get-Mailbox -Identity $ARG_USERNAME"
}

# ===============================================
# -- m365-get-groups
# ===============================================
help_m365[m365-get-groups]='Get all groups in Microsoft 365.'
m365-get-groups () {
    _m365-check
    [[ $? -ne 0 ]] && return 1
    _loading "Getting all groups"
    m365 entra m365group list | jq '.[] | {displayName: .displayName, id: .id}'
}

# ===============================================
# -- m365-add-all-users-group
# ===============================================
help_m365[m365-add-all-users-group]='Add all users to a group in Microsoft 365.'
m365-add-all-users-group () {
    m365_add_all_users_group_usage () {
        echo "Usage: m365-add-all-users-group -g <group>"
    }

    zparseopts -D -E g:=ARG_GROUP

    _debugf "ARG_GROUP: $ARG_GROUP"
    if [[ -z $ARG_GROUP ]]; then
        _error "You must specify a group."
        m365_add_all_users_group_usage
        return 1
    fi

    # Check if group exists
    GROUP_OUTPUT=$(m365 entra m365group get --id $GROUP | jq '{displayName: .displayName, id: .id}')
    if [[ $? -ne 0 ]]; then
        _error "Group $GROUP does not exist."
        return 1
    else
        _loading2 "Group $GROUP exists."
        echo $GROUP_OUTPUT
    fi

    local GROUP=${ARG_GROUP[2]}
    _loading "Adding all users to $GROUP"
    USERS=($(m365 entra user list --query "[].userPrincipalName" --output text))
    
    for user in $USERS; do
        _loading2 "Adding $user to ${GROUP}"
        m365 entra m365group user add -i $GROUP --userNames $user
    done
}

# ===============================================
# -- m365-group-disable-welcome
# ===============================================
help_m365[m365-group-disable-welcome]='Disable welcome email for a group in Microsoft 365.'
m365-group-disable-welcome () {
    m365_group_disable_welcome_usage () {
        echo "Usage: m365-group-disable-welcome -g <group>"
    }

    zparseopts -D -E g:=ARG_GROUP

    _debugf "ARG_GROUP: $ARG_GROUP"
    if [[ -z $ARG_GROUP ]]; then
        _error "You must specify a group."
        m365_group_disable_welcome_usage
        return 1
    fi

    _loading "Disabling welcome email for $ARG_GROUP"
    pwsh -c "Set-UnifiedGroup -Identity $ARG_GROUP -UnifiedGroupWelcomeMessageEnabled:$false"
}

