# Example usage: pwsh-update-group-emails.ps1 -newDomain "newdomain.com"
# Check if argument is provided

# Define parameters
param (
    [string]$newDomain
)

# Function for usage
function Show-Usage {
    Write-Host "Usage: pwsh-update-group-emails.ps1 -newDomain <new domain>`n"    
}

# -- _error
function _error {
    Write-Host -ForegroundColor Red $args[0]
}

# -- _loading
function _loading {
    Write-Host -BackgroundColor Yellow -ForegroundColor Black -NoNewline $args[0]
    Write-Host ""  # Reset the color by writing an empty string
}

# -- _loading2
function _loading2 {
    Write-Host -ForegroundColor DarkGray $args[0]
}

# -- _success
function _success {
    Write-Host -ForegroundColor Green $args[0]
}

if (-not $newDomain) {
    Show-Usage
    _error "Please provide the new domain name as an argument"
    exit
}

function connectExchangeOnline {
    # Import the Exchange Online module
    Import-Module ExchangeOnlineManagement -WarningAction SilentlyContinue

    # Connect to Exchange Online
    Connect-ExchangeOnline -UserPrincipalName $env:UserPrincipalName -ShowProgress:$true -ShowBanner:$false

    # Check if the connection was successful
    if ($?) {
        _success "Connected to Exchange Online"
    } else {
        _error "Failed to connect to Exchange Online"
        exit
    }
}

function updateGroups {
    param (
        [string]$newDomain
    )

    # Get all distribution groups
    $groups = Get-DistributionGroup
    $groupCount = $groups.Count

    if ($groupCount -eq 0) {
        Write-Host "No distribution groups found"
        return
    }

    # Print out what we're going to do
    _loading2 "Updating primary email address for $groupCount distribution groups to $newDomain"

    # Ask to continue
    $continue = Read-Host "Do you want to continue? (Y/N)"
    if ($continue -ne "Y" -and $continue -ne "y") {
        Write-Host "Exiting..."
        return
    }

    foreach ($group in $groups) {
        # Get the primary email address
        $primaryEmail = $group.PrimarySmtpAddress.ToString()
        $groupDomain = $primaryEmail.Split("@")[1]

        # Skip if the primary email address contains 'onmicrosoft.com'
        if ($groupDomain -like "*onmicrosoft.com") {
            _loading2 "Skipping group $($group.Name) with primary email $primaryEmail"
            continue
        }

        # Check if the primary email address contains newDomain
        if ($groupDomain -like "*$newDomain") {
            _loading2 "Skipping group $primaryEmail contains $newDomain"
            continue
        }
        
        # Replace the current domain with newDomain
        $newEmail = $primaryEmail.Replace($groupDomain, $newDomain)

        # Set the new primary email address
        Set-DistributionGroup -Identity $group.Identity -PrimarySmtpAddress $newEmail

        # Check if last command was successful
        if ($?) {
            _success "Updated group $($group.Name) primary email from $primaryEmail to $newEmail"
        } else {
            _error "Failed to update group $($group.Name) primary email from $primaryEmail to $newEmail"
        }

    }

}

# -- updateM365Groups
function updateM365Groups {
    param (
        [string]$newDomain
    )

    # Get all Microsoft 365 groups
    $groups = Get-UnifiedGroup
    $groupCount = $groups.Count

    if ($groupCount -eq 0) {
        Write-Host "No Microsoft 365 groups found"
        return
    }

    # Print out what we're going to do
    _loading2 "Updating primary email address for $groupCount Microsoft 365 groups to $newDomain"

    # Ask to continue
    $continue = Read-Host "Do you want to continue? (Y/N)"
    if ($continue -ne "Y" -and $continue -ne "y") {
        Write-Host "Exiting..."
        return
    }

    foreach ($group in $groups) {
        # Get the primary email address
        $primaryEmail = $group.PrimarySmtpAddress.ToString()
        $groupDomain = $primaryEmail.Split("@")[1]

        # Skip if the primary email address contains 'onmicrosoft.com'
        if ($groupDomain -like "*onmicrosoft.com") {
            _loading2 "Skipping group $($group.DisplayName) with primary email $primaryEmail"
            continue
        }

        # Check if the primary email address contains newDomain
        if ($groupDomain -like "*$newDomain") {
            _loading2 "Skipping group $primaryEmail contains $newDomain"
            continue
        }
        
        # Replace the current domain with newDomain
        $newEmail = $primaryEmail.Replace($groupDomain, $newDomain)

        # Set the new primary email address
        Set-UnifiedGroup -Identity $group.Identity -PrimarySmtpAddress $newEmail

        # Check if last command was successful
        if ($?) {
            _success "Updated group $($group.DisplayName) primary email from $primaryEmail to $newEmail"
        } else {
            _error "Failed to update group $($group.DisplayName) primary email from $primaryEmail to $newEmail"
        }

    }
}

_loading "Connecting to Exchange Online"
connectExchangeOnline
_loading "Updating distribution groups"
updateGroups($newDomain)
_loading "Updating Microsoft 365 groups"
updateM365Groups($newDomain)

# Disconnect from Exchange Online
Disconnect-ExchangeOnline -Confirm:$false

