<#
.SYNOPSIS
Updates the happy hour EXP rate via the MSSQL database.

.DESCRIPTION
Connects to the MSSQL database and updates the EXP multiplier used during
happy hour events. The script runs in interactive mode by default, prompting 
for parameters. It can be run in non-interactive mode by using the
-NonInteractive switch, which requires all parameters to be supplied.

.PARAMETER MssqlServerAddress
The address of the MSSQL server to connect to (e.g., 'localhost',
'192.168.1.10').

.PARAMETER MssqlUsername
The username for authenticating to the MSSQL server.

.PARAMETER MssqlPassword
The password for authenticating to the MSSQL server.

.PARAMETER Value
The EXP multiplier to set for happy hour events. The value must be a positive
floating-point number. Happy hour bonuses are written as direct multipliers,
even though they are shown as percentile increases in game. For example, setting
the EXP rate to 25 will increase the EXP gain by 2500% in game.

.PARAMETER NonInteractive
If specified, disables interactive prompts and requires all parameters to be
provided. Throws an error if any parameter is missing.

.OUTPUTS
None. Prints informational messages to the host. Intended for use by catching
throws with error messages. Returns exit code 0 when successful.

.NOTES
- Throws an error if parameter validation fails.
- Throws an error if the happy hour entries for days `0-6` do not exist or if
database operations fail.
- Requires the .psm1 files in the `/modules` directory.
- A server restart is required for the updated EXP rate to take effect.
- For more information about happy hour events, refer to table info
`atum2_db_account.dbo.ti_HappyHourEvent`.
#>

# ==============================================================================
# =================================== PARAMS ===================================
# ==============================================================================
[CmdletBinding()]
param (
    [string]$MssqlServerAddress,
    [string]$MssqlUsername,
    [string]$MssqlPassword,
    [string]$Value,

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

# $Value
if (-not $NonInteractive) {
    $Value = (Read-Host "Enter the new happy hour EXP multiplier")
}
$Value = Assert-TrimStrIsPositiveFloat $Value -Name "EXP multiplier"

# ==============================================================================
# =================================== SCRIPT ===================================
# ==============================================================================
$securePassword = ConvertTo-SecureString $MssqlPassword -AsPlainText -Force
$credential = [PSCredential]::new($MssqlUsername, $securePassword)
$MssqlPassword = $null

$table = "atum2_db_account.dbo.ti_HappyHourEvent"
$column = "EXPRate"
$whereCondition = "DayOfWeek BETWEEN 0 AND 6"

$oldValue = Get-MSSQLScalarValue `
    -ServerAddress $MssqlServerAddress `
    -Credential $credential `
    -Table $table `
    -Column $column `
    -WhereCondition $whereCondition
if ($null -eq $oldValue) {
    throw "DayOfWeek 0-6 entry missing!"
}

Set-MSSQLColumnValues `
    -ServerAddress $MssqlServerAddress `
    -Credential $credential `
    -Table $table `
    -Column $column `
    -Value $Value `
    -WhereCondition $whereCondition

$exitMsg = @"
Happy hours EXP was set to $([float]$oldValue * 100)%.
Happy hours EXP rate is set to $([float]$Value * 100)%.
(Requires server restart!)
Script successful!
"@
Write-Host $exitMsg -ForegroundColor Green
Exit 0
