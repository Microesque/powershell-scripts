# ==============================================================================
# =================================== PARAMS ===================================
# ==============================================================================
[CmdletBinding()]
param (
    [string]$Server,
    [string]$Username,
    [string]$Password,
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

# $Server
if (-not $NonInteractive) {
    $Server = (Read-Host "Enter SQL server address")
}
$Server = Assert-TrimStrIsValidServerAddress $Server -Name "Server"

# $Username
if (-not $NonInteractive) {
    $Username = (Read-Host "Enter SQL username")
}
$Username = Assert-TrimStrIsNotNullOrEmpty $Username -Name "Username"

# $Password
if (-not $NonInteractive) {
    $Password = (Read-SecureStringAsString "Enter SQL password")
}
$Password = Assert-TrimStrIsNotNullOrEmpty $Password -Name "Password"

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
    -Server $Server `
    -Username $Username `
    -Password $Password `
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
    -Server $Server `
    -Username $Username `
    -Password $Password `
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
