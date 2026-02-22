<#
.SYNOPSIS
Checks whether the system meets the software requirements for WSL2.

.DESCRIPTION
Performs a series of software compatibility checks for Windows Subsystem for
Linux (WSL2) and logs the results.

Checks performed:
- Checks if the OS is Windows (immediately returns $false if not).
- Checks Windows Build number (19041+ required).
- Checks the state of "VirtualMachinePlatform" Windows Feature.
- Checks the state of "Microsoft-Windows-Subsystem-Linux" Windows Feature.

.OUTPUTS
[bool]
Returns $true if all requirements are met, otherwise $false.
#>
function Test-Wsl2SoftwareRequirements {
    [CmdletBinding()]
    param()

    $result = $true

    # Check non-windows systems
    if ($PSVersionTable.PSVersion.Major -ge 6) {
        if (-not $IsWindows) {
            Write-Log "WSL2 requirements can only be checked on Windows." -Fail
            return $false
        }
    }

    # Log OS name
    $osCaption = (Get-CimInstance Win32_OperatingSystem).Caption
    Write-Log "OS Name: $osCaption" -Info

    # Check OS build number, WSL2 requires build 19041+
    $build = (Get-CimInstance Win32_OperatingSystem).BuildNumber
    if ([int]$Build -ge 19041) {
        Write-Log "Windows build: $build -> Compatible with WSL2." -Success 
    }
    else {
        Write-Log "Windows build: $build -> Not compatible with WSL2. Requires build 19041+." -Fail
        $result = $false
    }

    # Check VMP windows feature
    $vmp = Get-WindowsOptionalFeature -Online -FeatureName "VirtualMachinePlatform"
    if ($vmp.State -eq "Enabled") {
        Write-Log "Virtual Machine Platform (VMP) is enabled." -Success
    }
    else {
        Write-Log (
            "Virtual Machine Platform (VMP) is disabled. WSL2 will not work." +
            " Enable Virtual Machine Platform (VMP) and restart your computer."
        ) -Fail
        $result = $false
    }

    # Check WSL windows feature (only for WSL1, WSL2 doesn't require this)
    $wsl = Get-WindowsOptionalFeature -Online -FeatureName "Microsoft-Windows-Subsystem-Linux"
    if ($wsl.State -eq "Enabled") {
        Write-Log "`"Windows Subsystem for Linux`" optional feature is enabled. WSL1 is also supported on this computer." -Success
    }
    else {
        Write-Log "`"Windows Subsystem for Linux`" optional feature is disabled. WSL1 is not supported on this computer." -Warning
    }
    
    return $result
}

<#
.SYNOPSIS
Checks whether the system meets the hardware requirements for WSL2.

.DESCRIPTION
Performs a series of hardware compatibility checks for Windows Subsystem for
Linux (WSL2) and logs the results.

Checks performed:
- Checks for an active hypervisor (immediately returns $true if Hyper-V is active).
- Checks CPU support for hardware virtualization (VT-x/AMD-V).
- Checks CPU support for Second Level Address Translation (SLAT).
- Checks the state of hardware virtualization in BIOS/UEFI settings.

.OUTPUTS
[bool]
Returns $true if all requirements are met, otherwise $false.
#>
function Test-Wsl2HardwareRequirements {
    [CmdletBinding()]
    param()

    # Log CPU and motherboard
    $processorNames = (Get-CimInstance Win32_Processor).Name -join " && "
    $motherboardModel = (Get-CimInstance Win32_ComputerSystem).Model
    Write-Log "Processor Name(s): $processorNames" -Info
    Write-Log "Motherboard Model: $motherboardModel" -Info

    # Check for an active hypervisor, return if hyper-v is active
    if ((Get-CimInstance Win32_ComputerSystem).HypervisorPresent) {
        Write-Log "Running hypervisor detected on the system." -Info
        $hypervInfo = Get-CimInstance -ClassName "Win32_PerfRawData_HvStats_HyperVHypervisor" -ErrorAction SilentlyContinue
        if ($hypervInfo) {
            Write-Log "Hypervisor detected. Hyper-V is active and WSL2 can run." -Success
            return $true
        } 
        Write-Log "Hypervisor detected. It is likely not Hyper-V and could prevent WSL2 from running." -Fail
        return $false
    }
    Write-Log "No hypervisor detected. If the checks below are green, you may need to restart your computer." -Fail

    # Run computerinfo without progress bar
    $oldProgressPreference = $ProgressPreference
    try {
        $ProgressPreference = 'SilentlyContinue'
        $computerInfo = Get-ComputerInfo -Property 'HyperVRequirement*'
    }
    finally {
        $ProgressPreference = $oldProgressPreference
    }

    # Check CPU support
    if ($computerInfo.HyperVRequirementVMMonitorModeExtensions) {
        Write-Log "CPU supports hardware virtualization (VT-x/AMD-V)." -Success
    }
    else {
        Write-Log "CPU does not support hardware virtualization (VT-x/AMD-V). WSL2 cannot run on this system." -Fail
    }

    # Check SLAT
    if ($computerInfo.HyperVRequirementSecondLevelAddressTranslation) {
        Write-Log "CPU supports Second Level Address Translation (SLAT)." -Success
    }
    else {
        Write-Log "CPU does not support Second Level Address Translation (SLAT). WSL2 cannot run on this system." -Fail
    }

    # Check BIOS setting
    if ($computerInfo.HyperVRequirementVirtualizationFirmwareEnabled) {
        Write-Log "Hardware virtualization is enabled in BIOS/UEFI." -Success
    }
    else {
        Write-Log "Hardware virtualization is disabled in BIOS/UEFI. Enable it to use WSL2." -Fail
    }

    return $false
}

