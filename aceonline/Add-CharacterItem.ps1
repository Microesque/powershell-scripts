<#
.SYNOPSIS
Adds a specified item to a character's inventory via the MSSQL database.

.DESCRIPTION
Connects to the MSSQL database and adds the specified item to the specified
character's inventory. The script runs in interactive mode by default, prompting 
for parameters. It can be run in non-interactive mode by using the
-NonInteractive switch, which requires all parameters to be supplied.

.PARAMETER MssqlServerAddress
The address of the MSSQL server to connect to (e.g., 'localhost',
'192.168.1.10').

.PARAMETER MssqlUsername
The username for authenticating to the MSSQL server.

.PARAMETER MssqlPassword
The password for authenticating to the MSSQL server.

.PARAMETER CharacterName
The name of the character to whom the item will be added.

.PARAMETER ItemNumber
The numeric identifier of the item to add (`ItemNum` in the database).

.PARAMETER ItemCount
The quantity of the item to add to the character's inventory.

.PARAMETER NonInteractive
If specified, disables interactive prompts and requires all parameters to be
provided. Throws an error if any parameter is missing.

.OUTPUTS
None. Prints informational messages to the host. Intended for use by catching
throws with error messages. Returns exit code 0 when successful.

.NOTES
- Throws an error if parameter validation fails.
- Throws an error if the character does not exist, if database operations fail, 
or if parameters are missing in non-interactive mode.
- Requires the .psm1 files in the `/modules` directory.
- Requires the target character to re-log in for their inventory to update.
- Existing item counts are incremented, while new items are inserted into the
inventory. Completely ignores storage.
- For more information about inventory management, refer to table info
`atum2_db_1.dbo.td_Store`.
#>

# ==============================================================================
# =================================== PARAMS ===================================
# ==============================================================================
[CmdletBinding()]
param (
    [string]$MssqlServerAddress,
    [string]$MssqlUsername,
    [string]$MssqlPassword,
    [string]$CharacterName,
    [string]$ItemNumber,
    [string]$ItemCount,

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

# $CharacterName
if (-not $NonInteractive) {
    $CharacterName = (Read-Host "Enter the character name")
}
$CharacterName = Assert-TrimStrIsNotNullOrEmpty $CharacterName -Name "Character name"

# $ItemNumber
if (-not $NonInteractive) {
    $ItemNumber = (Read-Host "Enter the item number")
}
$ItemNumber = Assert-TrimStrIsPositiveInt $ItemNumber -Name "Item number"

# $ItemNumber
if (-not $NonInteractive) {
    $ItemCount = (Read-Host "Enter the item count")
}
$ItemCount = Assert-TrimStrIsPositiveInt $ItemCount -Name "Item count"

# ==============================================================================
# =================================== SCRIPT ===================================
# ==============================================================================
$securePassword = ConvertTo-SecureString $MssqlPassword -AsPlainText -Force
$credential = [PSCredential]::new($MssqlUsername, $securePassword)
$MssqlPassword = $null

$characterUniqueNumber = Get-MSSQLScalarValue `
    -ServerAddress $MssqlServerAddress `
    -Credential $credential `
    -Table "atum2_db_1.dbo.td_Character" `
    -Column "UniqueNumber" `
    -WhereCondition "CharacterName = '$CharacterName'"
if ($null -eq $characterUniqueNumber) {
    throw "Character name [$CharacterName] was not found!"
}

$accountUniqueNumber = Get-MSSQLScalarValue `
    -ServerAddress $MssqlServerAddress `
    -Credential $credential `
    -Table "atum2_db_1.dbo.td_Character" `
    -Column "AccountUniqueNumber" `
    -WhereCondition "CharacterName = '$CharacterName'"

$currentItemCount = Get-MSSQLScalarValue `
    -ServerAddress $MssqlServerAddress `
    -Credential $credential `
    -Table "atum2_db_1.dbo.td_Store" `
    -Column "CurrentCount" `
    -WhereCondition "AccountUniqueNumber = $accountUniqueNumber AND Possess = $characterUniqueNumber AND ItemNum = $ItemNumber AND ItemStorage = 0"

if ($null -eq $currentItemCount) {
    # Character doesn't have the item in inventory
    $currentItemCount = 0
    
    $maxItemIndex = Get-MSSQLMaxColumnValue `
        -ServerAddress $MssqlServerAddress `
        -Credential $credential `
        -Table "atum2_db_1.dbo.td_Store" `
        -Column "ItemWindowIndex" `
        -WhereCondition "AccountUniqueNumber = $accountUniqueNumber AND Possess = $characterUniqueNumber AND ItemStorage = 0"
    if ($null -eq $maxItemIndex) {
        $maxItemIndex = 100L
    }
    else {
        $maxItemIndex = [long]$maxItemIndex
    }
    
    if ($maxItemIndex -lt 100) {
        $maxItemIndex = 100L
    }
    else {
        $maxItemIndex++
    }

    $columns = @{
        "AccountUniqueNumber" = "$accountUniqueNumber"
        "Possess"             = "$characterUniqueNumber"
        "ItemStorage"         = "0"
        "Wear"                = "0"
        "CurrentCount"        = "$ItemCount"
        "ItemWindowIndex"     = "$maxItemIndex"
        "ItemNum"             = "$ItemNumber"
        "NumOfEnchants"       = "0"
        "PrefixCodeNum"       = "0"
        "SuffixCodeNum"       = "0"
        "CurrentEndurance"    = "0"
        "ColorCode"           = "0"
        "UsingTimeStamp"      = "0"
        "CreatedTime"         = "getdate()"
        "ShapeItemNum"        = "0"
        "MainSvrItemUID"      = "0"
        "CoolingTime"         = "0"
    }
    Add-MSSQLRowIntoTable `
        -ServerAddress $MssqlServerAddress `
        -Credential $credential `
        -Table "atum2_db_1.dbo.td_Store" `
        -Columns $columns
}
else {
    # Character has at least one of the item in inventory
    Set-MSSQLColumnValues `
        -ServerAddress $MssqlServerAddress `
        -Credential $credential `
        -Table "atum2_db_1.dbo.td_Store" `
        -Column "CurrentCount" `
        -Value "$($currentItemCount + $ItemCount)" `
        -WhereCondition "AccountUniqueNumber = $accountUniqueNumber AND Possess = $characterUniqueNumber AND ItemNum = $ItemNumber AND ItemStorage = 0"
}

$exitMsg = @"
The character [$CharacterName] had [$currentItemCount] of item [$ItemNumber]!
The character [$CharacterName] now has [$($currentItemCount + $ItemCount)] of item [$ItemNumber]!
(Requires character re-log!)
Script successful!
"@
Write-Host $exitMsg -ForegroundColor Green
Exit 0
