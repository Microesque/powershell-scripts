<#
.SYNOPSIS
Installs and configures a WSL2 Debian distribution for the current system.

.DESCRIPTION
Installs a WSL2 Debian distribution for the current system, then performs the
standard apt update/upgrade and clean ups and create a default user with the
credentials:

.DESCRIPTION
Installs a WSL2 Debian distribution for the current system, then performs a
standard apt update, upgrade, and cleanup. Finally, creates a default user with
the following credentials:
    Username: asd
    Password: asd
    
This script must be executed with administrative privileges.

.OUTPUTS
None. Prints informational messages to the host. Intended to be used with the
exit code. Exitcode:
    0 -> Debian WSL2 distribution was successfully installed and initialized.
    1 -> Installation or configuration failed, or the distribution is already
         installed.

.NOTES
- Requires the .psm1 files in the `/modules` directory.
- Default WSL version will be set to WSL2.
- If a Debian installation already exists, the script will fail with exitcode 1.
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
$distro = "Debian"
$defaultUser = "asd"
$defaultPassword = "asd"

Write-StepTitle "Initializing WSL2 '$distro'"

# Check for an existing installation
try {
    if (Test-WSLDistroInstallation $distro) {
        Write-Log "Distribution [$distro] is already installed in WSL." -Fail
        exit 1
    }
}
catch {
    Write-Log "Failed to retrieve the list of installed WSL distributions.`nReason:`n$_" -Fail
    exit 1
}

# Update WSL default version to WSL2
try {
    $version = Get-WslDefaultVersion
    if ($version -eq 2) {
        Write-Log "WSL default version is already set to WSL2." -Success
    }
    else {
        Write-Log "Current default WSL version: WSL$version" -Info
        Update-Wsl2AsDefault
        if (Get-WslDefaultVersion -eq 2) {
            Write-Log "WSL default version is now set to WSL2." -Success
        }
        else {
            Write-Log "WSL default version was set to WSL2, but changes did not take effect." -Fail
            exit 1
        }
    }
}
catch {
    Write-Log "Failed to set the default WSL version to WSL2.`nReason:`n$_" -Fail
    exit 1
}

# Install the distro
try {
    Write-Log "Installing WSL distribution [$distro]..." -Info
    Install-WSLDistro $distro
    Write-Log "WSL distribution [$distro] installed successfully." -Success
}
catch {
    Write-Log "Failed to install WSL distribution [$distro].`nReason:`n$_" -Fail
    exit 1
}

Write-StepTitle "Post-install configuration for '$distro'"

# Create a default user
try {
    Write-Log "Setting up the default user..." -Info
    Invoke-WSLRootCommand `
        -Distro $distro `
        -Command "adduser --disabled-password --gecos '' $defaultUser; echo '${defaultUser}:${defaultPassword}' | chpasswd; usermod -aG sudo $defaultUser"
    Write-Log "User [$defaultUser] with the password [$defaultPassword] created." -Success

    Invoke-WSLRootCommand `
        -Distro $distro `
        -Command "printf '[user]\ndefault=$defaultUser\n' > /etc/wsl.conf"
    Write-Log "User [$defaultUser] is now set as the default user for the distribution [$distro]." -Success
}
catch {
    Write-Log "Failed to create default user.`nReason:`n$_" -Fail
    exit 1
}

# Initialize distro packages
try {
    Write-Log "Updating and upgrading [$distro] packages..." -Info
    Invoke-WSLRootCommand `
        -Distro $distro `
        -Command "set -e; apt update; apt upgrade -y"

    Write-Log "Cleaning up packages..." -Info
    Invoke-WSLRootCommand `
        -Distro $distro `
        -Command "set -e; apt autoremove -y; apt clean"

    Write-Log "Initializing [$distro] packages successful." -Success
}
catch {
    Write-Log "Failed to initialize [$distro] packages.`nReason:`n$_" -Fail
    exit 1
}
