# ==============================================================================
# =================================== PARAMS ===================================
# ==============================================================================
[CmdletBinding()]
param (
    [string]$SQLServer,
    [string]$SQLUsername,
    [string]$SQLPassword,
    [string]$Value,

    [switch]$NonInteractive
)

if ($NonInteractive) {
    foreach ($name in "Server", "Username", "Password", "Value") {
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

# $Value
if (-not $NonInteractive) {
    $Value = (Read-Host "Enter the new happy hour EXP multiplier")
}
$Value = Assert-TrimStrIsPositiveFloat $Value -Name "EXP multiplier"

# ==============================================================================
# =================================== SCRIPT ===================================
# ==============================================================================
$table = "atum2_db_account.dbo.ti_HappyHourEvent"
$column = "EXPRate"
$whereCondition = "DayOfWeek BETWEEN 0 AND 6"

$oldValue = Get-TableColumnValue `
    -Server $SQLServer `
    -Username $SQLUsername `
    -Password $SQLPassword `
    -Table $table `
    -Column $column `
    -WhereCondition $whereCondition

$columnsAffected = Set-TableColumnValues `
    -Server $SQLServer `
    -Username $SQLUsername `
    -Password $SQLPassword `
    -Table $table `
    -Column $column `
    -Value $Value `
    -WhereCondition $whereCondition

if ($columnsAffected -eq 0) {
    throw "Number of rows affected was 0!"
}

$exitMsg = @"
Happy hours EXP was set to $([float]$oldValue * 100)%.
Happy hours EXP rate is set to $([float]$Value * 100)%.
(Requires server restart!)
Script successful!
"@
Write-Host $exitMsg -ForegroundColor Green
Exit 0
