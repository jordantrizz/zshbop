# Enable App Passwords and Basic authentication
* https://support.microsoft.com/en-us/account-billing/manage-app-passwords-for-two-step-verification-d6dc8c6d-4bf7-4851-ad95-6d07799387e9
* https://www.limilabs.com/blog/office365-enable-imap-pop3-smtp

## Enable Organizations Customization
1. Open powershell.
```
Install-Module –Name AzureAD
Install-Module –Name MSOnline
Install-Module -Name ExchangeOnlineManagement
Import-Module ExchangeOnlineManagement
Connect-ExchangeOnline
```

2. Check if your organizatio is dehydrated.
```
Get-OrganizationConfig | fl IsDehydrated
```

3. If your organization is dehydrated then you need to enable Exchange Customizations.
```
Enable-OrganizationCustomization
```

# Enable Email Forwarding
1. Log in to Microsoft 365 Defender as a Microsoft 365 administrator
2. Email & collaboration > Policies & rules > Threat policies > Anti-spam policies or https://security.microsoft.com/antispam
3. Click on Anti-spam outbound policy (Default) and scroll down to click the Edit protection settings link at the bottom of the sidebar.
4. Find the section called Forwarding Rules, and the dropdown list called Automatic Forwarding Rules. Pull that list down and choose On - Forwarding is enabled. Click Save at the bottom.

# Enable Automatic External Forwarding for Individual Mailboxes
1. Log in to Microsoft 365 Defender as a Microsoft 365 administrator
2. Email & collaboration > Policies & rules > Threat policies > Anti-spam policies or https://security.microsoft.com/antispam
3. Click + Create policy and choose Outbound.
4. Give your new outbound spam filter policy a Name and Description.
5. Click Next and search to find the user account you want to allow to forward, i.e. the email account that you are forwarding to Help Scout, which will display under the Users field after you select it. 
6. Click Next again, scroll down to the Forwarding rules section, and click the dropdown under Automatic forwarding rules. Choose On - Forwarding is enabled, then click Next.  
7. Review the settings on the last screen and click Create to create your new outbound policy for the specified user(s). 

# Powershell Commands for Microsoft 365
## Give User Full Access to All Mailboxes
```Get-Mailbox -ResultSize unlimited -Filter {(RecipientTypeDetails -eq 'UserMailbox') -and (Alias -ne 'Admin')} | Add-MailboxPermission -User AdministratorAccount@contoso.com -AccessRights fullaccess -InheritanceType all```

# Teams
## Teams Powershell Install
```Install-Module -Name MicrosoftTeams -Force -AllowClobber```

## Connect to Teams
```Connect-MicrosoftTeams```

