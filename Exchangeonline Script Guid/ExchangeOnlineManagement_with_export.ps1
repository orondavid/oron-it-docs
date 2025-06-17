# Exchange Online Management Script with Main Menu Structure

# === Global Error Logger ===

function Convert-SkuToDisplayName {
    param (
        [string]$Sku
    )

    switch ($Sku) {
        "O365_BUSINESS_PREMIUM" { return "Microsoft 365 Business Standard" }
        "ENTERPRISEPACK" { return "Office 365 E3" }
        "BUSINESS_BASIC" { return "Microsoft 365 Business Basic" }
        "M365_BUSINESS_PREMIUM" { return "Microsoft 365 Business Premium" }
        "STANDARDPACK" { return "Office 365 E1" }
        "EXCHANGESTANDARD" { return "Exchange Online (Plan 1)" }
        "EXCHANGE_S_ENTERPRISE" { return "Exchange Online (Plan 2)" }
        "O365_BUSINESS" { return "Microsoft 365 Apps for Business" }
        "EXCHANGEENTERPRISE" { return "Exchange Online (Plan 2)" }
        "O365_BUSINESS_ESSENTIALS" { return "Microsoft 365 Business Basic (Legacy)" }
        "Microsoft_Teams_Exploratory_Dept" { return "Microsoft Teams Exploratory" }
        default { return $Sku }
    }
}


function Write-ErrorLog {
    param (
        [string]$FunctionName,
        [string]$ErrorMessage
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logLine = "$timestamp [$FunctionName] ERROR: $ErrorMessage"
    Add-Content -Path "C:\ps\script_errors.log" -Value $logLine
}


function Ensure-MgGraphConnected {
    $requiredScopes = @("User.ReadWrite.All", "Directory.AccessAsUser.All", "AuditLog.Read.All", "Directory.Read.All")

    $ctx = Get-MgContext
    $connectedScopes = if ($ctx) { $ctx.Scopes } else { @() }
    $missing = $requiredScopes | Where-Object { $_ -notin $connectedScopes }

    if (-not $ctx -or $missing.Count -gt 0) {
        try {
            if ($ctx) {
                Disconnect-MgGraph -ErrorAction SilentlyContinue
            }
        }
        catch {
            Write-Host "ℹ️  No existing Microsoft Graph session to disconnect." -ForegroundColor DarkGray
        }

        Write-Host "🔐 Connecting to Microsoft Graph with required scopes..." -ForegroundColor Cyan
        Connect-MgGraph -Scopes $requiredScopes -NoWelcome
    }
}



# בדיקה אם המודול קיים וטעינה
if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Write-Host "Installing ExchangeOnlineManagement module..." -ForegroundColor Yellow
    Install-Module -Name ExchangeOnlineManagement -Scope CurrentUser -Force
}

# טעינת המודול אם לא נטען
if (-not (Get-Module ExchangeOnlineManagement)) {
    Import-Module ExchangeOnlineManagement
}

# התחברות
if (-not (Get-PSSession | Where-Object { $_.ComputerName -like "*outlook.office365.com*" })) {
    $adminUPN = Read-Host "Enter your admin UPN (e.g., admin@yourdomain.com)"
    Connect-ExchangeOnline -UserPrincipalName $adminUPN -ShowBanner:$false
}


$global:ScriptDirectory = Split-Path -Parent $MyInvocation.MyCommand.Definition
$global:ErrorLogFile = Join-Path -Path $ScriptDirectory -ChildPath "error_log.txt"

$global:ErrorActionPreference = "Continue"




# Catch any terminating error at the engine level
Register-EngineEvent PowerShell.OnScriptTerminatingError -Action {
    $errorDetails = "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Terminating Error:`n$($_.SourceArgs[0])`n"
    Add-Content -Path $global:ErrorLogFile -Value $errorDetails
}

# Optional: Add logging for non-terminating errors too
Register-EngineEvent PowerShell.OnError -Action {
    $err = $_.SourceArgs[0]
    $details = "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Error: $($err.Exception.Message)`n"
    Add-Content -Path $global:ErrorLogFile -Value $details
}


function Ensure-ExchangeConnected {
    try {
        if (-not (Get-ConnectionInformation)) {
            Connect-ExchangeOnline -ErrorAction Stop
        }
    }
    catch {
        Write-Host "Could not connect to Exchange Online." -ForegroundColor Red
        exit
    }
}



function Show-Mailboxes {
    Ensure-MgGraphConnected

    Write-Host "`nFetching all users..." -ForegroundColor Cyan

    try {
        $users = Get-MgUser -All -Property Id, DisplayName, UserPrincipalName, Mail | Sort-Object DisplayName

        $result = foreach ($user in $users) {
            # בדיקת תיבת דואר
            $hasMailbox = if ($user.Mail) { "Yes" } else { "No" }

            # רישיון
            $licenseDetails = Get-MgUserLicenseDetail -UserId $user.Id -ErrorAction SilentlyContinue
            $hasLicense = if ($licenseDetails) { "Yes" } else { "No" }

            # סוגי הרישיונות (רשימה מופרדת בפסיקים)
            $licenseTypes = if ($licenseDetails) {
				($licenseDetails.SkuPartNumber | ForEach-Object { Convert-SkuToDisplayName -Sku $_ }) -join ", "
            }
            else {
                ""
            }


            [PSCustomObject]@{
                DisplayName       = $user.DisplayName
                UserPrincipalName = $user.UserPrincipalName
                HasMailbox        = $hasMailbox
                Licensed          = $hasLicense
                LicenseType       = $licenseTypes
            }
        }

        $result | Format-Table -AutoSize

        $saveToTXT = Read-Host "Do you want to save the output to a TXT file? (Y/N)"
        if ($saveToTXT -eq 'Y' -or $saveToTXT -eq 'y') {
            $txtPath = Join-Path -Path $PSScriptRoot -ChildPath "result_export.txt"
            $result | Format-Table -AutoSize | Out-String | Set-Content -Path $txtPath -Encoding UTF8
            Write-Host "✅ Output saved to: $txtPath" -ForegroundColor Green
        }


    }
    catch {
        Write-ErrorLog -FunctionName "Show-Mailboxes" -ErrorMessage $_.Exception.Message
        Write-Host "Error fetching users: $_" -ForegroundColor Red
    }

    Pause
}



function Show-MailboxSize {
    Ensure-ExchangeConnected

    # שליפת תיבות הדואר והמרה לרשימה אינדקסבילית אמיתית
    $mailboxes = Get-Mailbox -ResultSize Unlimited | Select-Object DisplayName, UserPrincipalName
    $mailboxList = @()
    foreach ($m in $mailboxes) {
        $mailboxList += $m
    }

    if ($mailboxList.Count -eq 0) {
        Write-Host "No mailboxes found." -ForegroundColor Yellow
        return
    }

    # תפריט ממוספר
    Write-Host "`nSelect a mailbox:`n"
    for ($i = 0; $i -lt $mailboxList.Count; $i++) {
        $index = $i + 1
        $name = $mailboxList[$i].DisplayName
        $upn = $mailboxList[$i].UserPrincipalName
        Write-Host "$index. $name <$upn>"
    }

    # קלט
    try {
        $inputRaw = Read-Host "`nEnter the number of the mailbox"

        if (-not [int]::TryParse($inputRaw, [ref]$null)) {
            throw "Invalid input: '$inputRaw' is not a number."
        }

        $selection = [int]$inputRaw

        if ($selection -lt 1 -or $selection -gt $mailboxList.Count) {
            throw "Invalid selection: $selection is out of range (1-$($mailboxList.Count))."
        }

        $selectedUPN = $mailboxList[$selection - 1].UserPrincipalName
        $result = Get-MailboxStatistics -Identity $selectedUPN | Select DisplayName, TotalItemSize, ItemCount
        $result | Format-Table -AutoSize

        $saveToCSV = Read-Host "Do you want to save the output to a CSV file? (Y/N)"
        if ($saveToCSV -eq 'Y' -or $saveToCSV -eq 'y') {
            $csvPath = Join-Path -Path $PSScriptRoot -ChildPath "result_export.csv"
            $result | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8
            Write-Host "✅ Output saved to: $csvPath" -ForegroundColor Green
        }

    }
    catch {
        Write-ErrorLog -FunctionName "Show-MailboxSize" -ErrorMessage $_.Exception.Message
        Write-Host "❌ Error: $($_.Exception.Message)" -ForegroundColor Red
    }

    Pause
}




