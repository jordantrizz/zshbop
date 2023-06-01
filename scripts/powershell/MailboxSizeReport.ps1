<#
    .SYNOPSIS
    MailboxSizeReport.ps1

    .DESCRIPTION
    Display or export mailbox size report and many more information for a single user or all users (wildcard support).

    The script works for:
    -Exchange On-Premises (Run Exchange Management Shell)
    -Exchange Online (Connect to Exchange Online PowerShell)

    .LINK
    alitajran.com/get-mailbox-size-all-users-in-exchange-with-powershell

    .NOTES
    Written by: ALI TAJRAN
    Website: alitajran.com
    LinkedIn: linkedin.com/in/alitajran

    .CHANGELOG
    V1.00, 12/25/2019 - Initial version
    V1.10, 03/27/2023 - Optimized layout and changes to delimiter
#>

Write-host "

Mailbox Size Report
----------------------------

1.Display in Exchange Management Shell

2.Export to CSV File

3.Export to CSV File (Specific to Database)

4.Enter the Mailbox Name with Wild Card (Export)

5.Enter the Mailbox Name with Wild Card (Display)

6.Export to CSV File (OFFICE 365)

7.Enter the Mailbox Name with Wild Card (Export) (OFFICE 365)"-ForeGround "Cyan"

#----------------
# Script
#----------------

Write-Host "               "

