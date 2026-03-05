<#
.SYNOPSIS
Updates the war points of an account via the MSSQL database.

.DESCRIPTION
Connects to the MSSQL database and updates the war point value of the specified
account. The script runs in interactive mode by default, prompting for
parameters. It can be run in non-interactive mode by using the -NonInteractive
switch, which requires all parameters to be supplied.

.PARAMETER MssqlServerAddress
The address of the MSSQL server to connect to (e.g., 'localhost',
'192.168.1.10').

.PARAMETER MssqlUsername
The username for authenticating to the MSSQL server.

.PARAMETER MssqlPassword
The password for authenticating to the MSSQL server.

.PARAMETER AccountName
The name of the account whose war points will be updated.

.PARAMETER Value
The war points value to set. Prefix the value with `+` or `-` to add or
subtract from the existing value instead of setting it directly.

.PARAMETER NonInteractive
If specified, disables interactive prompts and requires all parameters to be
provided. Throws an error if any parameter is missing.

.OUTPUTS
None. Prints informational messages to the host. Intended for use by catching
throws with error messages. Returns exit code 0 when successful.

.NOTES
- Throws an error if parameter validation fails.
- Throws an error if the account does not exist or if database operations
fail.
- Requires the .psm1 files in the `/modules` directory.
- War points cannot be set below `0`. If subtraction results in a negative
value, it is clamped to `0`.
- For more information about accounts, refer to table info
`atum2_db_account.dbo.td_Account`.
#>

# ==============================================================================
# =================================== PARAMS ===================================
# ==============================================================================
[CmdletBinding()]
param (
    [string]$MssqlServerAddress,
    [string]$MssqlUsername,
    [string]$MssqlPassword,
    [string]$AccountName,
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
$securePassword = ConvertTo-SecureString $MssqlPassword -AsPlainText -Force
$credential = [PSCredential]::new($MssqlUsername, $securePassword)
$MssqlPassword = $null

$table = "atum2_db_account.dbo.td_Account"
$column = "WarPoint"
$whereCondition = "AccountName = '$AccountName'"

$oldValue = Get-MSSQLScalarValue `
    -ServerAddress $MssqlServerAddress `
    -Credential $credential `
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
    
Set-MSSQLColumnValues `
    -ServerAddress $MssqlServerAddress `
    -Credential $credential `
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