function Show-Forwarding {
    Ensure-ExchangeConnected

    try {
        $mailboxes = Get-Mailbox -ResultSize Unlimited | Where-Object {
            $_.ForwardingAddress -or $_.ForwardingSmtpAddress
        }

        $results = foreach ($mbx in $mailboxes) {
            [PSCustomObject]@{
                DisplayName               = $mbx.DisplayName
                UserPrincipalName         = $mbx.UserPrincipalName
                ForwardingAddress         = $mbx.ForwardingAddress
                ForwardingSmtpAddress     = $mbx.ForwardingSmtpAddress
                KeepCopyInOriginalMailbox = $mbx.DeliverToMailboxAndForward
            }
        }

        if ($results) {
            $results | Format-Table -AutoSize

            $saveToCSV = Read-Host "Do you want to save the output to a CSV file? (Y/N)"
            if ($saveToCSV -eq 'Y' -or $saveToCSV -eq 'y') {
                $csvPath = Join-Path -Path $PSScriptRoot -ChildPath "results_export.csv"
                $results | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8
                Write-Host "✅ Output saved to: $csvPath" -ForegroundColor Green
            }
        }
        else {
            Write-Host "No mailboxes with forwarding settings found." -ForegroundColor Green
        }
    }
    catch {
        Write-ErrorLog -FunctionName "Show-Forwarding" -ErrorMessage $_.Exception.Message
        Write-Host "❌ Error in Show-Forwarding: $($_.Exception.Message)" -ForegroundColor Red
    }

    Pause
}



function Show-ArchiveEnabled {
    Ensure-ExchangeConnected
    try {
		
        Get-Mailbox -ResultSize Unlimited | Where-Object { $_.ArchiveStatus -eq "Active" } |
        Select DisplayName, UserPrincipalName, ArchiveStatus | Format-Table -AutoSize
        Read-Host "`nPress Enter to return to the main menu"
    }
    catch {
        Write-ErrorLog -FunctionName "Show-ArchiveEnabled" -ErrorMessage $_.Exception.Message
        Write-Host "❌ Error in Show-ArchiveEnabled: $($_.Exception.Message)" -ForegroundColor Red
    }
	
    Pause
}


function Show-FullAccessPermissions {
    Ensure-ExchangeConnected
    try {
        $results = @()
        Get-Mailbox -ResultSize Unlimited | ForEach-Object {
            $mbx = $_
            $perms = Get-MailboxPermission -Identity $mbx.UserPrincipalName | Where-Object {
                $_.User -ne "NT AUTHORITY\\SELF" -and $_.AccessRights -contains "FullAccess"
            } | Select @{Name = 'Mailbox'; Expression = { $mbx.DisplayName } }, User, AccessRights
            $results += $perms
        }
        $results | Format-Table -AutoSize

        $saveToCSV = Read-Host "Do you want to save the output to a CSV file? (Y/N)"
        if ($saveToCSV -eq 'Y' -or $saveToCSV -eq 'y') {
            $csvPath = Join-Path -Path $PSScriptRoot -ChildPath "results_export.csv"
            $results | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8
            Write-Host "✅ Output saved to: $csvPath" -ForegroundColor Green
        }
    
        Read-Host "`nPress Enter to return to the main menu"
    }
    catch {
        Write-ErrorLog -FunctionName "Show-FullAccessPermissions" -ErrorMessage $_.Exception.Message
        Write-Host "❌ Error in Show-FullAccessPermissions: $($_.Exception.Message)" -ForegroundColor Red
    }
	
    Pause
}

function Show-SendAsPermissions {
    Ensure-ExchangeConnected
    try {
		
        Get-RecipientPermission -ResultSize Unlimited | Where-Object {
            $_.AccessRights -contains "SendAs"
        } | Select Identity, Trustee, AccessRights | Format-Table -AutoSize
        Read-Host "`nPress Enter to return to the main menu"
    }
    catch {
        Write-ErrorLog -FunctionName "Show-SendAsPermissions" -ErrorMessage $_.Exception.Message
        Write-Host "❌ Error in Show-SendAsPermissions: $($_.Exception.Message)" -ForegroundColor Red
    }
	
    Pause
}

function Show-InactiveMailboxes {
    Ensure-ExchangeConnected
    try {
        $threshold = (Get-Date).AddDays(-90)
        $results = @()

        $mailboxes = Get-Mailbox -ResultSize Unlimited
        foreach ($mbx in $mailboxes) {
            try {
                $stat = Get-MailboxStatistics -Identity $mbx.UserPrincipalName -ErrorAction Stop
                if ($stat.LastLogonTime -and $stat.LastLogonTime -lt $threshold) {
                    $results += [PSCustomObject]@{
                        DisplayName       = $mbx.DisplayName
                        LastLogonTime     = $stat.LastLogonTime
                        UserPrincipalName = $mbx.UserPrincipalName
                    }
                }
            }
            catch {
                Write-Host "❌ Error in Show-InactiveMailboxes: $($_.Exception.Message)" -ForegroundColor Red
                Write-Warning "Failed to get statistics for $($mbx.UserPrincipalName): $($_.Exception.Message)"
            }
        }

        if ($results.Count -gt 0) {
            $results | Sort-Object LastLogonTime | Format-Table -AutoSize
            Write-Host "`nTotal inactive mailboxes found (90+ Days): $($results.Count)" -ForegroundColor Yellow
        }
        else {
            Write-Host "No inactive mailboxes found (no one idle for more than 90 days)." -ForegroundColor Green
        }

        Read-Host "`nPress Enter to return to the main menu"
    }
    catch {
        Write-ErrorLog -FunctionName "Show-InactiveMailboxes" -ErrorMessage $_.Exception.Message
        Write-Host "❌ Unexpected error in Show-InactiveMailboxes: $($_.Exception.Message)" -ForegroundColor Red
    }
	
    Pause
	
}



function Show-SharedMailboxes {
    Ensure-ExchangeConnected
    try {

        Get-Mailbox -ResultSize Unlimited | Where-Object { $_.RecipientTypeDetails -eq "SharedMailbox" } |
        Select DisplayName, UserPrincipalName, PrimarySmtpAddress | Format-Table -AutoSize
            
        Read-Host "`nPress Enter to return to the main menu"
    }

    catch {
        Write-ErrorLog -FunctionName "Show-SharedMailboxes" -ErrorMessage $_.Exception.Message
    }

    Pause
}

function Export-MailboxesToCSV {
    Ensure-ExchangeConnected
    try {

        $path = Read-Host "Enter path to save the CSV file (e.g., C:\\MailboxList.csv)"
        Get-Mailbox -ResultSize Unlimited | Select DisplayName, UserPrincipalName
        Export-Csv -Path $path -Encoding UTF8 -NoTypeInformation
        Write-Host "✅ File saved successfully: $path" -ForegroundColor Green
    }
    catch {
        Write-ErrorLog -FunctionName "Export-MailboxesToCS" -ErrorMessage $_.Exception.Message
    }

    Pause
}


function Show-MailboxLicenses {
    Ensure-ExchangeConnected
    Ensure-MgGraphConnected
    try {

        $mailboxes = Get-Mailbox -ResultSize Unlimited
        $results = @()
        foreach ($mbx in $mailboxes) {
            $user = Get-MgUser -UserId $mbx.UserPrincipalName -ErrorAction SilentlyContinue
            $licenses = if ($user) {
				(Get-MgUserLicenseDetail -UserId $user.Id | ForEach-Object { Convert-SkuToDisplayName -Sku $_.SkuPartNumber }) -join ", "
            }

            else {
                "User not found in Graph"
            }
            $results += [PSCustomObject]@{
                DisplayName       = $mbx.DisplayName
                UserPrincipalName = $mbx.UserPrincipalName
                Licenses          = $licenses
            }
        }
        $results | Format-Table -AutoSize

        $saveToCSV = Read-Host "Do you want to save the output to a CSV file? (Y/N)"
        if ($saveToCSV -eq 'Y' -or $saveToCSV -eq 'y') {
            $csvPath = Join-Path -Path $PSScriptRoot -ChildPath "results_export.csv"
            $results | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8
            Write-Host "✅ Output saved to: $csvPath" -ForegroundColor Green
        }

        Read-Host "`nPress Enter to return to the main menu"
    }
    catch {
        Write-ErrorLog -FunctionName "Show-MailboxLicenses" -ErrorMessage $_.Exception.Message
    }

    Pause

}



