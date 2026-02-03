# ==============================================================================
# =================================== PARAMS ===================================
# ==============================================================================
[CmdletBinding()]
param (
    [string]$SQLServer,
    [string]$SQLUsername,
    [string]$SQLPassword,
    [string]$AccountName,
    [string]$Value,

    [switch]$NonInteractive
)

if ($NonInteractive) {
    foreach ($name in "Server", "Username", "Password", "AccountName", "Value") {
        if (-not $PSBoundParameters.ContainsKey($name)) {
            Stop-ScriptWithErrorMessage "Non-interactive execution missing $name parameter."
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
    $AccountName = (Read-Host "Enter account name")
}
$AccountName = Assert-TrimStrIsNotNullOrEmpty $AccountName -Name "Account name"

# $Value
if (-not $NonInteractive) {
    $Value = (Read-Host "War points value to set (prefix with + or - to add or subtract instead)")
}
$Value = Assert-TrimStrIsPrefixedInt $Value -Name "War points"

# ==============================================================================
# =================================== SCRIPT ===================================
# ==============================================================================
$table = "atum2_db_account.dbo.td_Account"
$column = "WarPoint"
$whereCondition = "AccountName = '$AccountName'"

$oldValue = Get-TableColumnValue `
    -Server $SQLServer `
    -Username $SQLUsername `
    -Password $SQLPassword `
    -Table $table `
    -Column $column `
    -WhereCondition $whereCondition
if ($null -eq $oldValue) {
    throw "Account name [$AccountName] was not found!"
}

if ($Value.StartsWith('+') -or $Value.StartsWith('-')) {
    $valueInt = [int]$oldValue + [int]$Value
    if ($valueInt -lt 0) {
        $valueInt = 0
    }
}
else {
    $valueInt = [int]$Value
}
    
$columnsAffected = Set-TableColumnValues `
    -Server $SQLServer `
    -Username $SQLUsername `
    -Password $SQLPassword `
    -Table $table `
    -Column $column `
    -Value "$valueInt" `
    -WhereCondition $whereCondition

$exitMsg = @"
War points for [$AccountName] was: $oldValue
War points for [$AccountName] set to: $valueInt
Script successful.
"@
Write-Host $exitMsg -ForegroundColor Green
Exit 0
