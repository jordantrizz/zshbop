# --
# powershell commands
# --
_debug " -- Loading ${(%):-%N}"

# What help file is this?
help_filesfiles[m365]="Microsoft 365 Powershell commands"

# - Init help array
typeset -gA help_m365

_debug " -- Loading ${(%):-%N}"

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
    m365 cli setup
}


# ===============================================
# -- m365-npm-login
# ===============================================
help_m365[m365-npm-login]='Login to Microsoft 365 nodejs cli.'
m365-npm-login () {
    _loading "Logging in to Microsoft 365 CLI - m365 login"
    m365 login
}

# ===============================================
# -- m365-
# ===============================================
help_m365[m365-connect-exo]='Connect to Exchange Online.'
m365-connect-exo () {
    powershell-check 1
    [[ $? -ne 0 ]] && { echo "Powershell is not installed."; return 1; }

    pwsh -c "Connect-ExchangeOnline"
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
        pwsh -c "\$users = Get-Mailbox -ResultSize Unlimited foreach (\$user in \$users) { \$alias = \$user.Alias + \"@$DOMAIN\" Set-Mailbox -Identity \$user.Identity -EmailAddresses @{Add=\$alias -Whatif} }"
    else
        _error "You must specify either an email or a domain."
        m365_add_email_usage
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