function Show-MailboxesOverQuota {
    Ensure-ExchangeConnected
    try {

        Write-Host "Mailboxes over quota" -ForegroundColor Red

        $mailboxes = Get-Mailbox -ResultSize Unlimited

        foreach ($mbx in $mailboxes) {
            $stats = Get-MailboxStatistics -Identity $mbx.UserPrincipalName -ErrorAction SilentlyContinue
            $quotaString = $mbx.ProhibitSendReceiveQuota
            $sizeString = $stats.TotalItemSize

            if ($quotaString -and $sizeString) {
                # Convert quota string to MB
                if ($quotaString -match "([\d\.]+)\s*(MB|GB|TB)") {
                    $quotaValue = [double]$matches[1]
                    $quotaUnit = $matches[2]

                    switch ($quotaUnit) {
                        "MB" { $quotaMB = $quotaValue }
                        "GB" { $quotaMB = $quotaValue * 1024 }
                        "TB" { $quotaMB = $quotaValue * 1024 * 1024 }
                    }
                }

                # Convert size string to MB
                if ($sizeString -match "([\d\.]+)\s*(MB|GB|TB)") {
                    $sizeValue = [double]$matches[1]
                    $sizeUnit = $matches[2]

                    switch ($sizeUnit) {
                        "MB" { $currentSizeMB = $sizeValue }
                        "GB" { $currentSizeMB = $sizeValue * 1024 }
                        "TB" { $currentSizeMB = $sizeValue * 1024 * 1024 }
                    }
                }

                if ($currentSizeMB -gt $quotaMB) {
                    [PSCustomObject]@{
                        DisplayName       = $mbx.DisplayName
                        UserPrincipalName = $mbx.UserPrincipalName
                        CurrentSizeMB     = [math]::Round($currentSizeMB, 2)
                        QuotaLimitMB      = [math]::Round($quotaMB, 2)
                    }
                }
            }
        }  Format-Table -AutoSize

    }
    catch {
        Write-ErrorLog -FunctionName "Show-MailboxesOverQuota" -ErrorMessage $_.Exception.Message
    }

    Pause
}

function Show-MailboxesWithoutLicense {
    Ensure-MgGraphConnected
    Ensure-ExchangeConnected

    try {
        Write-Host "`n🚫 Mailboxes without a license:`n" -ForegroundColor Yellow

        $mailboxes = Get-Mailbox -ResultSize Unlimited
        $results = foreach ($mbx in $mailboxes) {
            $user = Get-MgUser -UserId $mbx.UserPrincipalName -ErrorAction SilentlyContinue
            if ($user) {
                $licenseDetails = Get-MgUserLicenseDetail -UserId $user.Id -ErrorAction SilentlyContinue
                $skuList = $licenseDetails | ForEach-Object { Convert-SkuToDisplayName -Sku $_.SkuPartNumber }

                if (-not $skuList -or $skuList.Count -eq 0) {
                    [PSCustomObject]@{
                        DisplayName       = $mbx.DisplayName
                        UserPrincipalName = $mbx.UserPrincipalName
                        Licenses          = "❌ None"
                    }
                }
            }
        }

        if ($results) {
            $results | Format-Table -AutoSize

            $saveToCSV = Read-Host "Do you want to save the output to a CSV file? (Y/N)"
            if ($saveToCSV -eq 'Y' -or $saveToCSV -eq 'y') {
                $csvPath = Join-Path -Path $PSScriptRoot -ChildPath "mailboxes_without_license.csv"
                $results | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8
                Write-Host "✅ Output saved to: $csvPath" -ForegroundColor Green
            }
        }
        else {
            Write-Host "All mailboxes have at least one license." -ForegroundColor Green
        }
    }
    catch {
        Write-ErrorLog -FunctionName "Show-MailboxesWithoutLicense" -ErrorMessage $_.Exception.Message
    }

    Pause
}



function Show-UserDistributionGroups {
    Ensure-ExchangeConnected
    try {
        $upn = Read-Host "`nEnter the user's UPN (e.g. user@example.com)"
        Write-Host "Distribution Groups for ${upn}:" -ForegroundColor Yellow

        $groups = Get-DistributionGroup -ResultSize Unlimited | Where-Object {
            (Get-DistributionGroupMember -Identity $_.Identity -ErrorAction SilentlyContinue) |
            Where-Object { $_.PrimarySmtpAddress -eq $upn }
        }

        if ($groups) {
            $groups | Select DisplayName, PrimarySmtpAddress | Format-Table -AutoSize
        }
        else {
            Write-Host "User is not a member of any distribution groups." -ForegroundColor Red
        }
    }
    catch {
        Write-ErrorLog -FunctionName "Show-UserDistributionGroups" -ErrorMessage $_.Exception.Message
    }

    Pause
}

function Show-AllDistributionGroups {
    Ensure-ExchangeConnected

    Write-Host "All Distribution Groups:" -ForegroundColor Cyan

    Get-DistributionGroup -ResultSize Unlimited |
    Select DisplayName, PrimarySmtpAddress, GroupType |
    Format-Table -AutoSize

    Pause
}

function Show-ExternalForwardingUsers {
    Ensure-ExchangeConnected

    Write-Host "Users with external forwarding enabled:" -ForegroundColor Yellow

    $externalDomains = @("ms-ci.co.il.fm")  # Replace with your organization's domains

    $mailboxes = Get-Mailbox -ResultSize Unlimited | Where-Object {
        $_.ForwardingSmtpAddress -or $_.ForwardingAddress
    }

    $results = foreach ($mbx in $mailboxes) {
        $fwd = $mbx.ForwardingSmtpAddress
        if (-not $fwd) {
            $fwd = (Get-Recipient $mbx.ForwardingAddress -ErrorAction SilentlyContinue).PrimarySmtpAddress
        }

        if ($fwd -and ($externalDomains -notcontains ($fwd -split "@")[1])) {
            [PSCustomObject]@{
                DisplayName       = $mbx.DisplayName
                UserPrincipalName = $mbx.UserPrincipalName
                ForwardingTo      = $fwd
            }
        }
    }

    if ($results) {
        $results | Format-Table -AutoSize

        $saveToCSV = Read-Host "Do you want to save the output to a CSV file? (Y/N)"
        if ($saveToCSV -eq 'Y' -or $saveToCSV -eq 'y') {
            $csvPath = Join-Path -Path $PSScriptRoot -ChildPath "results_export.csv"
            $results | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8
            Write-Host "✅ Output saved to: $csvPath" -ForegroundColor Green
        }

    }
    else {
        Write-Host "No external forwarding found." -ForegroundColor Green
    }

    Pause
}


function Show-AvailableLicenses {
    Ensure-MgGraphConnected
    try {
        # טען מודול נדרש אם לא טעון
        if (-not (Get-Module Microsoft.Graph.Identity.DirectoryManagement)) {
            Import-Module Microsoft.Graph.Identity.DirectoryManagement -ErrorAction Stop
        }

        # ודא התחברות
        if (-not (Get-MgContext)) {
            Connect-MgGraph -Scopes "Directory.Read.All" -ErrorAction Stop
        }

        Write-Host "`nChecking available licenses..." -ForegroundColor Cyan

        # משוך מידע על רישויים
        $skus = Get-MgSubscribedSku -ErrorAction Stop

        # עיבוד והצגה
        $skus | Select @{Name = "License"; Expression = { Convert-SkuToDisplayName -Sku $_.SkuPartNumber } },
        @{Name = "Total"; Expression = { $_.PrepaidUnits.Enabled } },
        @{Name = "Assigned"; Expression = { $_.ConsumedUnits } },
        @{Name = "Available"; Expression = { $_.PrepaidUnits.Enabled - $_.ConsumedUnits } } |
        Format-Table -AutoSize
    }
    catch {
        Write-Host "❌ Error occurred:" -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Yellow
    }

    Write-Host "`nDone. Press Enter to continue..." -ForegroundColor Green
    Read-Host
}





