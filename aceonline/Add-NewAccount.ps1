# ==============================================================================
# =================================== PARAMS ===================================
# ==============================================================================
[CmdletBinding()]
param (
    [string]$MssqlServerAddress,
    [string]$MssqlUsername,
    [string]$MssqlPassword,
    [string]$AccountName,
    [string]$AccountPassword,
    [string]$AccountType,

    [switch]$NonInteractive
)

if ($NonInteractive) {
    $ScriptParams = $MyInvocation.MyCommand.ScriptBlock.Ast.ParamBlock.Parameters | ForEach-Object { $_.Name.VariablePath.UserPath }
    foreach ($param in $ScriptParams) {
        if (-not $PSBoundParameters.ContainsKey($param)) {
            throw "Non-interactive execution missing [$param] parameter."
        }
    }
}

# ==============================================================================
# =================================== IMPORTS ==================================
# ==============================================================================
$ModulesPath = Join-Path $PSScriptRoot "modules"
Import-Module (Join-Path $ModulesPath "CommonUtils.psm1") -Force
Import-Module (Join-Path $ModulesPath "MssqlUtils.psm1") -Force

# ==============================================================================
# =========================== PARAM/INPUT VALIDATION ===========================
# ==============================================================================
Write-Host ""

# $MssqlServerAddress
if (-not $NonInteractive) {
    $MssqlServerAddress = (Read-Host "Enter MSSQL server address")
}
$MssqlServerAddress = Assert-TrimStrIsValidServerAddress $MssqlServerAddress -Name "MSSQL server address"

# $MssqlUsername
if (-not $NonInteractive) {
    $MssqlUsername = (Read-Host "Enter MSSQL username")
}
$MssqlUsername = Assert-TrimStrIsNotNullOrEmpty $MssqlUsername -Name "MSSQL username"

# $MssqlPassword
if (-not $NonInteractive) {
    $MssqlPassword = (Read-SecureStringAsString "Enter MSSQL password")
}
$MssqlPassword = Assert-TrimStrIsNotNullOrEmpty $MssqlPassword -Name "MSSQL password"

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
$securePassword = ConvertTo-SecureString $MssqlPassword -AsPlainText -Force
$credential = [PSCredential]::new($MssqlUsername, $securePassword)
$MssqlPassword = $null

$accountEntry = Get-MSSQLScalarValue `
    -ServerAddress $MssqlServerAddress `
    -Credential $credential `
    -Table "atum2_db_account.dbo.td_Account" `
    -Column "AccountName" `
    -WhereCondition "AccountName = '$AccountName'"
if ($null -ne $accountEntry) {
    throw "Account name [$AccountName] already in use!"
}

$columns = @{
    "AccountName"                     = "'$AccountName'"
    "Password"                        = "'$AccountPassword'"
    "AccountType"                     = "$AccountType"
    "Sex"                             = "NULL"
    "BirthYear"                       = "NULL"
    "RegisteredDate"                  = "getdate()"
    "LastLoginDate"                   = "getdate()"
    "IsBlocked"                       = "0"
    "ChattingBlocked"                 = "0"
    "MGameEventType"                  = "0"
    "ConnectingServerGroupID"         = "0"
    "GameContinueTimeInSecondOfToday" = "0"
    "LastGameEndDate"                 = "getdate()"
    "JuminNumber"                     = "NULL"
    "SecondaryPassword"               = "NULL"
    "userfrom"                        = "0"
    "Password_new"                    = "NULL"
    "email"                           = "NULL"
    "CashPoint"                       = "1"
    "WarPoint"                        = "1"
    "CumulativeWarPoint"              = "1"
    "VoteCount"                       = "0"
    "WebPoint"                        = "0"
    "ActivationCode"                  = "NULL"
    "Active"                          = "1"
    "LastGetDCoinDate"                = "NULL"
    "GameContinueTimeInSecondofEvent" = "NULL"
}

Add-MSSQLRowIntoTable `
    -ServerAddress $MssqlServerAddress `
    -Credential $credential `
    -Table "atum2_db_account.dbo.td_Account" `
    -Columns $columns `

$exitMsg = @"
Account created!
Account Name: $AccountName
Account Type: $AccountType
Script successful!
"@
Write-Host $exitMsg -ForegroundColor Green
Exit 0
