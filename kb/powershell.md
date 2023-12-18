# Install Powershell on Linux
* https://docs.microsoft.com/en-us/powershell/scripting/install/installing-powershell-on-linux?view=powershell-7.2
## Exchange Online
### Install Exchange Online Management Module
* ```Install-Module -Name ExchangeOnlineManagement```

### Login to Exchnage Online
```Connect-ExchangeOnline -UserPrincipalName```

### Fix Wacky WSMAN
* https://www.bloggingforlogging.com/2020/08/21/wacky-wsman-on-linux/
* ```sudo pwsh -Command 'Install-Module -Name PSWSMan -Scope AllUsers'```

### Connect Linux Headless
* ```Connect-ExchangeOnline -device```

### Enable External Tagging
* ```Set-ExternalInOutlook -Enabled $true```
* Verify ```Get-ExternalInOutlook``` 

#### White List External Domains
* ```Set-ExternalInOutlook -AllowList  @{Add="lazyadmin.nl", "lazydev.nl"}```
* ```Set-ExternalInOutlook -AllowList  @{Remove="lazyadmin.nl", "lazydev.nl"}```
* Verify ```Get-ExternalInOutlook```

# Microsoft 365
## CLI for Microsoft 365
* https://pnp.github.io/cli-microsoft365/

## Export Teams Chat
* https://arjunumenon.com/export-microsoft-teams-chat-conversations-powershell/