$number = Read-Host "Choose The Task"
$output = @()
switch ($number) {

    1 {

        $AllMailbox = Get-mailbox -resultsize unlimited

        Foreach ($Mbx in $AllMailbox) {

            $Stats = Get-mailboxStatistics -Identity $Mbx.distinguishedname -WarningAction SilentlyContinue

            $userObj = New-Object PSObject

            $userObj | Add-Member NoteProperty -Name "Display Name" -Value $mbx.displayname
            $userObj | Add-Member NoteProperty -Name "Primary SMTP address" -Value $mbx.PrimarySmtpAddress
            $userObj | Add-Member NoteProperty -Name "TotalItemSize" -Value $Stats.TotalItemSize
            $userObj | Add-Member NoteProperty -Name "ItemCount" -Value $Stats.ItemCount

            Write-Output $Userobj

        }

        ; Break
    }

    2 {
        $i = 0 

        $CSVfile = Read-Host "Enter the Path of CSV file (Eg. C:\Report.csv)" 

        $AllMailbox = Get-mailbox -resultsize unlimited

        Foreach ($Mbx in $AllMailbox) {

            $Stats = Get-mailboxStatistics -Identity $Mbx.distinguishedname -WarningAction SilentlyContinue

            if (($Mbx.UseDatabaseQuotaDefaults -eq $true) -and (Get-MailboxDatabase $mbx.Database).ProhibitSendReceiveQuota.value -eq $null) {
                $ProhibitSendReceiveQuota = "Unlimited"
            }
            if (($Mbx.UseDatabaseQuotaDefaults -eq $true) -and (Get-MailboxDatabase $mbx.Database).ProhibitSendReceiveQuota.value -ne $null) {
                $ProhibitSendReceiveQuota = (Get-MailboxDatabase $mbx.Database).ProhibitSendReceiveQuota.value
            }
            if (($Mbx.UseDatabaseQuotaDefaults -eq $false) -and ($mbx.ProhibitSendReceiveQuota.value -eq $null)) {
                $ProhibitSendReceiveQuota = "Unlimited"
            }
            if (($Mbx.UseDatabaseQuotaDefaults -eq $false) -and ($mbx.ProhibitSendReceiveQuota.value -ne $null)) {
                $ProhibitSendReceiveQuota = $Mbx.ProhibitSendReceiveQuota.Value
            }
            if ($Mbx.ArchiveName.count -eq "0") {
                $ArchiveTotalItemSize = $null
                $ArchiveTotalItemCount = $null
            }
            if ($Mbx.ArchiveName -ge "1") {
                $MbxArchiveStats = Get-mailboxstatistics $Mbx.distinguishedname -Archive -WarningAction SilentlyContinue
                $ArchiveTotalItemSize = $MbxArchiveStats.TotalItemSize
                $ArchiveTotalItemCount = $MbxArchiveStats.BigFunnelMessageCount
            }

            $userObj = New-Object PSObject

            $userObj | Add-Member NoteProperty -Name "Display Name" -Value $mbx.displayname
            $userObj | Add-Member NoteProperty -Name "Alias" -Value $Mbx.Alias
            $userObj | Add-Member NoteProperty -Name "SamAccountName" -Value $Mbx.SamAccountName
            $userObj | Add-Member NoteProperty -Name "RecipientType" -Value $Mbx.RecipientTypeDetails
            $userObj | Add-Member NoteProperty -Name "Recipient OU" -Value $Mbx.OrganizationalUnit
            $userObj | Add-Member NoteProperty -Name "Primary SMTP address" -Value $Mbx.PrimarySmtpAddress
            $userObj | Add-Member NoteProperty -Name "Email Addresses" -Value ($Mbx.EmailAddresses.smtpaddress -join ",")
            $userObj | Add-Member NoteProperty -Name "Database" -Value $mbx.Database
            $userObj | Add-Member NoteProperty -Name "ServerName" -Value $mbx.ServerName
            if ($Stats) {
                $userObj | Add-Member NoteProperty -Name "TotalItemSize" -Value $Stats.TotalItemSize.Value
                $userObj | Add-Member NoteProperty -Name "ItemCount" -Value $Stats.ItemCount
                $userObj | Add-Member NoteProperty -Name "DeletedItemCount" -Value $Stats.DeletedItemCount
                $userObj | Add-Member NoteProperty -Name "TotalDeletedItemSize" -Value $Stats.TotalDeletedItemSize.Value
            }
            $userObj | Add-Member NoteProperty -Name "ProhibitSendReceiveQuota-In-MB" -Value $ProhibitSendReceiveQuota
            $userObj | Add-Member NoteProperty -Name "UseDatabaseQuotaDefaults" -Value $Mbx.UseDatabaseQuotaDefaults
            $userObj | Add-Member NoteProperty -Name "LastLogonTime" -Value $Stats.LastLogonTime
            $userObj | Add-Member NoteProperty -Name "ArchiveName" -Value ($Mbx.ArchiveName -join ",")
            $userObj | Add-Member NoteProperty -Name "ArchiveStatus" -Value $Mbx.ArchiveStatus
            $userObj | Add-Member NoteProperty -Name "ArchiveState" -Value $Mbx.ArchiveState 
            $userObj | Add-Member NoteProperty -Name "ArchiveQuota" -Value $Mbx.ArchiveQuota
            $userObj | Add-Member NoteProperty -Name "ArchiveTotalItemSize" -Value $ArchiveTotalItemSize
            $userObj | Add-Member NoteProperty -Name "ArchiveTotalItemCount" -Value $ArchiveTotalItemCount

            $output += $UserObj  
            # Update Counters and Write Progress
            $i++
            if ($AllMailbox.Count -ge 1) {
                Write-Progress -Activity "Scanning Mailboxes . . ." -Status "Scanned: $i of $($AllMailbox.Count)" -PercentComplete ($i / $AllMailbox.Count * 100)
            }
        }


        $output | Export-csv -Path $CSVfile -NoTypeInformation -Encoding UTF8 #-Delimiter ";"

        ; Break
    }

    3 {
        $i = 0 

        $CSVfile = Read-Host "Enter the Path of CSV file (Eg. C:\Report.csv)" 
        $Database = Read-Host "Enter the DatabaseName (Eg. Database 01)" 

        $AllMailbox = Get-mailbox -resultsize unlimited -Database "$Database"

        Foreach ($Mbx in $AllMailbox) {

            $Stats = Get-mailboxStatistics -Identity $Mbx.distinguishedname -WarningAction SilentlyContinue

            if (($Mbx.UseDatabaseQuotaDefaults -eq $true) -and (Get-MailboxDatabase $mbx.Database).ProhibitSendReceiveQuota.value -eq $null) {
                $ProhibitSendReceiveQuota = "Unlimited"
            }
            if (($Mbx.UseDatabaseQuotaDefaults -eq $true) -and (Get-MailboxDatabase $mbx.Database).ProhibitSendReceiveQuota.value -ne $null) {
                $ProhibitSendReceiveQuota = (Get-MailboxDatabase $mbx.Database).ProhibitSendReceiveQuota.Value
            }
            if (($Mbx.UseDatabaseQuotaDefaults -eq $false) -and ($mbx.ProhibitSendReceiveQuota.value -eq $null)) {
                $ProhibitSendReceiveQuota = "Unlimited"
            }
            if (($Mbx.UseDatabaseQuotaDefaults -eq $false) -and ($mbx.ProhibitSendReceiveQuota.value -ne $null)) {
                $ProhibitSendReceiveQuota = $Mbx.ProhibitSendReceiveQuota.Value
            }
            if ($Mbx.ArchiveName.count -eq "0") {
                $ArchiveTotalItemSize = $null
                $ArchiveTotalItemCount = $null
            }
            if ($Mbx.ArchiveName -ge "1") {
                $MbxArchiveStats = Get-mailboxstatistics $Mbx.distinguishedname -Archive -WarningAction SilentlyContinue
                $ArchiveTotalItemSize = $MbxArchiveStats.TotalItemSize
                $ArchiveTotalItemCount = $MbxArchiveStats.BigFunnelMessageCount
            }

            $userObj = New-Object PSObject

            $userObj | Add-Member NoteProperty -Name "Display Name" -Value $mbx.displayname
            $userObj | Add-Member NoteProperty -Name "Alias" -Value $Mbx.Alias
            $userObj | Add-Member NoteProperty -Name "SamAccountName" -Value $Mbx.SamAccountName
            $userObj | Add-Member NoteProperty -Name "RecipientType" -Value $Mbx.RecipientTypeDetails
            $userObj | Add-Member NoteProperty -Name "Recipient OU" -Value $Mbx.OrganizationalUnit
            $userObj | Add-Member NoteProperty -Name "Primary SMTP address" -Value $Mbx.PrimarySmtpAddress
            $userObj | Add-Member NoteProperty -Name "Email Addresses" -Value ($Mbx.EmailAddresses.smtpaddress -join ",")
            $userObj | Add-Member NoteProperty -Name "Database" -Value $mbx.Database
            $userObj | Add-Member NoteProperty -Name "ServerName" -Value $mbx.ServerName
            if ($Stats) {
                $userObj | Add-Member NoteProperty -Name "TotalItemSize" -Value $Stats.TotalItemSize
                $userObj | Add-Member NoteProperty -Name "ItemCount" -Value $Stats.ItemCount
                $userObj | Add-Member NoteProperty -Name "DeletedItemCount" -Value $Stats.DeletedItemCount
                $userObj | Add-Member NoteProperty -Name "TotalDeletedItemSize" -Value $Stats.TotalDeletedItemSize
            }
            $userObj | Add-Member NoteProperty -Name "ProhibitSendReceiveQuota-In-MB" -Value $ProhibitSendReceiveQuota
            $userObj | Add-Member NoteProperty -Name "UseDatabaseQuotaDefaults" -Value $Mbx.UseDatabaseQuotaDefaults
            $userObj | Add-Member NoteProperty -Name "LastLogonTime" -Value $Stats.LastLogonTime
            $userObj | Add-Member NoteProperty -Name "ArchiveName" -Value ($Mbx.ArchiveName -join ",")
            $userObj | Add-Member NoteProperty -Name "ArchiveStatus" -Value $Mbx.ArchiveStatus
            $userObj | Add-Member NoteProperty -Name "ArchiveState" -Value $Mbx.ArchiveState 
            $userObj | Add-Member NoteProperty -Name "ArchiveQuota" -Value $Mbx.ArchiveQuota
            $userObj | Add-Member NoteProperty -Name "ArchiveTotalItemSize" -Value $ArchiveTotalItemSize
            $userObj | Add-Member NoteProperty -Name "ArchiveTotalItemCount" -Value $ArchiveTotalItemCount

            $output += $UserObj  
            # Update Counters and Write Progress
            $i++
            if ($AllMailbox.Count -ge 1) {
                Write-Progress -Activity "Scanning Mailboxes . . ." -Status "Scanned: $i of $($AllMailbox.Count)" -PercentComplete ($i / $AllMailbox.Count * 100)
            }
        }


        $output | Export-csv -Path $CSVfile -NoTypeInformation -Encoding UTF8 #-Delimiter ";"

        ; Break
    }

    4 {
        $i = 0 
        $CSVfile = Read-Host "Enter the Path of CSV file (Eg. C:\DG.csv)" 

        $MailboxName = Read-Host "Enter the Mailbox name or Range (Eg. Mailboxname , Mi*,*Mik)"

        $AllMailbox = Get-mailbox $MailboxName -resultsize unlimited

        Foreach ($Mbx in $AllMailbox) {

            $Stats = Get-mailboxStatistics -Identity $Mbx.distinguishedname -WarningAction SilentlyContinue



            if (($Mbx.UseDatabaseQuotaDefaults -eq $true) -and (Get-MailboxDatabase $mbx.Database).ProhibitSendReceiveQuota.value -eq $null) {
                $ProhibitSendReceiveQuota = "Unlimited"
            }
            if (($Mbx.UseDatabaseQuotaDefaults -eq $true) -and (Get-MailboxDatabase $mbx.Database).ProhibitSendReceiveQuota.value -ne $null) {
                $ProhibitSendReceiveQuota = (Get-MailboxDatabase $mbx.Database).ProhibitSendReceiveQuota.Value
            }
            if (($Mbx.UseDatabaseQuotaDefaults -eq $false) -and ($mbx.ProhibitSendReceiveQuota.value -eq $null)) {
                $ProhibitSendReceiveQuota = "Unlimited"
            }
            if (($Mbx.UseDatabaseQuotaDefaults -eq $false) -and ($mbx.ProhibitSendReceiveQuota.value -ne $null)) {
                $ProhibitSendReceiveQuota = $Mbx.ProhibitSendReceiveQuota.Value
            }
            if ($Mbx.ArchiveName.count -eq "0") {
                $ArchiveTotalItemSize = $null
                $ArchiveTotalItemCount = $null
            }
            if ($Mbx.ArchiveName -ge "1") {
                $MbxArchiveStats = Get-mailboxstatistics $Mbx.distinguishedname -Archive -WarningAction SilentlyContinue
                $ArchiveTotalItemSize = $MbxArchiveStats.TotalItemSize
                $ArchiveTotalItemCount = $MbxArchiveStats.BigFunnelMessageCount
            }


            $userObj = New-Object PSObject

            $userObj | Add-Member NoteProperty -Name "Display Name" -Value $mbx.displayname
            $userObj | Add-Member NoteProperty -Name "Alias" -Value $Mbx.Alias
            $userObj | Add-Member NoteProperty -Name "SamAccountName" -Value $Mbx.SamAccountName
            $userObj | Add-Member NoteProperty -Name "RecipientType" -Value $Mbx.RecipientTypeDetails
            $userObj | Add-Member NoteProperty -Name "Recipient OU" -Value $Mbx.OrganizationalUnit
            $userObj | Add-Member NoteProperty -Name "Primary SMTP address" -Value $Mbx.PrimarySmtpAddress
            $userObj | Add-Member NoteProperty -Name "Email Addresses" -Value ($Mbx.EmailAddresses.smtpaddress -join ",")
            $userObj | Add-Member NoteProperty -Name "Database" -Value $mbx.Database
            $userObj | Add-Member NoteProperty -Name "ServerName" -Value $mbx.ServerName
            if ($Stats) {
                $userObj | Add-Member NoteProperty -Name "TotalItemSize" -Value $Stats.TotalItemSize
                $userObj | Add-Member NoteProperty -Name "ItemCount" -Value $Stats.ItemCount
                $userObj | Add-Member NoteProperty -Name "DeletedItemCount" -Value $Stats.DeletedItemCount
                $userObj | Add-Member NoteProperty -Name "TotalDeletedItemSize" -Value $Stats.TotalDeletedItemSize
            }
            $userObj | Add-Member NoteProperty -Name "ProhibitSendReceiveQuota-In-MB" -Value $ProhibitSendReceiveQuota
            $userObj | Add-Member NoteProperty -Name "UseDatabaseQuotaDefaults" -Value $Mbx.UseDatabaseQuotaDefaults
            $userObj | Add-Member NoteProperty -Name "LastLogonTime" -Value $Stats.LastLogonTime
            $userObj | Add-Member NoteProperty -Name "ArchiveName" -Value ($Mbx.ArchiveName -join ",")
            $userObj | Add-Member NoteProperty -Name "ArchiveStatus" -Value $Mbx.ArchiveStatus
            $userObj | Add-Member NoteProperty -Name "ArchiveState" -Value $Mbx.ArchiveState 
            $userObj | Add-Member NoteProperty -Name "ArchiveQuota" -Value $Mbx.ArchiveQuota
            $userObj | Add-Member NoteProperty -Name "ArchiveTotalItemSize" -Value $ArchiveTotalItemSize
            $userObj | Add-Member NoteProperty -Name "ArchiveTotalItemCount" -Value $ArchiveTotalItemCount

            $output += $UserObj  
            # Update Counters and Write Progress
            $i++
            if ($AllMailbox.Count -ge 1) {
                Write-Progress -Activity "Scanning Mailboxes . . ." -Status "Scanned: $i of $($AllMailbox.Count)" -PercentComplete ($i / $AllMailbox.Count * 100)
            }
        }

        $output | Export-csv -Path $CSVfile -NoTypeInformation -Encoding UTF8 #-Delimiter ";"

        ; Break
    }

    5 {

        $MailboxName = Read-Host "Enter the Mailbox name or Range (Eg. Mailboxname , Mi*,*Mik)"

        $AllMailbox = Get-mailbox $MailboxName -resultsize unlimited

        Foreach ($Mbx in $AllMailbox) {

            $Stats = Get-mailboxStatistics -Identity $Mbx.distinguishedname -WarningAction SilentlyContinue

            $userObj = New-Object PSObject

            $userObj | Add-Member NoteProperty -Name "Display Name" -Value $mbx.displayname
            $userObj | Add-Member NoteProperty -Name "Primary SMTP address" -Value $mbx.PrimarySmtpAddress
            $userObj | Add-Member NoteProperty -Name "TotalItemSize" -Value $Stats.TotalItemSize
            $userObj | Add-Member NoteProperty -Name "ItemCount" -Value $Stats.ItemCount

            Write-Output $Userobj

        }

        ; Break
    }

    6 {
        $i = 0 
        $CSVfile = Read-Host "Enter the Path of CSV file (Eg. C:\Report.csv)" 

        $AllMailbox = Get-mailbox -resultsize unlimited

        Foreach ($Mbx in $AllMailbox) {

            $Stats = Get-mailboxStatistics -Identity $Mbx.distinguishedname -WarningAction SilentlyContinue

            if ($Mbx.ArchiveName.count -eq "0") {
                $ArchiveTotalItemSize = $null
                $ArchiveTotalItemCount = $null
            }
            if ($Mbx.ArchiveName -ge "1") {
                $MbxArchiveStats = Get-mailboxstatistics $Mbx.distinguishedname -Archive -WarningAction SilentlyContinue
                $ArchiveTotalItemSize = $MbxArchiveStats.TotalItemSize
                $ArchiveTotalItemCount = $MbxArchiveStats.BigFunnelMessageCount
            }

            $userObj = New-Object PSObject

            $userObj | Add-Member NoteProperty -Name "Display Name" -Value $mbx.displayname
            $userObj | Add-Member NoteProperty -Name "Alias" -Value $Mbx.Alias
            $userObj | Add-Member NoteProperty -Name "SamAccountName" -Value $Mbx.SamAccountName
            $userObj | Add-Member NoteProperty -Name "RecipientType" -Value $Mbx.RecipientTypeDetails
            $userObj | Add-Member NoteProperty -Name "Recipient OU" -Value $Mbx.OrganizationalUnit
            $userObj | Add-Member NoteProperty -Name "Primary SMTP address" -Value $Mbx.PrimarySmtpAddress
            $userObj | Add-Member NoteProperty -Name "Email Addresses" -Value ($Mbx.EmailAddresses -join ",")
            $userObj | Add-Member NoteProperty -Name "Database" -Value $Stats.Database
            $userObj | Add-Member NoteProperty -Name "ServerName" -Value $Stats.ServerName
            $userObj | Add-Member NoteProperty -Name "TotalItemSize" -Value $Stats.TotalItemSize
            $userObj | Add-Member NoteProperty -Name "ItemCount" -Value $Stats.ItemCount
            $userObj | Add-Member NoteProperty -Name "DeletedItemCount" -Value $Stats.DeletedItemCount
            $userObj | Add-Member NoteProperty -Name "TotalDeletedItemSize" -Value $Stats.TotalDeletedItemSize
            $userObj | Add-Member NoteProperty -Name "ProhibitSendReceiveQuota-In-MB" -Value $Mbx.ProhibitSendReceiveQuota
            $userObj | Add-Member NoteProperty -Name "UseDatabaseQuotaDefaults" -Value $Mbx.UseDatabaseQuotaDefaults
            $userObj | Add-Member NoteProperty -Name "LastLogonTime" -Value $Stats.LastLogonTime
            $userObj | Add-Member NoteProperty -Name "ArchiveName" -Value ($Mbx.ArchiveName -join ",")
            $userObj | Add-Member NoteProperty -Name "ArchiveStatus" -Value $Mbx.ArchiveStatus
            $userObj | Add-Member NoteProperty -Name "ArchiveState" -Value $Mbx.ArchiveState 
            $userObj | Add-Member NoteProperty -Name "ArchiveQuota" -Value $Mbx.ArchiveQuota
            $userObj | Add-Member NoteProperty -Name "ArchiveTotalItemSize" -Value $ArchiveTotalItemSize
            $userObj | Add-Member NoteProperty -Name "ArchiveTotalItemCount" -Value $ArchiveTotalItemCount

            $output += $UserObj  
            # Update Counters and Write Progress
            $i++
            if ($AllMailbox.Count -ge 1) {
                Write-Progress -Activity "Scanning Mailboxes . . ." -Status "Scanned: $i of $($AllMailbox.Count)" -PercentComplete ($i / $AllMailbox.Count * 100)
            }
        }

        $output | Export-csv -Path $CSVfile -NoTypeInformation -Encoding UTF8 #-Delimiter ";"

        ; Break
    }

    7 {
        $i = 0
        $CSVfile = Read-Host "Enter the Path of CSV file (Eg. C:\DG.csv)" 

        $MailboxName = Read-Host "Enter the Mailbox name or Range (Eg. Mailboxname , Mi*,*Mik)"

        $AllMailbox = Get-mailbox $MailboxName -resultsize unlimited

        Foreach ($Mbx in $AllMailbox) {

            $Stats = Get-mailboxStatistics -Identity $Mbx.distinguishedname -WarningAction SilentlyContinue

            if ($Mbx.ArchiveName.count -eq "0") {
                $ArchiveTotalItemSize = $null
                $ArchiveTotalItemCount = $null
            }
            if ($Mbx.ArchiveName -ge "1") {
                $MbxArchiveStats = Get-mailboxstatistics $Mbx.distinguishedname -Archive -WarningAction SilentlyContinue
                $ArchiveTotalItemSize = $MbxArchiveStats.TotalItemSize
                $ArchiveTotalItemCount = $MbxArchiveStats.BigFunnelMessageCount
            }

            $userObj = New-Object PSObject

            $userObj | Add-Member NoteProperty -Name "Display Name" -Value $mbx.displayname
            $userObj | Add-Member NoteProperty -Name "Alias" -Value $Mbx.Alias
            $userObj | Add-Member NoteProperty -Name "SamAccountName" -Value $Mbx.SamAccountName
            $userObj | Add-Member NoteProperty -Name "RecipientType" -Value $Mbx.RecipientTypeDetails
            $userObj | Add-Member NoteProperty -Name "Recipient OU" -Value $Mbx.OrganizationalUnit
            $userObj | Add-Member NoteProperty -Name "Primary SMTP address" -Value $Mbx.PrimarySmtpAddress
            $userObj | Add-Member NoteProperty -Name "Email Addresses" -Value ($Mbx.EmailAddresses -join ",")
            $userObj | Add-Member NoteProperty -Name "Database" -Value $Stats.Database
            $userObj | Add-Member NoteProperty -Name "ServerName" -Value $Stats.ServerName
            $userObj | Add-Member NoteProperty -Name "TotalItemSize" -Value $Stats.TotalItemSize
            $userObj | Add-Member NoteProperty -Name "ItemCount" -Value $Stats.ItemCount
            $userObj | Add-Member NoteProperty -Name "DeletedItemCount" -Value $Stats.DeletedItemCount
            $userObj | Add-Member NoteProperty -Name "TotalDeletedItemSize" -Value $Stats.TotalDeletedItemSize
            $userObj | Add-Member NoteProperty -Name "ProhibitSendReceiveQuota-In-MB" -Value $Mbx.ProhibitSendReceiveQuota
            $userObj | Add-Member NoteProperty -Name "UseDatabaseQuotaDefaults" -Value $Mbx.UseDatabaseQuotaDefaults
            $userObj | Add-Member NoteProperty -Name "LastLogonTime" -Value $Stats.LastLogonTime
            $userObj | Add-Member NoteProperty -Name "ArchiveName" -Value ($Mbx.ArchiveName -join ",")
            $userObj | Add-Member NoteProperty -Name "ArchiveStatus" -Value $Mbx.ArchiveStatus
            $userObj | Add-Member NoteProperty -Name "ArchiveState" -Value $Mbx.ArchiveState 
            $userObj | Add-Member NoteProperty -Name "ArchiveQuota" -Value $Mbx.ArchiveQuota
            $userObj | Add-Member NoteProperty -Name "ArchiveTotalItemSize" -Value $ArchiveTotalItemSize
            $userObj | Add-Member NoteProperty -Name "ArchiveTotalItemCount" -Value $ArchiveTotalItemCount

            $output += $UserObj  
            # Update Counters and Write Progress
            $i++
            if ($AllMailbox.Count -ge 1) {
                Write-Progress -Activity "Scanning Mailboxes . . ." -Status "Scanned: $i of $($AllMailbox.Count)" -PercentComplete ($i / $AllMailbox.Count * 100) -ErrorAction SilentlyContinue
            }
        }

        $output | Export-csv -Path $CSVfile -NoTypeInformation -Encoding UTF8 #-Delimiter ";"

        ; Break
    }

    Default { Write-Host "No matches found , Enter Options 1 or 2" -ForeGround "red" }

}
