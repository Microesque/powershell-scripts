# ==============================================================================
# =================================== IMPORTS ==================================
# ==============================================================================
$ModulesPath = Join-Path $PSScriptRoot "modules"
Import-Module (Join-Path $ModulesPath "CommonUtils.psm1") -Force -ErrorAction Stop
Import-Module (Join-Path $ModulesPath "WslUtils.psm1") -Force -ErrorAction Stop

# ==============================================================================
# ================================= ADMIN CHECK ================================
# ==============================================================================
if (-not (Test-IsAdministrator)) {
    throw "This script must be run with administrative privileges."
}

# ==============================================================================
# =================================== SCRIPT ===================================
# ==============================================================================
$exitCode = 0

Write-Host ""

Write-StepTitle "Checking software requirements"
if (-not (Test-Wsl2SoftwareRequirements)) { $exitCode = 1 }

Write-StepTitle "Checking hardware requirements"
if (-not (Test-Wsl2HardwareRequirements)) { $exitCode = 1 }

Write-Host ""

exit $exitCode
