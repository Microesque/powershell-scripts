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
$server, $username, $password = Read-ServerAndCredentials
$table = "atum2_db_account.dbo.td_Account"
$accountName = "abi"
$whereCondition = "AccountName = '$accountName'"
$cashPointAdd = 10050
$warPointAdd = 10000

try {
    # Get current values
    $currentCashPoint = Get-TableColumnValue `
        -Server $server `
        -Username $username `
        -Password $password `
        -Table $table `
        -Column "CashPoint" `
        -WhereCondition $whereCondition
    $currentWarPoint = Get-TableColumnValue `
        -Server $server `
        -Username $username `
        -Password $password `
        -Table $table `
        -Column "WarPoint" `
        -WhereCondition $whereCondition
    Write-Host "Account name `"$accountName`" current cash points: $currentCashPoint" -ForegroundColor Green
    Write-Host "Account name `"$accountName`" current war points: $currentWarPoint" -ForegroundColor Green

    # Set new values
    $cashPointSet = $currentCashPoint + $cashPointAdd
    $warPointSet = $currentWarPoint + $warPointAdd
    $null = Set-TableColumnValues `
        -Server $server `
        -Username $username `
        -Password $password `
        -Table $table `
        -Column "CashPoint" `
        -Value "$cashPointSet" `
        -WhereCondition $whereCondition
    $null = Set-TableColumnValues `
        -Server $server `
        -Username $username `
        -Password $password `
        -Table $table `
        -Column "WarPoint" `
        -Value "$warPointSet" `
        -WhereCondition $WhereCondition
    Write-Host "Account name `"$accountName`" received cash points: +$cashPointAdd" -ForegroundColor Green
    Write-Host "Account name `"$accountName`" received war points: +$warPointAdd" -ForegroundColor Green
    Write-Host "Account name `"$accountName`" current cash points: $cashPointSet" -ForegroundColor Green
    Write-Host "Account name `"$accountName`" current war points: $warPointSet" -ForegroundColor Green
}
catch {
    Stop-ScriptWithErrorMessage "Something went wrong during SQL execution:`n$($_.Exception.Message)"
}

# Exit
Stop-ScriptWithSuccessMessage "Daily bonuses granted."
