# Connect to Microsoft Teams PowerShell module
Connect-MicrosoftTeams

# Define the users to add as owners
$UserEmails = @("user1@example.com", "user2@example.com", "user3@example.com")

# Get all Teams in your organization
$Teams = Get-Team

# Iterate through each Team and add the users as owners
foreach ($Team in $Teams) {
    try {
        foreach ($UserEmail in $UserEmails) {
            # Add each user as an owner to the Team
            Add-TeamUser -GroupId $Team.GroupId -User $UserEmail -Role Owner

            Write-Host "User added as an owner to Team: $($Team.DisplayName)"
        }
    }
    catch {
        Write-Host "Failed to add users as owners to Team: $($Team.DisplayName)"
        Write-Host "Error: $($_.Exception.Message)"
    }
}

# Disconnect from Microsoft Teams PowerShell module
Disconnect-MicrosoftTeams
