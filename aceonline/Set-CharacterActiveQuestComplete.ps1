# ==============================================================================
# =================================== PARAMS ===================================
# ==============================================================================
[CmdletBinding()]
param (
    [string]$Server,
    [string]$Username,
    [string]$Password,
    [string]$CharacterName,

    [switch]$NonInteractive
)

if ($NonInteractive) {
    foreach ($name in "Server", "Username", "Password", "CharacterName") {
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

# $CharacterName
if (-not $NonInteractive) {
    $CharacterName = (Read-Host "Enter character name")
}
$CharacterName = Assert-TrimStrIsNotNullOrEmpty $CharacterName -Name "Character name"

# ==============================================================================
# =================================== SCRIPT ===================================
# ==============================================================================
$characterUniqueNumber = Get-TableColumnValue `
    -Server $Server `
    -Username $Username `
    -Password $Password `
    -Table "atum2_db_1.dbo.td_Character" `
    -Column "UniqueNumber" `
    -WhereCondition "CharacterName = '$CharacterName'"

if ($null -eq $characterUniqueNumber) {
    throw "Character name [$CharacterName] was not found!"
}

$columnsAffected = Set-TableColumnValues `
    -Server $Server `
    -Username $Username `
    -Password $Password `
    -Table "atum2_db_1.dbo.td_CharacterQuest" `
    -Column "QuestState" `
    -Value "2" `
    -WhereCondition "CharacterUniqueNumber = $characterUniqueNumber AND QuestState = 1"

if ($columnsAffected -eq 0) {
    throw "No active quest found for the character [$CharacterName]!"
}

$exitMsg = @"
The character [$CharacterName] had [$columnsAffected] active quests, which are now complete!
(Requires character re-log!)
Script successful!
"@
Write-Host $exitMsg -ForegroundColor Green
Exit 0
