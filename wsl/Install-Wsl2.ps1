<#
.SYNOPSIS
Installs or updates the WSL to ensure WSL2 can run on the current system.

.DESCRIPTION
Installs or updates the Windows Subsystem for Linux (WSL), then verifies that
WSL2 is correctly installed by checking the availability of a kernel version.

This script must be executed with administrative privileges.

.OUTPUTS
None. Prints informational messages to the host. Intended to be used with the
exit code. Exitcode:
    0 -> WSL installation or update was successful and WSL2 is available.
    1 -> WSL installation or update failed, `wsl.exe` is unavailable, or WSL2
         verification failed.

.NOTES
- Requires the .psm1 files in the `/modules` directory.
- WSL2 verification is performed by checking for a Linux kernel version.
#>
[CmdletBinding()]

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
Write-StepTitle "Installing WSL"

# Check faulty installation
try {
    if (Test-WslExecutable) {
        Write-Log "wsl.exe is available and suitable." -Success
    }
    else {
        Write-Log "wsl.exe not found in the system PATH or might be too old." -Fail
        exit 1
    }
}
catch {
    Write-Log "Failed to check wsl.exe in the system PATH.`nReason:`n$_" -Fail
    exit 1
}

# Install/update
$isSuccess = $false
try {
    if (Test-WslInstallation) {
        # Install
        Write-Log "WSL is already installed." -Info
        $versions = Get-WslVersion
        if ($null -eq $versions.WslVersion) { $versions.WslVersion = "null" }
        if ($null -eq $versions.KernelVersion) { $versions.KernelVersion = "null" }
        Write-Log "WSL version: $($versions.WslVersion)" -Info
        Write-Log "Kernel version: $($versions.KernelVersion)" -Info

        Write-Log "Updating WSL..." -Info
        if (Update-Wsl) {
            Write-Log "WSL is up to date." -Success
        }
        else {
            Write-Log "WSL successfully updated." -Success
            $versions = Get-WslVersion
            if ($null -eq $versions.WslVersion) { $versions.WslVersion = "null" }
            if ($null -eq $versions.KernelVersion) { $versions.KernelVersion = "null" }
            Write-Log "WSL version: $($versions.WslVersion)" -Info
            Write-Log "Kernel version: $($versions.KernelVersion)" -Info
        }
        $isSuccess = $true
    }
    else {
        # Update
        Write-Log "WSL is not installed." -Info
        Write-Log "Installing WSL..." -Info
        Install-Wsl
        Write-Log "WSL successfully installed." -Success
        $versions = Get-WslVersion
        if ($null -eq $versions.WslVersion) { $versions.WslVersion = "null" }
        if ($null -eq $versions.KernelVersion) { $versions.KernelVersion = "null" }
        Write-Log "WSL version: $($versions.WslVersion)" -Info
        Write-Log "Kernel version: $($versions.KernelVersion)" -Info
        $isSuccess = $true
    }
    
    # Final check
    if (-not (Test-Wsl2Installation)) {
        $isSuccess = $false
    }
}
catch {
    Write-Log "Failed to check wsl.exe in the system PATH.`nReason:`n$_" -Fail
    exit 1
}

if ($isSuccess) {
    exit 0
}
exit 1
