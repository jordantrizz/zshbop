<#
 Collects user + mailbox data:
 DisplayName | UPN | Created | Licenses | LastPwdChange | MailboxType | ForwardingEmail | AlternateEmail
#>

# --- Bootstrap required modules and connect ---
param(
    [switch]$Token,
    [switch]$Report,
    [switch]$Help,
    [Alias('Device')][switch]$ForceDevice
)
${ErrorActionPreference} = 'Stop'
## Progress helper (define early so traps and pre-flight blocks can use it)
if (-not (Get-Variable -Name Step -Scope Script -ErrorAction SilentlyContinue)) { $script:Step = 0 }
function Step {
    param([string]$Message)
    $script:Step++
    $ts = (Get-Date).ToString('HH:mm:ss')
    Write-Host ("[$ts][$('{0:00}' -f $script:Step)] $Message") -ForegroundColor Cyan
}
trap [System.Management.Automation.PipelineStoppedException] {
    Step ("Pipeline stopped: {0}" -f $_.Exception.Message)
    return
}
trap {
    Step ("Unhandled error: {0}" -f $_)
    return
}
## Optional product mapping (friendly marketing names)
if (Test-Path (Join-Path $PSScriptRoot 'M365ProductMap.ps1')) {
    try {
        . (Join-Path $PSScriptRoot 'M365ProductMap.ps1')
        Step ("Loaded product mapping: {0} GUID entries, {1} StringID entries" -f $script:M365ProductMap.ByGuid.Count, $script:M365ProductMap.ByString.Count)
    } catch { Step "Failed to load M365ProductMap.ps1: $_" }
} else {
    Step "Product mapping file not found; proceeding without marketing names"
}

function Show-Usage {
    Write-Host "Usage:" -ForegroundColor Yellow
    Write-Host "  pwsh Get-M365Report.ps1 -Token           # Acquire/refresh tokens via device code" -ForegroundColor Yellow
    Write-Host "  pwsh Get-M365Report.ps1 -Report          # Generate the M365 user/mailbox report" -ForegroundColor Yellow
    Write-Host "  pwsh Get-M365Report.ps1 -Token -Report   # Acquire tokens, then run the report" -ForegroundColor Yellow
    Write-Host "  pwsh Get-M365Report.ps1 -Help            # Show this help" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "NOTE: Device code authentication now uses Az.Accounts (Connect-AzAccount)" -ForegroundColor Cyan
    Write-Host "      which properly displays the device code in non-interactive contexts." -ForegroundColor Cyan
}

# Early mode selection: show help or do token acquisition only before any heavy work
if (-not $Token -and -not $Report -and -not $Help) { Show-Usage; return }
if ($Help) { Show-Usage; return }
if ($ForceDevice) { $env:M365_FORCE_DEVICE = '1' }
if ($Token) { $env:M365_FORCE_DEVICE = '1' }

# Detect headless environments (no GUI/browser)
function Test-Headless {
    <#
      Improved detection:
       - Honor env overrides M365_FORCE_DEVICE=1 or M365_DEVICE=1
       - Linux: if DISPLAY is empty treat as headless even if xdg-open exists (common minimal servers)
       - SSH sessions always headless
       - Windows: attempt to detect remoting session without UI (basic heuristic)
       - MacOS: allow override only; default remains non-headless to avoid false positives
    #>
    try {
        if ($env:M365_FORCE_DEVICE -eq '1' -or $env:M365_DEVICE -eq '1') { return $true }
        if ($env:SSH_CONNECTION) { return $true }
        if ($IsLinux -and [string]::IsNullOrEmpty($env:DISPLAY)) { return $true }
        if ($IsWindows) {
            if ($env:WT_SESSION -and -not (Get-Process -Name explorer -ErrorAction SilentlyContinue)) { return $true }
        }
        # MacOS typically can launch browser even without DISPLAY; skip unless forced
    } catch { }
    return $false
}

## Simple token cache (Graph) -- stores bearer and expiry in temp file
function Get-GraphTokenCachePath {
    return (Join-Path ([System.IO.Path]::GetTempPath()) 'graph_token_cache.json')
}

## Simple token cache (Exchange Online)
function Get-ExoTokenCachePath {
    return (Join-Path ([System.IO.Path]::GetTempPath()) 'exo_token_cache.json')
}

