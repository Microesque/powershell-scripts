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