function Create-NewUserWithLicense {
    Ensure-MgGraphConnected

    # User input
    $displayName = Read-Host "Enter display name"

    do {
        $userPrincipalName = Read-Host "Enter user principal name (e.g. user@domain.com)"
        $isValidUpn = $userPrincipalName -match '^[^@]+@[^@]+\.[^@]+$'
        if (-not $isValidUpn) {
            Write-Host "Invalid UPN format. Please enter a valid email address." -ForegroundColor Red
        }
    } while (-not $isValidUpn)

    # Password validation loop
    do {
        $plainPassword = Read-Host "Enter temporary password (must be strong!)"
        $isValid = $false

        if ($plainPassword.Length -ge 8 -and
            $plainPassword -match '[A-Z]' -and
            $plainPassword -match '[a-z]' -and
            $plainPassword -match '[0-9]' -and
            $plainPassword -match '[!@#$%^&*()\-+=]') {
            $isValid = $true
        }
        else {
            Write-Host "Password does not meet complexity requirements!" -ForegroundColor Red
            Write-Host "It must contain:" -ForegroundColor Yellow
            Write-Host "- At least 8 characters" -ForegroundColor Yellow
            Write-Host "- Uppercase and lowercase letters" -ForegroundColor Yellow
            Write-Host "- At least one number" -ForegroundColor Yellow
            Write-Host "- At least one special character (!@# etc.)`n" -ForegroundColor Yellow
        }
    } while (-not $isValid)

    # Create user
    $userParams = @{
        AccountEnabled    = $true
        DisplayName       = $displayName
        MailNickname      = ($userPrincipalName -split "@")[0]
        UserPrincipalName = $userPrincipalName
        PasswordProfile   = @{
            ForceChangePasswordNextSignIn = $true
            Password                      = $plainPassword
        }
    }

    try {
        $newUser = New-MgUser @userParams
        Write-Host "`n✅ User created: $($newUser.UserPrincipalName)" -ForegroundColor Green
    }
    catch {
        Write-Host "`n❌ Failed to create user." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Yellow
        Pause
        return
    }

    # Set usage location
    $usageLocation = Read-Host "Enter usage location (2-letter country code, default: IL)"
    if ([string]::IsNullOrWhiteSpace($usageLocation)) {
        $usageLocation = "IL"
    }

    try {
        Update-MgUser -UserId $newUser.Id -UsageLocation $usageLocation
        Write-Host "Usage location set to: $usageLocation" -ForegroundColor Cyan
    }
    catch {
        Write-Host "❌ Failed to set usage location." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Yellow
        Pause
        return
    }

    # Ask for license assignment
    $assign = Read-Host "Would you like to assign a license now? (y/n)"
    if ($assign -eq "y") {
        try {
            $licenses = @(Get-MgSubscribedSku | Where-Object {
                    $_.ConsumedUnits -lt $_.PrepaidUnits.Enabled -and $_.PrepaidUnits.Enabled -gt 0
                })

            if (-not $licenses) {
                Write-Host "No available licenses found." -ForegroundColor Yellow
                Pause
                return
            }

            Write-Host "`nAvailable licenses:" -ForegroundColor Cyan
            for ($i = 0; $i -lt $licenses.Count; $i++) {
                $sku = $licenses[$i]
                $available = $sku.PrepaidUnits.Enabled - $sku.ConsumedUnits
                Write-Host "$($i + 1). $($sku.SkuPartNumber) (Available: $available)"
            }

            $choice = Read-Host "Select license number to assign"
            if ($choice -match '^\d+$' -and $choice -ge 1 -and $choice -le $licenses.Count) {
                $selectedLicense = $licenses[$choice - 1]
                Set-MgUserLicense -UserId $newUser.Id -AddLicenses @(@{ SkuId = $selectedLicense.SkuId }) -RemoveLicenses @()
                $skuName = Convert-SkuToDisplayName -Sku $selectedLicense.SkuPartNumber
                Write-Host "✅ License assigned: $skuName" -ForegroundColor Green
            }
            else {
                Write-Host "Invalid selection. No license assigned." -ForegroundColor Yellow
            }
        }
        catch {
            Write-Host "❌ Failed to assign license." -ForegroundColor Red
            Write-Host $_.Exception.Message -ForegroundColor Yellow
        }
    }
    else {
        Write-Host "User created without license." -ForegroundColor DarkYellow
    }

    Pause
}

function Remove-MailboxInteractive {
    Ensure-MgGraphConnected

    try {
        # שליפת כל המשתמשים
        $users = Get-MgUser -All -Property Id, DisplayName, UserPrincipalName | Sort-Object DisplayName

        if (-not $users -or $users.Count -eq 0) {
            Write-Host "No users found in Azure AD." -ForegroundColor Yellow
            return
        }

        # תפריט בחירה
        Write-Host "`nSelect a user to DELETE from Azure AD:`n" -ForegroundColor Red
        for ($i = 0; $i -lt $users.Count; $i++) {
            $index = $i + 1
            Write-Host "$index. $($users[$i].DisplayName) <$($users[$i].UserPrincipalName)>"
        }

        $inputRaw = Read-Host "`nEnter the number of the user to delete"
        if (-not [int]::TryParse($inputRaw, [ref]$null)) {
            throw "Invalid input: '$inputRaw' is not a number."
        }

        $selection = [int]$inputRaw
        if ($selection -lt 1 -or $selection -gt $users.Count) {
            throw "Invalid selection: $selection is out of range (1-$($users.Count))."
        }

        $selectedUser = $users[$selection - 1]
        Write-Host "`n⚠️ You selected to DELETE user: $($selectedUser.DisplayName) <$($selectedUser.UserPrincipalName)>" -ForegroundColor Yellow
        $confirm = Read-Host "Type YES to confirm full deletion from Azure AD"

        if ($confirm -eq "YES") {
            Remove-MgUser -UserId $selectedUser.Id -Confirm:$false -ErrorAction Stop
            Write-Host "✅ User deleted successfully from Azure AD." -ForegroundColor Green
        }
        else {
            Write-Host "❌ Deletion canceled." -ForegroundColor Cyan
        }
    }
    catch {
        Write-Host "❌ Error: $($_.Exception.Message)" -ForegroundColor Red
    }

    Pause
}

function Assign-LicenseToUserInteractive {
    Ensure-MgGraphConnected

    try {
        $users = Get-MgUser -All -Property Id, DisplayName, UserPrincipalName | Sort-Object DisplayName
        if (-not $users) {
            Write-Host "No users found." -ForegroundColor Yellow
            return
        }

        Write-Host "`nSelect a user to assign a license to:`n"
        for ($i = 0; $i -lt $users.Count; $i++) {
            Write-Host "$($i+1). $($users[$i].DisplayName) <$($users[$i].UserPrincipalName)>"
        }

        $userChoice = Read-Host "`nEnter the number of the user"
        $selectedUser = $users[$userChoice - 1]

        $availableLicenses = Get-MgSubscribedSku | Where-Object { $_.ConsumedUnits -lt $_.PrepaidUnits.Enabled }
        if (-not $availableLicenses) {
            Write-Host "No available licenses in the tenant." -ForegroundColor Yellow
            return
        }

        Write-Host "`nAvailable license types:`n"
        for ($i = 0; $i -lt $availableLicenses.Count; $i++) {
            $sku = $availableLicenses[$i]
            Write-Host "$($i+1). $($sku.SkuPartNumber) — Available: $($sku.PrepaidUnits.Enabled - $sku.ConsumedUnits)"
        }

        $licenseChoice = Read-Host "`nEnter the number of the license to assign"
        $selectedLicense = $availableLicenses[$licenseChoice - 1]

        Set-MgUserLicense -UserId $selectedUser.Id -AddLicenses @(@{ SkuId = $selectedLicense.SkuId }) -RemoveLicenses @()

        $skuName = Convert-SkuToDisplayName -Sku $selectedLicense.SkuPartNumber
        Write-Host "✅ License assigned: $skuName" -ForegroundColor Green
    }
    catch {
        Write-Host "❌ Error: $($_.Exception.Message)" -ForegroundColor Red
    }

    Pause
}


