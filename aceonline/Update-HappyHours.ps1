# ==============================================================================
# =================================== IMPORTS ==================================
# ==============================================================================
$ModulesPath = Join-Path $PSScriptRoot "modules"
Import-Module (Join-Path $ModulesPath "CommonUtils.psm1") -Force
Import-Module (Join-Path $ModulesPath "SqlUtils.psm1") -Force

# ==============================================================================
# ============================== INPUTS/VALIDATION =============================
# ==============================================================================
Clear-Host

$server = (Read-Host "Enter server ip (leave empty for 'localhost')").Trim()
if ([string]::IsNullOrEmpty($server)) {
    $server = "localhost"
}
elseif ($server -notmatch "^(?:[0-9]{1,3}\.){3}[0-9]{1,3}$") {
    Stop-ScriptWithErrorMessage "Invalid server IP: $server"
}

$username = (Read-Host "Enter SQL username").Trim()
$password = (Read-Host "Enter SQL password").Trim()

$happyHour = (Read-Host "Enter the new happy hour multiplier [0.0-10.0]").Trim()
if (-not [double]::TryParse($happyHour, [ref]$happyHour) -or $happyHour -lt 0.0 -or $happyHour -gt 10.0) {
    Stop-ScriptWithErrorMessage "Invalid happy hour value. Happy hour multiplier has to be a number between [0.0 - 10.0]."
}

# ==============================================================================
# =================================== SCRIPT ===================================
# ==============================================================================
$connectionString = "Server=$server;Database=master;User ID=$username;Password=$password;"
$query = @"
UPDATE [atum2_db_account].[dbo].[ti_HappyHourEvent]
SET EXPRate = $happyHour
WHERE UniqueNumber > 100;
"@

try {
    $rowsAffected = Invoke-SqlExecuteNonQuery $connectionString $query
}
catch {
    Stop-ScriptWithErrorMessage $_.Exception.Message
}

Write-Host "Rows affected: $rowsAffected" -ForegroundColor Green
Write-Host "Success! Happy hours is set to $($happyHour * 100)%. (Requires server restart!)" -ForegroundColor Green
