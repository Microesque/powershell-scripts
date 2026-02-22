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
Write-Host ""

# Check requirements
Write-StepTitle "Checking software requirements"
$test1 = Test-Wsl2SoftwareRequirements
Write-StepTitle "Checking hardware requirements"
$test2 = Test-Wsl2HardwareRequirements
if (-not ($test1 -and $test2)) {
    Write-Host ""
    exit 1
}

# Check faulty installation
Write-StepTitle "Checking current installation"
if (-not (Test-WslExecutable)) {
    Write-Host ""
    exit 1
}

# Install/update
$isSuccess = $false
if (Test-WslInstallation) {
    Write-WslVersion
    Write-StepTitle "Updating WSL"
    if (Update-Wsl) {
        $isSuccess = $true
        Write-WslVersion
    }
}
else {
    Write-StepTitle "Installing WSL"
    if (Install-Wsl) {
        $isSuccess = $true
        Write-WslVersion
    }
}

# Check WSL2 installation
if (-not (Test-Wsl2Installation)) {
    $isSuccess = $false
}
Write-Host ""
if ($isSuccess) {
    exit 0
}
exit 1