function Grant-MailboxAccessInteractive {
    Ensure-ExchangeConnected

    try {
        $users = Get-Mailbox -ResultSize Unlimited | Sort-Object DisplayName

        # שלב 1: בחירת המשתמש שיקבל את ההרשאה
        do {
            Write-Host "`nSelect the user who will RECEIVE the access:`n"
            for ($i = 0; $i -lt $users.Count; $i++) {
                Write-Host "$($i + 1). $($users[$i].DisplayName) <$($users[$i].UserPrincipalName)>"
            }
            $input1 = Read-Host "`nEnter number of the user to receive access"
        } while (-not [int]::TryParse($input1, [ref]$null) -or [int]$input1 -lt 1 -or [int]$input1 -gt $users.Count)

        $grantee = $users[[int]$input1 - 1]

        # שלב 2: בחירת התיבה עליה תינתן ההרשאה
        do {
            Write-Host "`nSelect the mailbox to GRANT access TO:`n"
            for ($i = 0; $i -lt $users.Count; $i++) {
                Write-Host "$($i + 1). $($users[$i].DisplayName) <$($users[$i].UserPrincipalName)>"
            }
            $input2 = Read-Host "`nEnter number of the mailbox to share"
        } while (-not [int]::TryParse($input2, [ref]$null) -or [int]$input2 -lt 1 -or [int]$input2 -gt $users.Count)

        $mailbox = $users[[int]$input2 - 1]

        # שלב 3: סוג ההרשאה
        do {
            Write-Host "`nChoose permission type:"
            Write-Host "1. Full Access to mailbox"
            Write-Host "2. Calendar permissions only"
            $permType = Read-Host "Enter your choice (1 or 2)"
        } while ($permType -ne "1" -and $permType -ne "2")

        if ($permType -eq "1") {
            Add-MailboxPermission -Identity $mailbox.UserPrincipalName -User $grantee.UserPrincipalName -AccessRights FullAccess -InheritanceType All -ErrorAction Stop
            Write-Host "✅ Full Access granted." -ForegroundColor Green
        }
        else {
            # שלב 4: סוג הרשאה ביומן
            do {
                Write-Host "`nSelect calendar permission level:"
                Write-Host "1. Owner (full control)"
                Write-Host "2. Editor (read/write)"
                Write-Host "3. Reviewer (read-only)"
                Write-Host "4. AvailabilityOnly (free/busy)"
                $calPerm = Read-Host "Enter your choice (1–4)"
            } while ($calPerm -notin "1", "2", "3", "4")

            $accessRight = switch ($calPerm) {
                "1" { "Owner" }
                "2" { "Editor" }
                "3" { "Reviewer" }
                "4" { "AvailabilityOnly" }
            }

            Add-MailboxFolderPermission -Identity "$($mailbox.UserPrincipalName):\Calendar" -User $grantee.UserPrincipalName -AccessRights $accessRight -ErrorAction Stop
            Write-Host "✅ Calendar permission '$accessRight' granted." -ForegroundColor Green
        }
    }
    catch {
        Write-Host "❌ Error: $($_.Exception.Message)" -ForegroundColor Red
    }

    Pause
}

function Show-ArchiveEnabledMailboxes {
    Ensure-ExchangeConnected

    Write-Host "`nChecking mailboxes with Online Archive enabled..." -ForegroundColor Cyan

    try {
        $mailboxes = Get-Mailbox -ResultSize Unlimited | Where-Object { $_.ArchiveStatus -eq "Active" }

        if (-not $mailboxes) {
            Write-Host "No users found with archive enabled." -ForegroundColor Yellow
        }
        else {
            $results = foreach ($mbx in $mailboxes) {
                $stats = Get-MailboxStatistics -Identity $mbx.UserPrincipalName

                [PSCustomObject]@{
                    DisplayName       = $mbx.DisplayName
                    UserPrincipalName = $mbx.UserPrincipalName
                    ArchiveStatus     = $mbx.ArchiveStatus
                    RetentionPolicy   = $mbx.RetentionPolicy
                    ArchiveSizeGB     = if ($stats.TotalArchiveSize -and $stats.TotalArchiveSize.Value) {
                        [math]::Round(($stats.TotalArchiveSize.Value.ToBytes() / 1GB), 2)
                    }
                    else {
                        "N/A"
                    }
                }
            }

            $results | Sort-Object ArchiveSizeGB -Descending | Format-Table -AutoSize
        }
    }
    catch {
        Write-Host "❌ Error: $($_.Exception.Message)" -ForegroundColor Red
    }

    Read-Host "`nPress Enter to return to the main menu"
}




function New-InteractiveRetentionPolicy {
    Ensure-ExchangeConnected

    # קבלת שם למדיניות החדשה
    $policyName = Read-Host "Enter a name for the new retention policy"

    # כמה תגיות ליצור
    $tagCount = Read-Host "How many archive tags would you like to create?"
    if (-not ($tagCount -match '^\d+$') -or [int]$tagCount -lt 1) {
        Write-Host "Invalid number entered. Aborting..." -ForegroundColor Red
        return
    }

    $tags = @()

    for ($i = 1; $i -le $tagCount; $i++) {
        Write-Host "`n--- Tag #$i ---" -ForegroundColor Cyan
        $tagName = Read-Host "Enter tag name"
        $tagComment = Read-Host "Enter a description for the tag"
        $days = Read-Host "After how many days should emails be archived?"
        if (-not ($days -match '^\d+$')) {
            Write-Host "Invalid number of days. Skipping tag." -ForegroundColor Yellow
            continue
        }

        try {
            $tag = New-RetentionPolicyTag -Name $tagName `
                -Type All `
                -RetentionAction MoveToArchive `
                -RetentionEnabled $true `
                -AgeLimitForRetention $days `
                -Comment $tagComment `
                -ErrorAction Stop
            $tags += $tag
            Write-Host "✔️ Tag '$tagName' created successfully." -ForegroundColor Green
        }
        catch {
            Write-Host "❌ Failed to create tag '$tagName': $($_.Exception.Message)" -ForegroundColor Red
        }
    }

    if ($tags.Count -eq 0) {
        Write-Host "No tags were created. Retention policy will not be created." -ForegroundColor Yellow
        return
    }

    try {
        $tagNames = $tags | Select-Object -ExpandProperty Name
        New-RetentionPolicy -Name $policyName -RetentionPolicyTagLinks $tagNames
        Write-Host "`n✅ Retention policy '$policyName' created with $($tags.Count) tags." -ForegroundColor Green
    }
    catch {
        Write-Host "❌ Failed to create retention policy: $($_.Exception.Message)" -ForegroundColor Red
    }

    Pause
}

function Show-RetentionPolicies {
    try {
        Ensure-ExchangeConnected

        Write-Host "`nFetching Retention Policies..." -ForegroundColor Cyan

        $policies = Get-RetentionPolicy

        if (-not $policies) {
            Write-Host "No retention policies found." -ForegroundColor Yellow
            return
        }

        $policies | Select-Object Name, RetentionPolicyTagLinks, IsDefault |
        Sort-Object Name |
        Format-Table -AutoSize

        Write-Host "`nDone." -ForegroundColor Green
    }
    catch {
        Write-Host "Error occurred while retrieving retention policies:" -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Yellow
    }

    Write-Host "`nPress Enter to continue..." -ForegroundColor Gray
    Read-Host
}

