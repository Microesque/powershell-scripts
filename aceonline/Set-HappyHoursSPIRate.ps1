# ==============================================================================
# =================================== PARAMS ===================================
# ==============================================================================
[CmdletBinding()]
param (
    [string]$Server,
    [string]$Username,
    [string]$Password,
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

# $Value
if (-not $NonInteractive) {
    $Value = (Read-Host "Enter the new happy hour SPI multiplier")
}
$Value = Assert-TrimStrIsPositiveFloat $Value -Name "SPI multiplier"

# ==============================================================================
# =================================== SCRIPT ===================================
# ==============================================================================
$table = "atum2_db_account.dbo.ti_HappyHourEvent"
$column = "SPIRate"
$whereCondition = "DayOfWeek BETWEEN 0 AND 6"

$oldValue = Get-TableColumnValue `
    -Server $Server `
    -Username $Username `
    -Password $Password `
    -Table $table `
    -Column $column `
    -WhereCondition $whereCondition

$columnsAffected = Set-TableColumnValues `
    -Server $Server `
    -Username $Username `
    -Password $Password `
    -Table $table `
    -Column $column `
    -Value $Value `
    -WhereCondition $whereCondition

if ($columnsAffected -eq 0) {
    throw "Number of rows affected was 0!"
}

$exitMsg = @"
Happy hours SPI was set to $([float]$oldValue * 100)%.
Happy hours SPI rate is set to $([float]$Value * 100)%.
(Requires server restart!)
Script successful!
"@
Write-Host $exitMsg -ForegroundColor Green
Exit 0
