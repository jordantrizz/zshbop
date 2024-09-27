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
# -- m365-npm
# ===============================================
help_m365[m365-cli]='Install Microsoft 365 nodejs cli.'
m365-cli () {
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
# -- m365-setup
# ===============================================
help_m365[m365-setup]='Setup Microsoft 365 nodejs cli.'
m365-setup () {
    _loading "Setting up Microsoft 365 CLI - m365 cli setup"
    m365 setup
}


# ===============================================
# -- m365-login
# ===============================================
help_m365[m365-login]='Login to Microsoft 365 nodejs cli.'
m365-login () {
    _m365-login () {
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

    local MODE M365_EMAIL M365_USERNAME M365_DOMAIN
    zparseopts -D -E e:=ARG_EMAIL u:=ARG_USERNAME d:=ARG_DOMAIN a:=ARG_ALL

    _debugf "ARG_EMAIL: $ARG_EMAIL ARG_USERNAME: $ARG_USERNAME ARG_DOMAIN: $ARG_DOMAIN ARG_ALL: $ARG_ALL"
    if [[ -n $ARG_EMAIL ]]; then
        MODE="email"
        M365_EMAIL=$ARG_EMAIL
        M365_USERNAME=${ARG_USERNAME[2]}
    elif [[ -n $ARG_DOMAIN ]]; then
        MODE="domain"
        M365_DOMAIN=$ARG_DOMAIN
    fi

    if [[ $MODE == "email" ]]; then
        _loading "Adding email $M365_EMAIL to $M365_USERNAME"
        m365 entra user set --userName $M365_USERNAME --mailNickname $M365_USERNAME --userPrincipalName $M365_EMAIL
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
    _m365-set-primary-email-usage () {
        echo "Usage: m365-set-primary-email [-e <new-email> -u <username@domain>|-all <domain>] [-count <count>]"
        echo ""
        echo "Options:"
        echo "  -u <username@domain>  The username@domain to set the primary email for."
        echo "  -e <new-email>        The new email to set as the primary email."
        echo "  -all <domain>         Set the primary email for all users to the domain."
        echo "  -count <count>        Stop after setting the primary email for <count> users."
        echo "  -group-only           Update distribution groups only"
    }
    _m365-set-primary-email-proceed () {
        local MESSAGE=$@
        _loading "$MESSAGE"
        read -q "REPLY?Proceed? [y/N] "
        echo ""
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            return 0
        else
            return 1
        fi
    }

    local MODE M365_EMAIL M365_USERNAME DOMAIN CHECK_USER USER_FIRST_PART COUNT DO_COUNT
    zparseopts -D -E e:=ARG_EMAIL u:=ARG_USERNAME all:=ARG_ALL count:=ARG_COUNT groups-only=ARG_GROUP_ONLY

    _debugf "ARG_EMAIL: $ARG_EMAIL ARG_USERNAME: $ARG_USERNAME ARG_ALL: $ARG_ALL ARG_COUNT: $ARG_COUNT ARG_GROUP_ONLY: $ARG_GROUP_ONLY"
    if [[ -n $ARG_EMAIL ]]; then
        MODE="email"
        M365_EMAIL=${ARG_EMAIL[2]}
        M365_USERNAME=${ARG_USERNAME[2]}
    elif [[ -n $ARG_ALL ]]; then
        DOMAIN=${ARG_ALL[2]}
        if [[ -n $ARG_GROUP_ONLY ]]; then
            MODE="groups-only"
        else
            MODE="all"        
        fi
    else
        _error "You must specify either an email or a domain."
        _m365-set-primary-email-usage
        return 1
    fi

    if [[ -n $ARG_COUNT ]]; then
        DO_COUNT=${ARG_COUNT[2]}
    else
        DO_COUNT=0
    fi

    if [[ $MODE == "email" ]]; then
        _m365-set-primary-email-proceed "Setting primary email to $M365_EMAIL for $M365_USERNAME"
        [[ $? -ne 0 ]] && return 1
        _loading3 "Running: m365 entra user set --userName $M365_USERNAME --userPrincipalName $M365_EMAIL"
        m365 entra user set --userName $M365_USERNAME --userPrincipalName $M365_EMAIL
    elif [[ $MODE == "all" ]]; then    
        _m365-set-primary-email-proceed "Setting primary email to $DOMAIN for all users"
        [[ $? -ne 0 ]] && return 1
        m365 entra user list --query "[].userPrincipalName" --output text | while read user; do
            _loading2 "Setting $DOMAIN as primary email for $user"
            # Get the user's first part of their email before @ and last part after @
            USER_FIRST_PART=$(echo $user | cut -d'@' -f1)
            USER_LAST_PART=$(echo $user | cut -d'@' -f2)
            
            # Check if the user is already using the domain
            if [[ $USER_LAST_PART == $DOMAIN ]]; then
                _loading3 "User $user is already using $DOMAIN, skipping."
                continue
            else
                _loading3 "User $user is not using $DOMAIN, setting it as primary email"
            fi

            _loading3 "Running: m365 entra user set --userName $user --userPrincipalName $USER_FIRST_PART@$DOMAIN"
            m365 entra user set --userName $user --userPrincipalName $USER_FIRST_PART@$DOMAIN            
            COUNT=$((COUNT+1))
            if [[ $COUNT -eq $DO_COUNT ]]; then
                _error "Stopping after $DO_COUNT users."
                break
            fi
        done
        return 1
    elif [[ $MODE == "groups-only" ]]; then
        _m365-set-primary-email-proceed "Setting primary email to $DOMAIN for all groups"
        [[ $? -ne 0 ]] && return 1
        # Get all groups using powershell
        
    else
        _error "You must specify either an email or a domain."
        _m365-set-primary-email-usage
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

    local M365_USERNAME
    zparseopts -D -E u:=ARG_USERNAME

    _debugf "ARG_USERNAME: $ARG_USERNAME"
    if [[ -z $ARG_USERNAME ]]; then
        _error "You must specify a username."
        m365_get_user_usage
        return 1
    else
        M365_USERNAME=${ARG_USERNAME[2]}
    fi

    _loading "Getting user $M365_USERNAME"
    m365 entra user get --userName $M365_USERNAME
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

# ===============================================
# -- m365-shared-mailbox
# ===============================================
help_m365[m365-shared-mailbox]='Create a shared mailbox in Microsoft 365.'
m365-shared-mailbox () {
    m365_shared_mailbox_usage () {
        echo "Usage: m365-shared-mailbox -n <name> -e <email>"
    }

    zparseopts -D -E n:=ARG_NAME e:=ARG_EMAIL

    _debugf "ARG_NAME: $ARG_NAME ARG_EMAIL: $ARG_EMAIL"
    if [[ -z $ARG_NAME || -z $ARG_EMAIL ]]; then
        _error "You must specify a name and an email."
        m365_shared_mailbox_usage
        return 1
    fi

    _loading "Creating shared mailbox $ARG_NAME with email $ARG_EMAIL"
    pwsh -c "New-Mailbox -Name $ARG_NAME -Shared -PrimarySmtpAddress $ARG_EMAIL"
}

# ===============================================
# -- m365-convert-mailbox-shared
# ===============================================
help_m365[m365-convert-mailbox-shared]='Convert a mailbox to a shared mailbox in Microsoft 365.'
m365-convert-mailbox-shared () {
    m365_convert_mailbox_shared_usage () {
        echo "Usage: m365-convert-mailbox-shared -u <username> -upn <userprincipalname>"
    }

    local M365_USERNAME M365_UPN
    zparseopts -D -E u:=ARG_USERNAME upn:=ARG_USERPRINCIPALNAME

    _debugf "ARG_USERNAME: $ARG_USERNAME"
    if [[ -z $ARG_USERNAME ]]; then
        _error "You must specify a username."
        m365_convert_mailbox_shared_usage
        return 1
    else
        M365_USERNAME=${ARG_USERNAME[2]}
    fi

    if [[ -n $ARG_USERPRINCIPALNAME ]]; then 
        M365_UPN=${ARG_USERPRINCIPALNAME[2]}
    else
        # Get User Principal Name
        echo "Enter your Microsoft 365 username: "
        read M365_UPN
    fi

    _loading "Converting mailbox $M365_USERNAME to shared mailbox"
    pwsh -c "Import-Module ExchangeOnlineManagement;
    Connect-ExchangeOnline -UserPrincipalName $M365_UPN -ShowProgress \$true;
    Set-Mailbox -Identity $M365_USERNAME -Type Shared;
    Get-Mailbox -Identity $M365_USERNAME | Select-Object -Property UserPrincipalName, RecipientTypeDetails"
}

# ===============================================
# -- m365-set-display-name
# ===============================================
help_m365[m365-set-display-name]='Set the display name for a user in Microsoft 365.'
m365-set-display-name () {
    m365_set_display_name_usage () {
        echo "Usage: m365-set-display-name -u <username> -n <name>"
    }

    local M365_USERNAME M365_NAME
    zparseopts -D -E u:=ARG_USERNAME n:=ARG_NAME

    _debugf "ARG_USERNAME: $ARG_USERNAME ARG_NAME: $ARG_NAME"
    if [[ -z $ARG_USERNAME || -z $ARG_NAME ]]; then
        _error "You must specify a username and a name."
        m365_set_display_name_usage
        return 1
    else
        M365_USERNAME=${ARG_USERNAME[2]}
        M365_NAME=${ARG_NAME[2]}
    fi

    _loading "Setting display name for $M365_USERNAME to $M365_NAME"
    m365 entra user set --userName $M365_USERNAME --displayName $M365_NAME
}

# ===============================================
# -- m365-get-license
# ===============================================
help_m365[m365-get-license]='Get the licenses for a user in Microsoft 365.'
m365-get-license () {
    m365_get_license_usage () {
        echo "Usage: m365-get-license -u <username>"
    }

    local M365_USERNAME
    zparseopts -D -E u:=ARG_USERNAME

    _debugf "ARG_USERNAME: $ARG_USERNAME"
    if [[ -z $ARG_USERNAME ]]; then
        _error "You must specify a username."
        m365_get_license_usage
        return 1
    else
        M365_USERNAME=${ARG_USERNAME[2]}
    fi

    _loading "Getting licenses for $M365_USERNAME"
    m365 entra user license list --userName $M365_USERNAME --output text
}

# ===============================================
# -- m365-remove-license
# ===============================================
help_m365[m365-remove-license]='Remove a license from a user in Microsoft 365.'
m365-remove-license () {
    m365_remove_license_usage () {
        echo "Usage: m365-remove-license -u <username> -lid <license-id>"
    }

    local M365_USERNAME M365_LICENSE
    zparseopts -D -E u:=ARG_USERNAME lid:=ARG_LICENSE

    _debugf "ARG_USERNAME: $ARG_USERNAME ARG_LICENSE: $ARG_LICENSE"
    if [[ -z $ARG_USERNAME || -z $ARG_LICENSE ]]; then
        _error "You must specify a username and a license."
        m365_remove_license_usage
        return 1
    else
        M365_USERNAME=${ARG_USERNAME[2]}
        M365_LICENSE=${ARG_LICENSE[2]}
    fi

    _loading "Removing license $M365_LICENSE from $M365_USERNAME"
    m365 entra user license remove --userName $M365_USERNAME --ids $M365_LICENSE

    _loading "License removed, getting updated licenses for $M365_USERNAME"
    m365 entra user license list --userName $M365_USERNAME --output text
}

# ===============================================
# -- m365-set-group-primary-email
# ===============================================
help_m365[m365-set-group-primary-email]='Update the email for all groups in Microsoft 365.'
m365-set-group-primary-email () {
    m365_update_group_email_usage () {
        echo "Usage: m365-update-group-email [-group -email] | [-all -domain <domain>]"
    }

    local MODE M365_EMAIL M365_GROUP M365_DOMAIN
    zparseopts -D -E group:=ARG_GROUP email:=ARG_EMAIL all=ARG_ALL domain:=ARG_DOMAIN

    _debugf "ARG_GROUP: $ARG_GROUP ARG_EMAIL: $ARG_EMAIL ARG_ALL: $ARG_ALL ARG_DOMAIN: $ARG_DOMAIN"
    if [[ -n $ARG_GROUP && -n $ARG_EMAIL ]]; then
        MODE="group"
        M365_GROUP=${ARG_GROUP[2]}
        M365_EMAIL=${ARG_EMAIL[2]}
    elif [[ -n $ARG_ALL && -n $ARG_DOMAIN ]]; then
        MODE="all"
        M365_DOMAIN=${ARG_DOMAIN[2]}
    else
        _error "You must specify either a group and email or all and a domain."
        m365_update_group_email_usage
        return 1
    fi

    if [[ $MODE == "group" ]]; then
        _error "Not completed"
        return 1
    elif [[ $MODE == "all" ]]; then
        _loading "Updating email for all groups to $M365_DOMAIN"
        pwsh -c $ZBR/powershell/m365-set-group-primary-email.ps1 -newDomain $M365_DOMAIN
    else
        _error "You must specify either a group and email or all and a domain."
        m365_update_group_email_usage
        return 1
    fi
}