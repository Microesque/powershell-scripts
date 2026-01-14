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
$value = (Read-Host "Enter the new happy hour exp multiplier").Trim()
if (-not [double]::TryParse($value, [ref]$value) -or $value -lt 0.0) {
    Stop-ScriptWithErrorMessage "Invalid multiplier value. -> $value"
}
$table = "atum2_db_account.dbo.ti_HappyHourEvent"
$whereCondition = "UniqueNumber > 100"

# Set new value
try {
    $columnsAffected = Set-TableColumnValues `
        -Server $server `
        -Username $username `
        -Password $password `
        -Table $table `
        -Column "EXPRate" `
        -Value "$value" `
        -WhereCondition $whereCondition
    if ($columnsAffected -eq 0) {
        throw "Number of rows affected was 0!"
    }
}
catch {
    Stop-ScriptWithErrorMessage "Something went wrong during SQL execution:`n$($_.Exception.Message)"
}

# Update user and exit
Write-Host "Happy hours exp rate is set to $($value * 100)%. (Requires server restart!)" -ForegroundColor Green
Stop-ScriptWithSuccessMessage "Script successful."
