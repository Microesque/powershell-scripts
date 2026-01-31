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
if ($NonInteractive) {
    $Server = $Server.Trim()
    $Username = $Username.Trim()
    $Password = $Password.Trim()
    $AccountName = $AccountName.Trim()
    $Value = $Value.Trim()

    try {
        Assert-ServerAndCredentials $Server $Username $Password
    }
    catch {
        Stop-ScriptWithErrorMessage $_.Exception.Message
    }

    if ([string]::IsNullOrEmpty($AccountName)) {
        Stop-ScriptWithErrorMessage "Account name empty!"
    }

    if ([string]::IsNullOrEmpty($Value)) {
        Stop-ScriptWithErrorMessage "Value empty!"
    }
    elseif ($Value -notmatch "^[+-]?\d+$") {
        Stop-ScriptWithErrorMessage "Value needs to be an integer, optionally prefixed with + or - -> $Value"
    }
}
else {
    try {
        $Server, $Username, $Password = Read-ServerAndCredentials
    }
    catch {
        Stop-ScriptWithErrorMessage $_.Exception.Message
    }

    $AccountName = (Read-Host "Enter game account name").Trim()
    if ([string]::IsNullOrEmpty($AccountName)) {
        Stop-ScriptWithErrorMessage "Account name empty!"
    }

    $Value = (Read-Host "War points value to set (prefix with + or - to add or subtract instead)").Trim()
    if ([string]::IsNullOrEmpty($Value)) {
        Stop-ScriptWithErrorMessage "Value empty!"
    }
    elseif ($Value -notmatch "^[+-]?\d+$") {
        Stop-ScriptWithErrorMessage "Value needs to be an integer, optionally prefixed with + or - -> $Value"
    }
}

# ==============================================================================
# =================================== SCRIPT ===================================
# ==============================================================================
$table = "atum2_db_account.dbo.td_Account"
$whereCondition = "AccountName = '$AccountName'"

try {
    # Get the current value
    $currentWarPoint = Get-TableColumnValue `
        -Server $Server `
        -Username $Username `
        -Password $Password `
        -Table $table `
        -Column "WarPoint" `
        -WhereCondition $whereCondition
    if ($currentWarPoint -eq $null) {
        Stop-ScriptWithErrorMessage "Account name was not found! -> $AccountName"
    }

    # Calculate the value to set
    if ($Value.StartsWith('+') -or $Value.StartsWith('-')) {
        $valueInt = [int]$currentWarPoint + [int]$Value
        if ($valueInt -lt 0) {
            $valueInt = 0
        }
    }
    else {
        $valueInt = [int]$Value
    }
    
    #Set the new value
    $columnsAffected = Set-TableColumnValues `
        -Server $Server `
        -Username $Username `
        -Password $Password `
        -Table $table `
        -Column "WarPoint" `
        -Value "$valueInt" `
        -WhereCondition $whereCondition
}
catch {
    Stop-ScriptWithErrorMessage "Something went wrong during SQL execution:`n$($_.Exception.Message)"
}

Write-Host "Account name `"$AccountName`" war points was: $currentWarPoint" -ForegroundColor Green
Write-Host "Account name `"$AccountName`" war points set to: $valueInt" -ForegroundColor Green
Stop-ScriptWithSuccessMessage "Script successful."
