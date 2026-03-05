<#
.SYNOPSIS
Marks the active quests of a character as complete via the MSSQL database.

.DESCRIPTION
Connects to the MSSQL database and updates the state of the currently active
quests as complete for the specified character. The script runs in interactive
mode by default, prompting for parameters. It can be run in non-interactive mode
by using the -NonInteractive switch, which requires all parameters to be
supplied.

.PARAMETER MssqlServerAddress
The address of the MSSQL server to connect to (e.g., 'localhost',
'192.168.1.10').

.PARAMETER MssqlUsername
The username for authenticating to the MSSQL server.

.PARAMETER MssqlPassword
The password for authenticating to the MSSQL server.

.PARAMETER CharacterName
The name of the character whose active quests will be marked as complete.

.PARAMETER NonInteractive
If specified, disables interactive prompts and requires all parameters to be
provided. Throws an error if any parameter is missing.

.OUTPUTS
None. Prints informational messages to the host. Intended for use by catching
throws with error messages. Returns exit code 0 when successful.

.NOTES
- Throws an error if parameter validation fails.
- Throws an error if the character does not exist or if database operations
fail.
- Throws an error if the character has no active quests.
- Requires the .psm1 files in the `/modules` directory.
- The character must re-log in for the quest state changes to take effect.
- For more information about quests, refer to table info
`atum2_db_1.dbo.td_CharacterQuest`.
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
    $CharacterName = (Read-Host "Enter character name")
}
$CharacterName = Assert-TrimStrIsNotNullOrEmpty $CharacterName -Name "Character name"

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

$rowsAffected = Set-MSSQLColumnValues `
    -ServerAddress $MssqlServerAddress `
    -Credential $credential `
    -Table "atum2_db_1.dbo.td_CharacterQuest" `
    -Column "QuestState" `
    -Value "2" `
    -WhereCondition "CharacterUniqueNumber = $characterUniqueNumber AND QuestState = 1"

if ($rowsAffected -eq 0) {
    throw "No active quest found for the character [$CharacterName]!"
}

$exitMsg = @"
The character [$CharacterName] had [$rowsAffected] active quests, which are now complete!
(Requires character re-log!)
Script successful!
"@
Write-Host $exitMsg -ForegroundColor Green
Exit 0
