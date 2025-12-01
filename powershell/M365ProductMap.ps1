<#
 M365ProductMap.ps1
 Parses the large 'm365products.txt' dataset (tab-delimited) into two hash maps:
  - By GUID (Sku GUID) -> Product Name
  - By String ID (SkuPartNumber / String ID) -> Product Name
 Provides helper to resolve a friendly product name given either form.

 Parsing approach:
  - Treat any line with >= 3 tab-delimited fields as a new product record:
       Product Name<TAB>String ID<TAB>GUID<...>
  - Ignore subsequent lines that list service plans (they typically lack >=3 tabs).
  - First encountered mapping wins (duplicates are ignored).
  - GUID must match 36-char canonical pattern.

 Usage:
   . "$PSScriptRoot/M365ProductMap.ps1"
   $map = $script:M365ProductMap
   Get-M365ProductName -Identifier 'EXCHANGEENTERPRISE' -Map $map   # By String ID
   Get-M365ProductName -Identifier 'efb87545-963c-4e0d-99df-69c6916d9eb0' -Map $map  # By GUID
#>

function Import-M365Products {
    param(
        [string]$Path = (Join-Path $PSScriptRoot 'm365products.txt')
    )
    $result = @{ ByGuid = @{}; ByString = @{} }
    if (-not (Test-Path $Path)) { return $result }
    try {
        $content = Get-Content -Path $Path -Raw -Encoding UTF8
    } catch { return $result }
    foreach ($rawLine in ($content -split "`n")) {
        $line = $rawLine.TrimEnd("`r")
        if ([string]::IsNullOrWhiteSpace($line)) { continue }
        $parts = $line -split "`t"
        if ($parts.Length -ge 3) {
            $productName = $parts[0].Trim()
            $stringId    = $parts[1].Trim()
            $guid        = $parts[2].Trim()
            # Basic GUID pattern
            $isGuid = $guid -match '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$'
            if ($productName) {
                if ($stringId -and -not $result.ByString.ContainsKey($stringId)) { $result.ByString[$stringId] = $productName }
                if ($isGuid -and -not $result.ByGuid.ContainsKey($guid)) { $result.ByGuid[$guid] = $productName }
            }
        }
    }
    return $result
}

function Get-M365ProductName {
    param(
        [Parameter(Mandatory=$true)][string]$Identifier,
        [Parameter(Mandatory=$true)]$Map
    )
    if ($Map.ByString.ContainsKey($Identifier)) { return $Map.ByString[$Identifier] }
    if ($Map.ByGuid.ContainsKey($Identifier))   { return $Map.ByGuid[$Identifier] }
    return $null
}

# Load once when module is dot-sourced
$script:M365ProductMap = Import-M365Products