function Load-ExoCachedToken {
    $p = Get-ExoTokenCachePath
    if (-not (Test-Path $p)) { return $null }
    try {
        $o = Get-Content $p -Raw | ConvertFrom-Json
        if ($o.expires -and ([DateTime]::Parse($o.expires) -gt (Get-Date).AddMinutes(2))) { return $o } else { return $null }
    } catch { return $null }
}

function Save-ExoCachedToken($token, $expires) {
    $p = Get-ExoTokenCachePath
    try {
        @{ token = $token; expires = ($expires.ToString('o')); saved = (Get-Date).ToString('o') } | ConvertTo-Json | Set-Content -Path $p -Encoding UTF8
        Step ("Cached EXO token until {0}" -f $expires.ToString('u'))
    } catch { Step "Failed to write EXO token cache: $_" }
}

function Load-GraphCachedToken {
    $p = Get-GraphTokenCachePath
    if (-not (Test-Path $p)) { return $null }
    try {
        $o = Get-Content $p -Raw | ConvertFrom-Json
        if ($o.expires -and ([DateTime]::Parse($o.expires) -gt (Get-Date).AddMinutes(2))) { return $o } else { return $null }
    } catch { return $null }
}

function Save-GraphCachedToken($token, $expires) {
    $p = Get-GraphTokenCachePath
    try {
        @{ token = $token; expires = ($expires.ToString('o')); saved = (Get-Date).ToString('o') } | ConvertTo-Json | Set-Content -Path $p -Encoding UTF8
        Step ("Cached Graph token until {0}" -f $expires.ToString('u'))
    } catch { Step "Failed to write Graph token cache: $_" }
}

Step "Starting M365 script"
Step ("Environment: PSVersion={0} Edition={1} Platform={2}" -f $PSVersionTable.PSVersion, $PSVersionTable.PSEdition, $PSVersionTable.OS)
Step "Pre-flight: ensuring NuGet provider & PSGallery trust (only required for report)"
try {
    if (-not (Get-PackageProvider -Name NuGet -ErrorAction SilentlyContinue)) {
        Step "NuGet provider missing; installing"
        Install-PackageProvider -Name NuGet -Force -Scope CurrentUser -ErrorAction Stop
        Step "NuGet provider installed"
    } else { Step "NuGet provider already present" }
} catch { Step "ERROR installing NuGet provider: $_" }

try {
    $repo = Get-PSRepository -Name PSGallery -ErrorAction SilentlyContinue
    if ($repo -and $repo.InstallationPolicy -ne 'Trusted') {
        Step "Setting PSGallery InstallationPolicy=Trusted"
        Set-PSRepository -Name PSGallery -InstallationPolicy Trusted -ErrorAction Stop
    } elseif ($repo) {
        Step "PSGallery already trusted"
    } else {
        Step "PSGallery repository not found (custom environment?)"
    }
} catch { Step "WARNING: Unable to adjust PSGallery trust: $_" }

try {
    Step "Testing network reachability to PSGallery API"
    try {
        Invoke-WebRequest -Uri https://www.powershellgallery.com/api/v2/ -Method Head -TimeoutSec 10 -ErrorAction Stop | Out-Null
        Step "PSGallery reachable (HEAD)"
    } catch {
        if ($_.Exception.Response.StatusCode.Value__ -eq 405) {
            Step "HEAD not allowed; retrying with GET"
            Invoke-RestMethod -Uri "https://www.powershellgallery.com/api/v2/Packages()?$top=1" -Method Get -TimeoutSec 10 -ErrorAction Stop | Out-Null
            Step "PSGallery reachable (GET)"
        } else {
            throw
        }
    }
} catch { Step "WARNING: PSGallery not reachable: $_ (continuing)" }

function Ensure-Module {
    param(
        [Parameter(Mandatory=$true)][string]$Name
    )
    Step ("Checking module: {0}" -f $Name)
    if (-not (Get-Module -ListAvailable -Name $Name)) {
        Step ("Installing module '{0}'" -f $Name)
        try {
            Install-Module -Name $Name -Scope CurrentUser -Repository PSGallery -Force -AllowClobber -SkipPublisherCheck -ErrorAction Stop
            Step ("Installed module '{0}'" -f $Name)
        } catch {
            Write-Host "ERROR installing module '$Name': $_" -ForegroundColor Red
            return
        }
    } else { Step ("Module '{0}' already installed" -f $Name) }
    try {
        Step ("Importing module '{0}' (this may take a minute)..." -f $Name)
        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        Import-Module $Name -ErrorAction Stop
        $sw.Stop()
        Step ("Imported module '{0}' in {1}s" -f $Name, [math]::Round($sw.Elapsed.TotalSeconds,1))
    }
    catch {
        Write-Host "ERROR importing module '$Name': $_" -ForegroundColor Red
        return
    }
}