function Assign-RetentionPolicyToUser {
    try {
        Ensure-ExchangeConnected

        Write-Host "`nFetching users..." -ForegroundColor Cyan
        $users = Get-Mailbox -ResultSize Unlimited | Sort-Object DisplayName

        if (-not $users) {
            Write-Host "No mailboxes found." -ForegroundColor Yellow
            return
        }

        $i = 1
        $users | ForEach-Object {
            Write-Host "$i. $($_.DisplayName) <$($_.UserPrincipalName)>"
            $i++
        }

        $userSelection = Read-Host "Enter the number of the user"
        if ($userSelection -notmatch '^\d+$' -or $userSelection -lt 1 -or $userSelection -gt $users.Count) {
            Write-Host "Invalid selection." -ForegroundColor Red
            return
        }

        $selectedUser = $users[$userSelection - 1]

        Write-Host "`nFetching Retention Policies..." -ForegroundColor Cyan
        $policies = Get-RetentionPolicy | Sort-Object Name

        if (-not $policies) {
            Write-Host "No retention policies found." -ForegroundColor Yellow
            return
        }

        $j = 1
        $policies | ForEach-Object {
            Write-Host "$j. $($_.Name)"
            $j++
        }

        $policySelection = Read-Host "Enter the number of the Retention Policy to assign"
        if ($policySelection -notmatch '^\d+$' -or $policySelection -lt 1 -or $policySelection -gt $policies.Count) {
            Write-Host "Invalid selection." -ForegroundColor Red
            return
        }

        $selectedPolicy = $policies[$policySelection - 1]

        Write-Host "`nAssigning policy '$($selectedPolicy.Name)' to '$($selectedUser.UserPrincipalName)'..." -ForegroundColor Cyan
        Set-Mailbox -Identity $selectedUser.UserPrincipalName -RetentionPolicy $selectedPolicy.Name

        Write-Host "Retention policy assigned successfully." -ForegroundColor Green
    }
    catch {
        Write-Host "Error occurred:" -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Yellow
    }

    Write-Host "`nPress Enter to continue..." -ForegroundColor Gray
    Read-Host
}

function Find-InactiveLicensedUsers {
    Ensure-MgGraphConnected
    param (
        [int]$DaysInactive = 90
    )

    try {
        Ensure-ExchangeConnected
        Ensure-MgGraphConnected -Scopes "User.Read.All", "Directory.Read.All"

        Write-Host "`nFetching all licensed users..." -ForegroundColor Cyan

        $thresholdDate = (Get-Date).AddDays(-$DaysInactive)
        $licensedUsers = Get-MgUser -All -Property "Id,DisplayName,UserPrincipalName,AssignedLicenses" |
        Where-Object { $_.AssignedLicenses.Count -gt 0 }

        $results = @()

        foreach ($user in $licensedUsers) {
            try {
                $mailbox = Get-Mailbox -Identity $user.UserPrincipalName -ErrorAction Stop

                if ($mailbox.RecipientTypeDetails -eq "SharedMailbox") {
                    continue
                }

                $stats = Get-MailboxStatistics -Identity $user.UserPrincipalName -ErrorAction Stop

                if ($stats.LastLogonTime -lt $thresholdDate) {
                    $results += [PSCustomObject]@{
                        DisplayName       = $user.DisplayName
                        UserPrincipalName = $user.UserPrincipalName
                        LastLogonTime     = $stats.LastLogonTime
                        LicenseCount      = $user.AssignedLicenses.Count
                        RecipientType     = $mailbox.RecipientTypeDetails
                    }
                }

            }
            catch {
                Write-Warning "Skipped $($user.UserPrincipalName): $($_.Exception.Message)"
            }
        }

        if ($results.Count -eq 0) {
            Write-Host "No inactive licensed users found." -ForegroundColor Yellow
        }
        else {
            $results | Sort-Object LastLogonTime | Format-Table -AutoSize | Out-Host
        }
    }
    catch {
        Write-Host "Error: $_" -ForegroundColor Red
    }

    Write-Host "`nDone. Press Enter to continue..." -ForegroundColor Green
    Read-Host
}




function Incoming-Mail-Traffic-Tracking {
    try {
        # קלט מהמשתמש לגבי כתובת התיבה לבדיקה
        $UserPrincipalName = Read-Host "Enter the user principal name to check"

        # שאלת המשתמש כמה ימים אחורה לבדוק (עם מגבלה של 10)
        $DaysBack = Read-Host "Enter number of days to check (max 10)"
        if (-not [int]::TryParse($DaysBack, [ref]$DaysBack) -or $DaysBack -lt 1 -or $DaysBack -gt 10) {
            Write-Host "Invalid input! Using default: 10 days." -ForegroundColor Yellow
            $DaysBack = 10
        }

        # שאלת המשתמש מה לבדוק
        Write-Host "`n📌 Please choose what to check:" -ForegroundColor Cyan
        Write-Host "1️ All emails " -ForegroundColor Yellow
        Write-Host "2️ Only problematic emails (Failed, Blocked, Quarantined, Pending, Deferred)" -ForegroundColor Red
        $FilterOption = Read-Host "Enter your choice (1 or 2)"

        Write-Host "`n📬 Checking mailbox activity for: $UserPrincipalName (Last $DaysBack days)" -ForegroundColor Cyan

        # שליפת הודעות מהמייל
        $messageTrace = Get-MessageTrace -RecipientAddress $UserPrincipalName -StartDate (Get-Date).AddDays(-$DaysBack) -EndDate (Get-Date)

        # סינון לפי בחירת המשתמש
        if ($FilterOption -eq "1") {
            $filteredMessages = $messageTrace
            Write-Host "`n📩 Showing all emails:" -ForegroundColor Yellow
        }
        elseif ($FilterOption -eq "2") {
            $filteredMessages = $messageTrace | Where-Object { $_.Status -in @("Failed", "Deferred", "Pending", "Blocked", "Quarantined") }
            Write-Host "`n⚠ Showing only problematic email statuses:" -ForegroundColor Red
        }

        # הצגת הנתונים
        if ($filteredMessages) {
            $filteredMessages | Format-Table Received, SenderAddress, Subject, Status

            $saveToCSV = Read-Host "Do you want to save the output to a CSV file? (Y/N)"
            if ($saveToCSV -eq 'Y' -or $saveToCSV -eq 'y') {
                $csvPath = Join-Path -Path $PSScriptRoot -ChildPath "filteredMessages_export.csv"
                $filteredMessages | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8
                Write-Host "✅ Output saved to: $csvPath" -ForegroundColor Green
            }

        }
        else {
            Write-Host "✅ No matching emails found." -ForegroundColor Green
        }

        # בדיקת כניסות חשודות (Unified Audit Log)
        Write-Host "`n🔍 Checking for suspicious logins..." -ForegroundColor Yellow
        $loginAttempts = Search-UnifiedAuditLog -Operations UserLoggedIn -StartDate (Get-Date).AddDays(-$DaysBack) -EndDate (Get-Date) -UserIds $UserPrincipalName

        if ($loginAttempts) {
            Write-Host "⚠️ Suspicious login activity detected:" -ForegroundColor Red
            $loginAttempts | Format-Table CreationDate, UserId, IPAddress, Operation

            $saveToCSV = Read-Host "Do you want to save the output to a CSV file? (Y/N)"
            if ($saveToCSV -eq 'Y' -or $saveToCSV -eq 'y') {
                $csvPath = Join-Path -Path $PSScriptRoot -ChildPath "loginAttempts_export.csv"
                $loginAttempts | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8
                Write-Host "✅ Output saved to: $csvPath" -ForegroundColor Green
            }

        }
        else {
            Write-Host "✅ No suspicious logins found." -ForegroundColor Green
        }

    }
    catch {
        $errorDetails = "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Error:`n$($_.Exception.Message)`nStackTrace:`n$($_.Exception.StackTrace)`nInnerException:`n$($_.Exception.InnerException)"
        Add-Content -Path "$PSScriptRoot\detailed_error_log.txt" -Value $errorDetails
        Write-Host "❌ Detailed error saved to detailed_error_log.txt" -ForegroundColor Yellow
    }

    Pause
}

