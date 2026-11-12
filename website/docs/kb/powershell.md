---
title: PowerShell
description: "Knowledge base article on PowerShell. Also available in the shell as `kb powershell`."
---

<!-- BEGIN GENERATED: kb-powershell -->
* https://docs.microsoft.com/en-us/powershell/scripting/install/installing-powershell-on-linux?view=powershell-7.2
### Exchange Online
#### Install Exchange Online Management Module
* ```Install-Module -Name ExchangeOnlineManagement```

#### Login to Exchnage Online
```Connect-ExchangeOnline -UserPrincipalName```

#### Fix Wacky WSMAN
* https://www.bloggingforlogging.com/2020/08/21/wacky-wsman-on-linux/
* ```sudo pwsh -Command 'Install-Module -Name PSWSMan -Scope AllUsers'```

#### Connect Linux Headless
* ```Connect-ExchangeOnline -device```

#### Enable External Tagging
* ```Set-ExternalInOutlook -Enabled $true```
* Verify ```Get-ExternalInOutlook``` 

##### White List External Domains
* ```Set-ExternalInOutlook -AllowList  @{Add="lazyadmin.nl", "lazydev.nl"}```
* ```Set-ExternalInOutlook -AllowList  @{Remove="lazyadmin.nl", "lazydev.nl"}```
* Verify ```Get-ExternalInOutlook```

## Microsoft 365
### CLI for Microsoft 365
* https://pnp.github.io/cli-microsoft365/

### Export Teams Chat
* https://arjunumenon.com/export-microsoft-teams-chat-conversations-powershell/

---

*Generated from [`kb/powershell.md`](https://github.com/jordantrizz/zshbop/blob/next-release/kb/powershell.md) by
`npm run gen:kb`. The shell shows the same article with `kb powershell`.*

<!-- END GENERATED: kb-powershell -->