# Ensure required modules only if report or token requested
Ensure-Module -Name Az.Accounts
Ensure-Module -Name Microsoft.Graph.Authentication
if ($Report) {
    Ensure-Module -Name Microsoft.Graph.Users
    Ensure-Module -Name Microsoft.Graph.Identity.DirectoryManagement
    Ensure-Module -Name ExchangeOnlineManagement
}

# Connect to Microsoft Graph (prefer device code on headless or when forced); skip if only report needs it later?
$needGraph = $Token -or $Report
if (-not $needGraph) { Step "Skipping Graph connection (no --token or --report)"; return }

$Scopes = @(
    'User.Read.All'
    'Directory.Read.All'
    'AuditLog.Read.All'
)
${preferDevice} = ($env:M365_DEVICE -eq '1' -or $env:M365_FORCE_DEVICE -eq '1' -or (Test-Headless))
# In token mode, always force device code login for Graph regardless of cached tokens
$forceDeviceToken = $Token -eq $true

# Use Az.Accounts for device code authentication (works in non-interactive scripts)
if ($forceDeviceToken -or $preferDevice) {
    Step "Authenticating via Azure device code (Connect-AzAccount)"
    try {
        # Connect-AzAccount with device code - this displays the code correctly in scripts
        $azContext = Connect-AzAccount -UseDeviceAuthentication -ErrorAction Stop
        Step ("Azure authentication successful: {0}" -f $azContext.Context.Account.Id)
        
        # Get Graph API access token from Az context
        $graphToken = Get-AzAccessToken -ResourceUrl "https://graph.microsoft.com" -ErrorAction Stop
        Step "Obtained Microsoft Graph access token from Az context"
        
        # Connect to Graph using the token
        Connect-MgGraph -AccessToken ($graphToken.Token | ConvertTo-SecureString -AsPlainText -Force)
        
        Write-Host "`n╔═══════════════════════════════════════════════════════════╗" -ForegroundColor Green
        Write-Host "║  ✓ Successfully Connected to Microsoft Graph via Az Auth ║" -ForegroundColor Green
        Write-Host "╚═══════════════════════════════════════════════════════════╝`n" -ForegroundColor Green
        
        # Cache the token
        try {
            Save-GraphCachedToken -token $graphToken.Token -expires $graphToken.ExpiresOn
        } catch { Step "Unable to cache Graph token: $_" }
    } catch {
        Write-Host "Azure device authentication failed: $_" -ForegroundColor Red
        throw
    }
} else {
    # Standard interactive flow or cached token
    Step "Connecting to Microsoft Graph (standard flow)"
    try {
        $cached = Load-GraphCachedToken
        if ($cached) {
            Write-Host "`n╔═══════════════════════════════════════════════════════════╗" -ForegroundColor Green
            Write-Host "║  ✓ Using Cached Microsoft Graph Token                    ║" -ForegroundColor Green
            Write-Host "║    Expires: $(([DateTime]::Parse($cached.expires)).ToString('yyyy-MM-dd HH:mm:ss')) UTC                      ║" -ForegroundColor Green
            Write-Host "╚═══════════════════════════════════════════════════════════╝`n" -ForegroundColor Green
            Connect-MgGraph -AccessToken ($cached.token | ConvertTo-SecureString -AsPlainText -Force) -NoWelcome -ErrorAction Stop
        } else {
            $sw = [System.Diagnostics.Stopwatch]::StartNew()
            Connect-MgGraph -Scopes $Scopes -NoWelcome -ErrorAction Stop
            $sw.Stop()
            Step ("Graph connection established in {0}s" -f [math]::Round($sw.Elapsed.TotalSeconds,1))
            try {
                $gctx = Get-MgContext
                if ($gctx -and $gctx.AuthTokens) {
                    $tok = $gctx.AuthTokens.AccessToken
                    $exp = $gctx.AuthTokens.ExpiresOn
                    if ($tok -and $exp) { Save-GraphCachedToken -token $tok -expires $exp }
                }
            } catch { Step "Unable to extract Graph token for caching: $_" }
        }
    } catch {
        Write-Host "Standard Graph login failed. For device code authentication, run with -Token flag." -ForegroundColor Yellow
        throw
    }
}
Step "Connected to Microsoft Graph"

