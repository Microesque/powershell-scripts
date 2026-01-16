# ==============================================================================
# =================================== IMPORTS ==================================
# ==============================================================================
$ModulesPath = Join-Path $PSScriptRoot "modules"
Import-Module (Join-Path $ModulesPath "CommonUtils.psm1") -Force
Import-Module (Join-Path $ModulesPath "SqlExpressUtils.psm1") -Force

# ==============================================================================
# =================================== SCRIPT ===================================
# ==============================================================================
# Get user input
Clear-Host
try {
    $server, $username, $password = Read-ServerAndCredentials
}
catch {
    Stop-ScriptWithErrorMessage $_.Exception.Message
}
$accountName = (Read-Host "Enter game account name").Trim()
if ([string]::IsNullOrEmpty($accountName)) {
    Stop-ScriptWithErrorMessage "Account name empty!"
}
$value = (Read-Host "War points value to set (prefix with + or - to add or subtract instead)").Trim()
if ([string]::IsNullOrEmpty($value)) {
    Stop-ScriptWithErrorMessage "Value empty!"
}
elseif ($value -notmatch "^[+-]?\d+$") {
    Stop-ScriptWithErrorMessage "Value needs to be an integer, optionally prefixed with + or - -> $value"
}
$table = "atum2_db_account.dbo.td_Account"
$whereCondition = "AccountName = '$accountName'"

try {
    # Get the current value
    $currentWarPoint = Get-TableColumnValue `
        -Server $server `
        -Username $username `
        -Password $password `
        -Table $table `
        -Column "WarPoint" `
        -WhereCondition $whereCondition
    if ($currentWarPoint -eq $null) {
        Stop-ScriptWithErrorMessage "Account name was not found! -> $accountName"
    }

    # Calculate the value to set
    if ($value.StartsWith('+') -or $value.StartsWith('-')) {
        $valueInt = [int]$currentWarPoint + [int]$value
        if ($valueInt -lt 0) {
            $valueInt = 0
        }
    }
    else {
        $valueInt = [int]$value
    }
    
    #Set the new value
    $columnsAffected = Set-TableColumnValues `
        -Server $server `
        -Username $username `
        -Password $password `
        -Table $table `
        -Column "WarPoint" `
        -Value "$valueInt" `
        -WhereCondition $whereCondition
}
catch {
    Stop-ScriptWithErrorMessage "Something went wrong during SQL execution:`n$($_.Exception.Message)"
}

# Update user and exit
Write-Host "Account name `"$accountName`" war points was: $currentWarPoint" -ForegroundColor Green
Write-Host "Account name `"$accountName`" war points set to: $valueInt" -ForegroundColor Green
Stop-ScriptWithSuccessMessage "Script successful."
