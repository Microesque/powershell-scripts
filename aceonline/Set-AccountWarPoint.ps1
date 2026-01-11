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
$value = (Read-Host "War points value to set").Trim()
if ([string]::IsNullOrEmpty($value)) {
    Stop-ScriptWithErrorMessage "Value empty!"
}
elseif ($value -notmatch '^\d+$') {
    Stop-ScriptWithErrorMessage "Value needs to be an integer! -> $value"
}
$table = "atum2_db_account.dbo.td_Account"
$whereCondition = "AccountName = '$accountName'"

# Set new value
try {
    $columnsAffected = Set-TableColumnValues `
        -Server $server `
        -Username $username `
        -Password $password `
        -Table $table `
        -Column "WarPoint" `
        -Value "$value" `
        -WhereCondition $whereCondition
}
catch {
    Stop-ScriptWithErrorMessage "Something went wrong during SQL execution:`n$($_.Exception.Message)"
}

# Update user and exit
if ($columnsAffected -eq 0) {
    Stop-ScriptWithErrorMessage "Account name was not found! -> $accountName"
}
Write-Host "Account name `"$accountName`" war points set to: $value" -ForegroundColor Green
Stop-ScriptWithSuccessMessage "Script successful."
