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

# ============================= SOFTWARE REQUIREMENTS ==========================
Write-StepTitle "Checking software requirements"

# Check non-windows systems, exit if not windows
if ($PSVersionTable.PSVersion.Major -ge 6) {
    if (-not $IsWindows) {
        Write-Log "WSL2 requirements can only be checked on Windows." -Fail
        exit 1
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
    $exitCode = 1
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
    $exitCode = 1
}

# Check WSL windows feature (only for WSL1, WSL2 doesn't require this)
$wsl = Get-WindowsOptionalFeature -Online -FeatureName "Microsoft-Windows-Subsystem-Linux"
if ($wsl.State -eq "Enabled") {
    Write-Log "`"Windows Subsystem for Linux`" optional feature is enabled. WSL1 is also supported on this computer." -Success
}
else {
    Write-Log "`"Windows Subsystem for Linux`" optional feature is disabled. WSL1 is not supported on this computer." -Warning
}

# ============================= HARDWARE REQUIREMENTS ==========================
Write-StepTitle "Checking hardware requirements"

# Log CPU and motherboard
$processorNames = (Get-CimInstance Win32_Processor).Name -join " && "
$motherboardModel = (Get-CimInstance Win32_ComputerSystem).Model
Write-Log "Processor Name(s): $processorNames" -Info
Write-Log "Motherboard Model: $motherboardModel" -Info

# Check for an active hypervisor, exit if hyper-v is active
# (When any hypervisor is active all checks return null)
if ((Get-CimInstance Win32_ComputerSystem).HypervisorPresent) {
    Write-Log "Running hypervisor detected on the system." -Info
    $hypervInfo = Get-CimInstance -ClassName "Win32_PerfRawData_HvStats_HyperVHypervisor" -ErrorAction SilentlyContinue
    if ($hypervInfo) {
        Write-Log "Hypervisor detected. Hyper-V is active and WSL2 can run." -Success
        exit $exitCode
    }
    Write-Log "Hypervisor detected. It is likely not Hyper-V and could prevent WSL2 from running." -Fail
    exit 1
}
Write-Log "No hypervisor detected. If the checks below are successful, you may need to restart your computer." -Info

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

exit $exitCode