function Get-Mailbox-FullReport {
    Ensure-MgGraphConnected
    $UserPrincipalName = Read-Host "Enter the UserPrincipalName (e.g., user@domain.com)"
	
    try {
       
        Write-Host "Collecting report for mailbox:" $UserPrincipalName -ForegroundColor Cyan

        # תיבת דואר
        $mailbox = Get-Mailbox -Identity $UserPrincipalName -ErrorAction Stop
        $stats = Get-MailboxStatistics -Identity $UserPrincipalName
        $displayName = $mailbox.DisplayName
        $type = $mailbox.RecipientTypeDetails
        $archiveStatus = if ($mailbox.ArchiveStatus -eq "Active") { "Enabled" } else { "Disabled" }
        $archiveDB = if ($mailbox.ArchiveDatabase) { $mailbox.ArchiveDatabase } else { "N/A" }
        $retentionPolicy = if ($mailbox.RetentionPolicy) { $mailbox.RetentionPolicy } else { "None" }
        $mailboxSize = $stats.TotalItemSize.ToString()

        # שימוש ב־Microsoft Graph במקום MSOnline/AzureAD
        $sku = "N/A"
        try {
            $licenseDetails = Get-MgUserLicenseDetail -UserId $UserPrincipalName -ErrorAction Stop
            if ($licenseDetails) {
                $skuList = @()
                $skuList = $licenseDetails | ForEach-Object { Convert-SkuToDisplayName -Sku $_.SkuPartNumber }
                $sku = $skuList -join ", "

            }
        }
        catch {
            $sku = "Unable to retrieve licenses"
        }


        # הפניות מייל
        $forwarding = if ($mailbox.ForwardingSMTPAddress) {
            "$($mailbox.ForwardingSMTPAddress) (SMTP)"
        }
        elseif ($mailbox.ForwardingAddress) {
            "$($mailbox.ForwardingAddress)"
        }
        else {
            "None"
        }

        # קבוצות
        $groups = Get-DistributionGroup | Where-Object {
            (Get-DistributionGroupMember $_.Identity -ErrorAction SilentlyContinue | Where-Object {
                $_.PrimarySmtpAddress -eq $UserPrincipalName
            })
        } | Select-Object -ExpandProperty DisplayName
        $groupList = if ($groups) { $groups -join ", " } else { "None" }

        # הרשאות לתיבות אחרות
        $permissions = Get-MailboxPermission -Identity $UserPrincipalName -ErrorAction SilentlyContinue |
        Where-Object { $_.AccessRights -ne "None" -and $_.IsInherited -eq $false }
        $permList = if ($permissions) {
            $permissions | Select-Object Identity, AccessRights | Format-Table -AutoSize | Out-String
        }
        else {
            "No explicit mailbox permissions"
        }

        # הרשאות ליומן
        $calendarPermissions = Get-MailboxFolderPermission "${UserPrincipalName}:\Calendar" -ErrorAction SilentlyContinue |
        Where-Object { $_.User -ne "Default" -and $_.User -ne "Anonymous" }
        $calendarList = if ($calendarPermissions) {
            $calendarPermissions | Select-Object User, AccessRights | Format-Table -AutoSize | Out-String
        }
        else {
            "No calendar sharing found"
        }

        # Inbox Rules
        $rules = Get-InboxRule -Mailbox $UserPrincipalName -ErrorAction SilentlyContinue
        $ruleList = if ($rules) {
            $rules | Select-Object Name, Enabled, Priority, From, MoveToFolder | Format-Table -AutoSize | Out-String
        }
        else {
            "No Inbox rules found"
        }

        # הצגה
        Write-Host "General Info" -ForegroundColor Green
        Write-Host "Display Name     : $displayName"
        Write-Host "Mailbox Type     : $type"
        Write-Host "License (SKU)    : $sku"
        Write-Host "Mailbox Size     : $mailboxSize"
        Write-Host "Retention Policy : $retentionPolicy"
        Write-Host "Archive Status   : $archiveStatus"
        Write-Host "Archive Database : $archiveDB"
        Write-Host "Forwarding       : $forwarding"
        Write-Host ""
        Write-Host "Group Memberships" -ForegroundColor Green
        Write-Host $groupList
        Write-Host ""
        Write-Host "Mailbox Permissions (User has access to others)" -ForegroundColor Green
        Write-Output $permList
        Write-Host ""
        Write-Host "Calendar Permissions (Others have access to this user's calendar)" -ForegroundColor Green
        Write-Output $calendarList
        Write-Host ""
        Write-Host "Inbox Rules" -ForegroundColor Green
        Write-Output $ruleList

    }
    catch {
        Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    }

    Pause
}


function Check-M365UserStatus {
    try {
        $UserPrincipalName = Read-Host "Enter the UserPrincipalName (e.g., user@domain.com)"

        # ודא חיבור ל־Exchange Online
        if (-not (Get-ConnectionInformation)) {
            Connect-ExchangeOnline -ShowBanner:$false
        }

        # ניסיון לשלוף את המשתמש
        $user = Get-User -Identity $UserPrincipalName -ErrorAction Stop

        # הצגת המידע
        Write-Host "`n✅ User found: $($user.DisplayName)" -ForegroundColor Green
        Write-Host ("Blocked Sign-in : " + ($(if ($user.BlockCredential) { "🚫 Yes" } else { "✅ No" })))
        Write-Host ("Account Disabled: " + ($(if ($user.AccountDisabled) { "⚠️  Yes" } else { "✅ No" })))
    
    }
    catch {
        $scriptDirectory = $PSScriptRoot
        $logFile = Join-Path -Path $scriptDirectory -ChildPath "Error.log"
        $errorMsg = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - Error for user '$UserPrincipalName': $($_.Exception.Message)"
        Add-Content -Path $logFile -Value $errorMsg

        Write-Host "`n❌ An error occurred: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "Details were saved to: $logFile" -ForegroundColor DarkGray
    }

    # עצירה לפני החזרה לתפריט
    Read-Host -Prompt "`nPress Enter to return to the menu"
}


function Reset-M365UserPassword {
    Ensure-MgGraphConnected

    try {
        # בדיקה האם המודול מותקן
        if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Users)) {
            Write-Host "`n❌ Required module 'Microsoft.Graph.Users' is not installed." -ForegroundColor Red
            Write-Host "You can install it using: Install-Module Microsoft.Graph.Users" -ForegroundColor Yellow
            return
        }

        # טען את המודול אם עדיין לא טענו אותו
        if (-not (Get-Module -Name Microsoft.Graph.Users)) {
            Import-Module Microsoft.Graph.Users
        }

        # בדוק חיבור לגרף
        if (-not (Get-MgContext)) {
            Connect-MgGraph -Scopes "User.ReadWrite.All"
        }

        # קלט מייל
        $UserPrincipalName = Read-Host "Enter the UserPrincipalName (e.g., user@domain.com)"

        # שליפת המשתמש
        $user = Get-MgUser -UserId $UserPrincipalName -ErrorAction Stop

        # סיסמה מותאמת או אוטומטית
        $choice = Read-Host "Do you want to set a custom password? (Y/N)"
        if ($choice -eq 'Y' -or $choice -eq 'y') {
            $newPassword = Read-Host "Enter the new password"
        }
        else {
            $newPassword = -join ((48..57) + (65..90) + (97..122) + (33, 35, 64, 36, 37) | Get-Random -Count 14 | ForEach-Object { [char]$_ })
        }

        # אילוץ החלפת סיסמה
        $forceChangeInput = Read-Host "Force user to change password at next sign-in? (Y/N)"
        $forceChange = $false
        if ($forceChangeInput -eq 'Y' -or $forceChangeInput -eq 'y') {
            $forceChange = $true
        }

        # איפוס הסיסמה
        Update-MgUser -UserId $UserPrincipalName -PasswordProfile @{
            Password                      = $newPassword
            ForceChangePasswordNextSignIn = $forceChange
        }

        # פלט למשתמש
        Write-Host "`n✅ Password reset successful for: $UserPrincipalName" -ForegroundColor Green
        Write-Host "🔐 New Password: $newPassword" -ForegroundColor Yellow
        if ($forceChange) {
            Write-Host "🔁 User will be required to change password at next sign-in." -ForegroundColor Cyan
        }
        else {
            Write-Host "ℹ️  User will NOT be required to change password at next sign-in." -ForegroundColor DarkCyan
        }

    }
    catch {
        $scriptDirectory = $PSScriptRoot
        $logFile = Join-Path -Path $scriptDirectory -ChildPath "Error.log"
        $errorMsg = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - Password reset failed for '$UserPrincipalName': $($_.Exception.Message)"
        Add-Content -Path $logFile -Value $errorMsg

        if ($_.Exception.Message -like "*403*" -and $newPassword) {
            Write-Host "`n⚠️ Warning: Microsoft Graph returned '403 Forbidden', but the password might have been changed." -ForegroundColor Yellow
            Write-Host "🔐 New Password: $newPassword" -ForegroundColor Yellow
            Write-Host "✅ Please verify manually in the portal or ask the user to test sign-in."
        }
        else {
            Write-Host "`n❌ Failed to reset password: $($_.Exception.Message)" -ForegroundColor Red
            Write-Host "Details were saved to: $logFile" -ForegroundColor DarkGray
        }
    }

    Read-Host -Prompt "`nPress Enter to return to the menu"
}