<#
.SYNOPSIS
Checks whether wsl.exe is available in the system PATH.

.OUTPUTS
[bool]
Returns $true if wsl.exe is found in the system PATH; otherwise $false.
#>
function Test-WslExecutable {
    [CmdletBinding()]
    param()

    if (-not (Get-Command wsl.exe -ErrorAction SilentlyContinue)) {
        Write-Log "wsl.exe not found in the system PATH." -Fail
        return $false
    }
    return $true
}

<#
.SYNOPSIS
Checks whether WSL is installed and functional.

.DESCRIPTION
Invokes wsl.exe -status to verify that the executable is operating correctly and
is returning a successful exit code.

.OUTPUTS
[bool]
Returns $true if WSL is installed and operational; otherwise $false.
#>
function Test-WslInstallation {
    [CmdletBinding()]
    param()
    
    $null = & wsl.exe --status 2>$null
    if ($LASTEXITCODE -ne 0) {
        Write-Log "WSL is not currently installed, or the version may be too old." -Fail
        return $false
    }
    Write-Log "WSL is currently installed." -Success
    return $true
}

<#
.SYNOPSIS
Logs the installed WSL version.

.DESCRIPTION
Invokes wsl.exe --version to retrieve version information. Evaluates the exit
code to determine success. Assumes that wsl.exe is available in the system PATH.
#>
function Write-WslVersion {
    [CmdletBinding()]
    param()
    
    $lines = & wsl.exe --version 2>$null
    $msg = $lines |
    ForEach-Object { $_ -replace "`0", "" } |
    Where-Object { $_ -match "WSL version:|Kernel version:" }
    if ($msg) {
        $msg | ForEach-Object { Write-Log $_ -Info }
    }
    else {
        Write-Log "WSL version information not available." -Info
    }
}

<#
.SYNOPSIS
Attempts to update WSL to the latest version.

.DESCRIPTION
Executes wsl.exe --update to initiate the update. Evaluates the exit code to
determine success. Assumes that wsl.exe is available in the system PATH.

.OUTPUTS
[bool]
Returns $true if update was successful; otherwise $false.
#>
function Update-Wsl {
    $lines = & wsl.exe --update 2>&1
    $output = ($lines -join "`n").Replace("`0", "")
    if ($LASTEXITCODE -ne 0) {
        Write-Log "WSL update failed with exit code $LASTEXITCODE. Output:`n$output" -Fail
        return $false
    }

    if ($output -match "already") {
        Write-Log "WSL is up to date." -Success
    }
    else {
        Write-Log "WSL successfully updated." -Success
    }

    return $true
}

<#
.SYNOPSIS
Attempts to install WSL.

.DESCRIPTION
Executes wsl.exe --install to initiate the installation. Evaluates the exit code
to determine success. Assumes that wsl.exe is available in the system PATH.

.OUTPUTS
[bool]
Returns $true if installation was successful; otherwise $false.
#>
function Install-Wsl {
    Write-Log "Installing WSL..." -Info
    $lines = & wsl.exe --install --no-distribution 2>&1
    if ($LASTEXITCODE -ne 0) {
        $output = ($lines -join "`n").Replace("`0", "")
        Write-Log "WSL installation failed with exit code $LASTEXITCODE. Output:`n$output" -Fail
        return $false
    }
    Write-Log "WSL installed successfully." -Success

    return $true
}

<#
.SYNOPSIS
Attempts to set the default WSL version to WSL2.

.DESCRIPTION
Executes wsl.exe --set-default-version 2 to set WSL2 as the default version.
Evaluates the exit code to determine success. Assumes that wsl.exe is available
in the system PATH.

.OUTPUTS
[bool]
Returns $true if setting was successful; otherwise $false.
#>
function Update-Wsl2AsDefault {
    $lines = & wsl.exe --set-default-version 2 2>&1  # This command is idempotent
    if ($LASTEXITCODE -ne 0) {
        $output = ($lines -join "`n").Replace("`0", "")
        Write-Log "Setting default WSL version to WSL2 failed with exit code $LASTEXITCODE. Output:`n$output" -Fail
        return $false
    }
    Write-Log "Default WSL version is now set to WSL2." -Success

    return $true
}

Export-ModuleMember -Function *
