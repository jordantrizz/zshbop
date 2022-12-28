# Free or Paid
* Free still just hard to install.
# Ubuntu install
## List of required supporting packages.
```
apt install -y            \
  libauthen-ntlm-perl     \
  libcgi-pm-perl          \
  libcrypt-openssl-rsa-perl   \
  libdata-uniqid-perl         \
  libencode-imaputf7-perl     \
  libfile-copy-recursive-perl \
  libfile-tail-perl        \
  libio-socket-inet6-perl  \
  libio-socket-ssl-perl    \
  libio-tee-perl           \
  libhtml-parser-perl      \
  libjson-webtoken-perl    \
  libmail-imapclient-perl  \
  libparse-recdescent-perl \
  libproc-processtable-perl \
  libmodule-scandeps-perl  \
  libreadonly-perl         \
  libregexp-common-perl    \
  libsys-meminfo-perl      \
  libterm-readkey-perl     \
  libtest-mockobject-perl  \
  libtest-pod-perl         \
  libunicode-string-perl   \
  liburi-perl              \
  libwww-perl              \
  libtest-nowarnings-perl  \
  libtest-deep-perl        \
  libtest-warn-perl        \
  make                     \
  time                     \
  cpanminus
```

## Download Install
```
wget -N https://raw.githubusercontent.com/imapsync/imapsync/master/imapsync
```

# Other
## Migrating to Microsoft 365 with imapsync
* https://tipsforadmins.com/importing-mailboxes-to-microsoft-365-using-imapsync/

## OAUTH2
* https://github.com/simonrob/email-oauth2-proxy.git
* https://github.com/imapsync/imapsync/issues/250

## OAUTH2 Microsoft 365 with Powershell
https://github.com/imapsync/imapsync/issues/250
```
Install-PackageProvider Nuget –Force
Install-Module –Name PowerShellGet –Force
Install-Module MSAL.PS -MaximumVersion 4.36.1.2 -AcceptLicense
Import-Module MSAL.PS -MaximumVersion 4.36.1.2
Clear-MsalTokenCache
$clientID = "08162f7c-0fd2-4200-a84a-f25a4db0b584" #thunderbird, see https://hg.mozilla.org/comm-central/file/tip/mailnews/base/src/OAuth2Providers.jsm
$secret = ConvertTo-SecureString 'TxRBilcHdC6WGBee]fs?QR:SJ8nI[g82' -AsPlainText -Force
$TenantId = "TENANTNAME.onmicrosoft.com"
$scope = "https://graph.microsoft.com/.default"
$myAccessToken = Get-MsalToken -ClientId $clientID `
         -TenantId $tenantID `
         -Scopes "$($scope)" `
         -clientsecret $secret
$myAccessToken.AccessToken
```

## OAUTH2 Microsoft 365 with Python
### Step 1 - Download muttoauth2
* ```wget https://gitlab.com/muttmua/mutt/-/raw/master/contrib/mutt_oauth2.py```

### Step 2 - Edit mutt_oauth2.py
```
ENCRYPTION_PIPE = ['gpg', '--encrypt', '--recipient', 'YOUR_GPG_IDENTITY']
DECRYPTION_PIPE = ['gpg', '--decrypt']
->
ENCRYPTION_PIPE = ['tee']
DECRYPTION_PIPE = ['tee']

        'redirect_uri': 'https://login.microsoftonline.com/common/oauth2/nativeclient',
->
        'redirect_uri': 'http://localhost/',

        'client_id': '',
        'client_secret': '',
->
        'client_id': '08162f7c-0fd2-4200-a84a-f25a4db0b584',
        'client_secret': 'TxRBilcHdC6WGBee]fs?QR:SJ8nI[g82',
```

### Step 3 - Run mutt_oauth2.py
#### Local System
```python mutt_oauth2.py TOKEN_FILENAME2 --verbose --authorize --authflow localhostauthcode```
#### Remote System
```python mutt_oauth2.py TOKEN_FILENAME2 --verbose --authorize --authflow authcode```

### Step 4 - Open URL and Copy and Paste Code
* Click on the URL and then when it errors out, copy the URL and extract the code= data.

### Step 5 - Provide Admin Account Access to Mailbox
```
Connect-ExchangeOnline'
Get-Mailbox user1@domain2.com | Add-MailboxPermission -User mail_syncer@domain2.com -AccessRights FullAccess -InheritanceType All
Get-Mailbox -ResultSize unlimited -Filter {(RecipientTypeDetails -eq 'UserMailbox') -and (Alias -ne 'Admin')} | Add-MailboxPermission -User admin@org.onmicrosoft.com -AccessRights fullaccess -InheritanceType all
```