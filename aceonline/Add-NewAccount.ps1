# ==============================================================================
# =================================== PARAMS ===================================
# ==============================================================================
[CmdletBinding()]
param (
    [string]$SQLServer,
    [string]$SQLUsername,
    [string]$SQLPassword,
    [string]$AccountName,
    [string]$AccountPassword,
    [string]$AccountType,

    [switch]$NonInteractive
)

if ($NonInteractive) {
    foreach ($name in "Server", "Username", "Password", "AccountName", "AccountPassword", "AccountType") {
        if (-not $PSBoundParameters.ContainsKey($name)) {
            throw "Non-interactive execution missing $name parameter."
        }
    }
}

# ==============================================================================
# =================================== IMPORTS ==================================
# ==============================================================================
$ModulesPath = Join-Path $PSScriptRoot "modules"
Import-Module (Join-Path $ModulesPath "CommonUtils.psm1") -Force
Import-Module (Join-Path $ModulesPath "SqlExpressUtils.psm1") -Force

# ==============================================================================
# =========================== PARAM/INPUT VALIDATION ===========================
# ==============================================================================
Write-Host ""

# $SQLServer
if (-not $NonInteractive) {
    $SQLServer = (Read-Host "Enter SQL server address")
}
$SQLServer = Assert-TrimStrIsValidServerAddress $SQLServer -Name "SQL server"

# $SQLUsername
if (-not $NonInteractive) {
    $SQLUsername = (Read-Host "Enter SQL username")
}
$SQLUsername = Assert-TrimStrIsNotNullOrEmpty $SQLUsername -Name "SQL username"

# $SQLPassword
if (-not $NonInteractive) {
    $SQLPassword = (Read-SecureStringAsString "Enter SQL password")
}
$SQLPassword = Assert-TrimStrIsNotNullOrEmpty $SQLPassword -Name "SQL password"

# $AccountName
if (-not $NonInteractive) {
    $AccountName = (Read-Host "Enter new account name")
}
$AccountName = Assert-TrimStrIsNotNullOrEmpty $AccountName -Name "Account name"

# $AccountPassword
if (-not $NonInteractive) {
    $AccountPassword = (Read-SecureStringAsString "Enter new account password")
    $AccountPassword2 = (Read-SecureStringAsString "Re-enter new account password")
    if ($AccountPassword -cne $AccountPassword2) {
        throw "Re-entered password does not match!"
    }
}
$AccountPassword = Assert-TrimStrIsNotNullOrEmpty $AccountPassword -Name "Account password"

# $AccountType
if (-not $NonInteractive) {
    $AccountType = (Read-Host "Enter new account type [0 -> Normal, 128 -> GM, 256 -> Helper]")
}
$AccountType = Assert-TrimStrIsValidAccountType $AccountType -Name "Account type"

# ==============================================================================
# =================================== SCRIPT ===================================
# ==============================================================================
$accountEntry = Get-TableColumnValue `
    -Server $SQLServer `
    -Username $SQLUsername `
    -Password $SQLPassword `
    -Table "atum2_db_account.dbo.td_Account" `
    -Column "AccountName" `
    -WhereCondition "AccountName = '$AccountName'"
if ($null -ne $accountEntry) {
    throw "Account name [$AccountName] already in use!"
}

$columnNames = @(
    "AccountName",
    "Password",
    "AccountType",
    "Sex",
    "BirthYear",
    "RegisteredDate",
    "LastLoginDate",
    "IsBlocked",
    "ChattingBlocked",
    "MGameEventType",
    "ConnectingServerGroupID",
    "GameContinueTimeInSecondOfToday",
    "LastGameEndDate",
    "JuminNumber",
    "SecondaryPassword",
    "userfrom",
    "Password_new",
    "email",
    "CashPoint",
    "WarPoint",
    "CumulativeWarPoint",
    "VoteCount",
    "WebPoint",
    "ActivationCode",
    "Active" ,
    "LastGetDCoinDate",
    "GameContinueTimeInSecondofEvent"
)

$columnValues = @(
    "'$AccountName'",
    "'$AccountPassword'",
    "$AccountType",
    "NULL",
    "NULL",
    "getdate()",
    "getdate()",
    "0",
    "0",
    "0",
    "0",
    "0",
    "getdate()",
    "NULL",
    "NULL",
    "0",
    "NULL",
    "NULL",
    "1",
    "1",
    "1",
    "0",
    "0",
    "NULL",
    "1",
    "NULL",
    "NULL"
)

Add-RowIntoTable `
    -Server $SQLServer `
    -Username $SQLUsername `
    -Password $SQLPassword `
    -Table "atum2_db_account.dbo.td_Account" `
    -ColumnNames $columnNames `
    -ColumnValues $columnValues

$exitMsg = @"
Account created!
Account Name: $AccountName
Account Type: $AccountType
Script successful!
"@
Write-Host $exitMsg -ForegroundColor Green
Exit 0