function Get-M365SigninFailures {
    Ensure-MgGraphConnected  # אם כבר כתבת אותה

    $UserPrincipalName = Read-Host "Enter the UserPrincipalName (e.g., user@domain.com)"
    
    try {
        $user = Get-MgUser -UserId $UserPrincipalName -ErrorAction Stop
        $userId = $user.Id

        Write-Host "`n🔍 Fetching recent failed sign-in attempts for $UserPrincipalName ..." -ForegroundColor Cyan

        $logins = Get-MgAuditLogSignIn -Filter "userId eq '$userId' and status/errorCode ne 0" -Top 20

        if ($logins.Count -eq 0) {
            Write-Host "✅ No failed sign-in attempts found for $UserPrincipalName" -ForegroundColor Green
            return
        }

        $output = @()
        foreach ($log in $logins) {
            $output += [PSCustomObject]@{
                Time      = $log.CreatedDateTime
                ErrorCode = $log.Status.ErrorCode
                Reason    = $log.Status.FailureReason
                Client    = $log.AppDisplayName
                IP        = $log.IpAddress
            }
        }

        $output | Format-Table -AutoSize

        $save = Read-Host "`nDo you want to save the results to TXT? (Y/N)"
        if ($save -eq "Y" -or $save -eq "y") {
            $path = Join-Path -Path $PSScriptRoot -ChildPath "SigninLog_$($UserPrincipalName.Split('@')[0]).txt"
            $output | Out-File -FilePath $path -Encoding UTF8
            Write-Host "`n✅ Saved to $path" -ForegroundColor Yellow
        }

    }
    catch {
        Write-Host "❌ Error: $($_.Exception.Message)" -ForegroundColor Red
    }

    Read-Host "`nPress Enter to return to the menu"
}



function Show-MainMenu {
    Clear-Host
    Write-Host "=== Exchange Online Management Menu ===" -ForegroundColor Cyan
    Write-Host "1. View Data"
    Write-Host "2. Perform Actions"
    Write-Host "3. Exit"
    Write-Host ""
}

function Show-ViewDataMenu {
    Clear-Host
    Write-Host "=== View Data ===" -ForegroundColor Cyan
    Write-Host "1. Show all mailboxes"
    Write-Host "2. Show mailbox size"
    Write-Host "3. Show forwarding addresses"
    Write-Host "4. Mailboxes with archive"
    Write-Host "5. Full Access permissions"
    Write-Host "6. SendAs permissions"
    Write-Host "7. Inactive mailboxes (90+ Days)"
    Write-Host "8. Shared mailboxes"
    Write-Host "9. Export mailboxes to CSV"
    Write-Host "10. Show licenses per mailbox"
    Write-Host "11. Show mailboxes over quota"
    Write-Host "12. Show mailboxes without a license"
    Write-Host "13. Show distribution groups for a user"
    Write-Host "14. Show all distribution groups"
    Write-Host "15. Show users with external forwarding"
    Write-Host "16. Show available license types"
    Write-Host "17. Show Archive Enabled Mailboxes"
    Write-Host "18. Show-RetentionPolicies"
    Write-Host "19. Inactive mailboxes with license"
    Write-Host "20. Incoming Mail Traffic (Message Trace Report)"
    Write-Host "21. Get Mailbox FullReport"
    Write-Host "22. Check Block Mailbox"
    Write-Host "23. Get login Failures"
    Write-Host "24. Back to Main Menu"
    Write-Host ""
}

function Show-PerformActionsMenu {
    Clear-Host
    Write-Host "=== Perform Actions ===" -ForegroundColor Cyan
    Write-Host "1. Create new user with license"
    Write-Host "2. Remove Mailbox"
    Write-Host "3. Assign License To User"
    Write-Host "4. Grant Mailbox Or CalanderAccess"
    Write-Host "5. Create Archive Retention Policy"
    Write-Host "6. Assign Retention Policy To User"
    Write-Host "7. Reset MailBox Password"
    Write-Host "8. Back to Main Menu"
    Write-Host ""
}

# Import all existing display functions
# These functions must be defined below or loaded from another script
# Example: function Show-Mailboxes { ... }


# MAIN LOOP
while ($true) {

    Show-MainMenu
    $mainChoice = Read-Host "Select an option (1-3)"

    switch ($mainChoice) {

        "1" {
            $exitViewMenu = $false
            do {
                Show-ViewDataMenu
                $viewChoice = Read-Host "Select an option (1-24)"

                switch ($viewChoice) {
                    "1" { Show-Mailboxes }
                    "2" { Show-MailboxSize }
                    "3" { Show-Forwarding }
                    "4" { Show-ArchiveEnabled }
                    "5" { Show-FullAccessPermissions }
                    "6" { Show-SendAsPermissions }
                    "7" { Show-InactiveMailboxes }
                    "8" { Show-SharedMailboxes }
                    "9" { Export-MailboxesToCSV }
                    "10" { Show-MailboxLicenses }
                    "11" { Show-MailboxesOverQuota }
                    "12" { Show-MailboxesWithoutLicense }
                    "13" { Show-UserDistributionGroups }
                    "14" { Show-AllDistributionGroups }
                    "15" { Show-ExternalForwardingUsers }
                    "16" { Show-AvailableLicenses }
                    "17" { Show-ArchiveEnabledMailboxes }
                    "18" { Show-RetentionPolicies }
                    "19" { Find-InactiveLicensedUsers }
                    "20" { Incoming-Mail-Traffic-Tracking }
                    "21" { Get-Mailbox-FullReport }
                    "22" { Check-M365UserStatus }
                    "23" { Get-M365SigninFailures }
                    "24" { $exitViewMenu = $true }
                    default {
                        Write-Host "Invalid selection. Try again." -ForegroundColor Red
                        Start-Sleep -Seconds 2
                    }
                }
            } while (-not $exitViewMenu)
        }



        "2" {
            $exitActionMenu = $false
            do {
                Show-PerformActionsMenu
                $actionChoice = Read-Host "Select an option (1-7)"

                switch ($actionChoice) {
                    "1" { Create-NewUserWithLicense }
                    "2" { Remove-MailboxInteractive }
                    "3" { Assign-LicenseToUserInteractive }
                    "4" { Grant-MailboxAccessInteractive }
                    "5" { New-InteractiveRetentionPolicy }
                    "6" { Assign-RetentionPolicyToUser }
                    "7" { Reset-M365UserPassword } 
                    "8" { $exitActionMenu = $true }
                    default {
                        Write-Host "Invalid selection. Try again." -ForegroundColor Red
                        Start-Sleep -Seconds 2
                    }
                }
            } while (-not $exitActionMenu)
        }

        "3" {
            Write-Host "`n🔌 Disconnecting all active sessions..." -ForegroundColor Yellow
            try {
                if (Get-ConnectionInformation) {
                    Disconnect-ExchangeOnline -Confirm:$false
                    Write-Host "✅ Disconnected from Exchange Online." -ForegroundColor Green
                }
                else {
                    Write-Host "ℹ️  No active Exchange Online connection found." -ForegroundColor DarkYellow
                }

                try {
                    if (Get-MgContext) {
                        Disconnect-MgGraph
                        Write-Host "✅ Disconnected from Microsoft Graph." -ForegroundColor Green
                    }
                    else {
                        Write-Host "ℹ️  No Microsoft Graph session found." -ForegroundColor DarkYellow
                    }
                }
                catch {
                    Write-Host "ℹ️  Microsoft Graph disconnect not required or already closed." -ForegroundColor DarkGray
                }

            }
            catch {
                Write-Host "`n❌ Error during disconnect: $($_.Exception.Message)" -ForegroundColor Red
            }

            Read-Host "`nPress Enter to return to the main menu"
        }


        default {
            Write-Host "Invalid selection. Try again." -ForegroundColor Red
            Start-Sleep -Seconds 2
        }
    }
}




