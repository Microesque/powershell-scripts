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
elseif (-not (Test-ServerIp $server)) {
    Stop-ScriptWithErrorMessage "Invalid server IP: $server"
}

$username = (Read-Host "Enter SQL username").Trim()
$password = (Read-Host "Enter SQL password").Trim()

$spiRate = (Read-Host "Enter the new happy hour spi multiplier [0.0-100.0]").Trim()
if (-not [double]::TryParse($spiRate, [ref]$spiRate) -or $spiRate -lt 0.0 -or $spiRate -gt 100.0) {
    Stop-ScriptWithErrorMessage "Invalid multiplier value. Multiplier has to be a number between [0.0 - 100.0]."
}

# ==============================================================================
# =================================== SCRIPT ===================================
# ==============================================================================
$connectionString = "Server=$server;Database=master;User ID=$username;Password=$password;"
$query = @"
UPDATE [atum2_db_account].[dbo].[ti_HappyHourEvent]
SET SPIRate = $spiRate
WHERE UniqueNumber > 100;
"@

try {
    $rowsAffected = Invoke-SqlExecuteNonQuery $connectionString $query
}
catch {
    Stop-ScriptWithErrorMessage $_.Exception.Message
}

Write-Host "Rows affected: $rowsAffected" -ForegroundColor Green
Write-Host "Success! Happy hours exp rate is set to $($spiRate * 100)%. (Requires server restart!)" -ForegroundColor Green