# Use beta profile to ensure SignInActivity is available
# Optionally use beta profile (set env var M365_USE_BETA=1 to enable)
if ($env:M365_USE_BETA -eq '1') {
    try { Select-MgProfile -Name beta; Step "Selected Microsoft Graph beta profile" } catch { Step "Could not select beta profile; continuing" }
} else {
    Step "Skipping Graph beta profile (set M365_USE_BETA=1 to enable)"
}

# Connect to Exchange Online (prefer device auth on headless or when forced)
if (-not $Report) {
    Step "Exchange Online connection skipped (no --report)"
} else {
    # Check for cached EXO token first
    $exoCached = Load-ExoCachedToken
    if ($exoCached) {
        Write-Host "`n╔═══════════════════════════════════════════════════════════╗" -ForegroundColor Green
        Write-Host "║  ✓ Using Cached Exchange Online Token                    ║" -ForegroundColor Green
        Write-Host "║    Expires: $(([DateTime]::Parse($exoCached.expires)).ToString('yyyy-MM-dd HH:mm:ss')) UTC                      ║" -ForegroundColor Green
        Write-Host "╚═══════════════════════════════════════════════════════════╝`n" -ForegroundColor Green
        try {
            Connect-ExchangeOnline -AccessToken $exoCached.token -ShowBanner:$false -ErrorAction Stop
            Step "Connected to Exchange Online using cached token"
        } catch {
            Step "Cached EXO token failed; falling back to device auth"
            Connect-ExchangeOnline -Device -ShowBanner:$false -ErrorAction Stop
            Step "EXO reconnected via device auth"
            try {
                if (Get-Command Get-EXOAccessToken -ErrorAction SilentlyContinue) {
                    $exoTok = Get-EXOAccessToken
                    if ($exoTok.AccessToken -and $exoTok.ExpiresOn) { Save-ExoCachedToken -token $exoTok.AccessToken -expires $exoTok.ExpiresOn }
                }
            } catch { Step "Unable to extract EXO token for caching: $_" }
        }
    } else {
        # No cached token - determine auth method
        if ($preferDevice -or $forceDeviceToken -or ($IsLinux -and [string]::IsNullOrEmpty($env:DISPLAY))) {
            Step "Connecting to Exchange Online via device code"
            Connect-ExchangeOnline -Device -ShowBanner:$false -ErrorAction Stop
            Step "EXO connection established"
            try {
                if (Get-Command Get-EXOAccessToken -ErrorAction SilentlyContinue) {
                    $exoTok = Get-EXOAccessToken
                    if ($exoTok.AccessToken -and $exoTok.ExpiresOn) { Save-ExoCachedToken -token $exoTok.AccessToken -expires $exoTok.ExpiresOn }
                }
            } catch { Step "Unable to extract EXO token for caching: $_" }
        } else {
            Step "Connecting to Exchange Online (standard)"
            try {
                Connect-ExchangeOnline -ShowBanner:$false -ErrorAction Stop
                Step "EXO connection established"
                try {
                    if (Get-Command Get-EXOAccessToken -ErrorAction SilentlyContinue) {
                        $exoTok = Get-EXOAccessToken
                        if ($exoTok.AccessToken -and $exoTok.ExpiresOn) { Save-ExoCachedToken -token $exoTok.AccessToken -expires $exoTok.ExpiresOn }
                    }
                } catch { Step "Unable to extract EXO token for caching: $_" }
            } catch {
                Step "Standard EXO login failed; retrying with device-based auth"
                Connect-ExchangeOnline -Device -ShowBanner:$false -ErrorAction Stop
                Step "EXO connected via device auth"
                try {
                    if (Get-Command Get-EXOAccessToken -ErrorAction SilentlyContinue) {
                        $exoTok = Get-EXOAccessToken
                        if ($exoTok.AccessToken -and $exoTok.ExpiresOn) { Save-ExoCachedToken -token $exoTok.AccessToken -expires $exoTok.ExpiresOn }
                    }
                } catch { Step "Unable to extract EXO token for caching: $_" }
            }
        }
    }
}
if ($Report) { Step "Connected to Exchange Online" }

