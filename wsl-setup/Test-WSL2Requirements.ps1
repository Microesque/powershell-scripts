# ==============================================================================
# ================================= ADMIN CHECK ================================
# ==============================================================================
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
$isAdmin = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    throw "This script must be run with administrative privileges."
}

# ==============================================================================
# =================================== IMPORTS ==================================
# ==============================================================================
$ModulesPath = Join-Path $PSScriptRoot "modules"
Import-Module (Join-Path $ModulesPath "CommonUtils.psm1") -Force -ErrorAction Stop
Import-Module (Join-Path $ModulesPath "WslUtils.psm1") -Force -ErrorAction Stop

# ==============================================================================
# =================================== SCRIPT ===================================
# ==============================================================================

$exitCode = 0

Write-Host ""

Write-StepTitle "Checking software requirements"
if (-not (Test-SoftwareRequirements)) { $exitCode = 1 }

Write-StepTitle "Checking hardware requirements"
if (-not (Test-HardwareRequirements)) { $exitCode = 1 }

Write-Host ""

exit $exitCode