"# ensure skuMap exists even in token-only mode" | Out-Null
$skuMap = @{}
if ($Report) {
    # --- License (SKU) map: GUID -> SkuPartNumber ---
    Step "Retrieving subscribed SKU license metadata"
    try {
        $skus = Get-MgSubscribedSku -All | Select-Object SkuId,SkuPartNumber
        foreach ($s in $skus) { if ($s.SkuId) { $skuMap[$s.SkuId.ToString()] = $s.SkuPartNumber } }
        Step ("Loaded {0} SKU mappings" -f $skus.Count)
        # Enhance with friendly product names where possible
        if ($script:M365ProductMap) {
            $enhancedCount = 0
            foreach ($k in @($skuMap.Keys)) {
                $raw = $skuMap[$k]
                $friendly = Get-M365ProductName -Identifier $raw -Map $script:M365ProductMap
                if ($friendly -and $friendly -ne $raw) { $skuMap[$k] = $friendly; $enhancedCount++ }
            }
            Step ("Enhanced {0} SKU entries with marketing names" -f $enhancedCount)
        }
    } catch {
        Step "Failed to retrieve subscribed SKUs; will output GUIDs for Licenses"
    }
}

# --- Pull Entra user info ---
if ($Report) {
    $rawUsers = Get-MgUser -All -Property DisplayName,UserPrincipalName,CreatedDateTime,AssignedLicenses,SignInActivity,OtherMails
} else {
    $rawUsers = @()
}
$users = $rawUsers | Select-Object DisplayName,
                              UserPrincipalName,
                              @{N='WhenCreated';E={$_.CreatedDateTime}},
                              @{N='Licenses';E={
                                    $ids = @($_.AssignedLicenses.SkuId)
                                    if (-not $ids -or $ids.Count -eq 0) { return '' }
                                    ($ids | ForEach-Object {
                                        $idStr = $_.ToString()
                                        if ($skuMap -and $skuMap.ContainsKey($idStr)) { $skuMap[$idStr] } else { $idStr }
                                    }) -join ';'
                               }},
                              @{N='LicenseIds';E={ ($_.AssignedLicenses.SkuId | ForEach-Object { $_.ToString() }) -join ';' }},
                              @{N='LastPasswordChange';E={$_.SignInActivity.LastPasswordChangeDateTime}},
                              @{N='AlternateEmail';E={[string]::Join(';',($_.OtherMails))}}
Step ("Retrieved {0} Entra ID users" -f $users.Count)

# --- Pull mailbox info (type + forwarding) ---
if ($Report) {
    $rawMailboxes = Get-Mailbox -ResultSize Unlimited
} else {
    $rawMailboxes = @()
}
$mailboxes = $rawMailboxes | Select-Object DisplayName,
                                   PrimarySmtpAddress,
                                   @{N='MailboxType';E={$_.RecipientTypeDetails}},
                                   @{N='ForwardingEmail';E={
                                       if ($_.ForwardingSmtpAddress) { $_.ForwardingSmtpAddress }
                                       elseif ($_.ForwardingAddress) { $_.ForwardingAddress.PrimarySmtpAddress }
                                       else { '' }
                                   }}
Step ("Retrieved {0} mailboxes" -f $mailboxes.Count)

# --- Merge datasets on UPN / PrimarySmtpAddress ---
$report = foreach ($u in $users) {
    $m = $mailboxes | Where-Object { $_.PrimarySmtpAddress -eq $u.UserPrincipalName }
    [PSCustomObject]@{
        DisplayName          = $u.DisplayName
        UserPrincipalName    = $u.UserPrincipalName
        WhenCreated          = $u.WhenCreated
        Licenses             = $u.Licenses
        LastPasswordChange   = $u.LastPasswordChange
        MailboxType          = $m.MailboxType
        ForwardingEmail      = $m.ForwardingEmail
        AlternateEmail       = $u.AlternateEmail
    }
}
if ($Report) { Step ("Merged user + mailbox data into {0} rows" -f $report.Count) }

# --- Export ---
if ($Report) {
    $tempDir = [System.IO.Path]::GetTempPath()
    Step ("Using temp directory: {0}" -f $tempDir)
    $path = Join-Path $tempDir ('M365_Report_{0:yyyyMMdd_HHmmss}.csv' -f (Get-Date))
    $report | Export-Csv -NoTypeInformation -Encoding UTF8 -Path $path
    Step "Report exported to $path"
    Write-Host "✅ Completed M365 report generation" -ForegroundColor Green
    Write-Host "Path copied to clipboard (if supported)" -ForegroundColor DarkGray
    try { $path | Set-Clipboard } catch { }
} elseif ($Token) {
    Write-Host "✅ Token acquisition completed (Graph context cached). Run with --report to generate output." -ForegroundColor Green
}
