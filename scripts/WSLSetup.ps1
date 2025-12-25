# ==============================================================================
# =============================== Self Elevation ===============================
# ==============================================================================
$CurrentPrincipal = New-Object Security.Principal.WindowsPrincipal $([Security.Principal.WindowsIdentity]::GetCurrent())
$Admin = [Security.Principal.WindowsBuiltinRole]::Administrator
if (-not $CurrentPrincipal.IsInRole($Admin)) {
    Start-Process Powershell.exe -Verb RunAs -ArgumentList "-file `"$($myinvocation.MyCommand.Definition)`""
    exit
}

# ==============================================================================
# ================================== FUNCTIONS =================================
# ==============================================================================
# Custom fucntion for exiting the script.
function Stop-ScriptAfterKeyPress {
    Write-Host "`nExecution stopped. Press any key to exit."
    $null = $Host.UI.RawUI.ReadKey("NoEcho, IncludeKeyDown")
    exit
}

# Formats and prints the title (max. 80 chars).
function Write-StepTitle {
    param (
        [Parameter(Mandatory = $true)]
        [string]$msg
    )

    $maxLength = 80
    if ($msg.Length -gt $maxLength) {
        throw "Step title message too long (max. $maxLength chars) -> $($msg.Substring(0, 40))..."
    }

    $num = $maxLength - $msg.Length - 2
    if ($num -lt 0) {
        $num = 0
    }
    Write-Host "`n[$msg]$("=" * $num)`n"
}

# Custom printing function for formatting logging messages. Use one of:
# -Success
# -Fail
# -Warning
# -Info
function Write-Log {
    [CmdletBinding(DefaultParameterSetName = "Info")]
    param (
        [Parameter(ParameterSetName = "Success")] [switch]$Success,
        [Parameter(ParameterSetName = "Fail")]    [switch]$Fail,
        [Parameter(ParameterSetName = "Warning")] [switch]$Warning,
        [Parameter(ParameterSetName = "Info")]    [switch]$Info,

        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Message
    )
    
    switch ($PSCmdlet.ParameterSetName) {
        "Success" { Write-Host "[/] $Message" -ForegroundColor Green }
        "Fail" { Write-Host "[!] $Message" -ForegroundColor Red }
        "Warning" { Write-Host "[?] $Message" -ForegroundColor Yellow }
        Default { Write-Host "[i] $Message" -ForegroundColor Magenta }
    }
}

# Tests to see if software requirements for wsl installtion are met.
# Returns $true or $false
function Test-SoftwareRequirements {
    $Result = $true

    $osCaption = (Get-CimInstance Win32_OperatingSystem).Caption
    Write-Log "OS Name: $osCaption"-Info

    $Build = (Get-CimInstance Win32_OperatingSystem).BuildNumber
    if ([int]$Build -ge 19041) {
        Write-Log "Windows build: $Build -> Compatible with WSL2." -Success 
    }
    else {
        Write-Log "Windows build: $Build -> Not compatible with WSL2. Requires build 19041+." -Fail
        $Result = $false
    }

    $Vmp = Get-WindowsOptionalFeature -Online -FeatureName "VirtualMachinePlatform"
    if ($Vmp.State -eq "Enabled") {
        Write-Log "Virtual Machine Platform (VMP) is enabled." -Success
    }
    else {
        $Msg = "Virtual Machine Platform (VMP) is disabled. WSL2 will not work." +
        " Enable Virtual Machine Platform (VMP) and restart your computer."
        Write-Log $Msg -Fail
        $Result = $false
    }
    
    return $Result
}

# Tests to see if hardware requirements for wsl installtion are met.
# Returns $true or $false
function Test-HardwareRequirements {
    $processorNames = (Get-CimInstance Win32_Processor).Name -join " && "
    $motherboardModel = (Get-CimInstance Win32_ComputerSystem).Model
    Write-Log "Processor Name(s): $processorNames" -Info
    Write-Log "Motherboard Model: $motherboardModel" -Info

    if ((Get-CimInstance Win32_ComputerSystem).HypervisorPresent) {
        Write-Log "Running hypervisor detected on the system." -Info

        $hypervInfo = Get-CimInstance -ClassName "Win32_PerfRawData_HvStats_HyperVHypervisor" -ErrorAction SilentlyContinue
        if ($hypervInfo) {
            Write-Log "Hyper-V is active and WSL2 can run." -Success
            return $true
        }
        
        Write-Log "Detected hypervisor is likely not Hyper-V and could prevent WSL2 from running." -Fail
        return $false
    }

    Write-Log "No running hypervisor detected. If the checks below are green, you may need to restart your computer." -Fail

    $ProgressPreference = "SilentlyContinue"
    $computerInfo = Get-ComputerInfo -Property "HyperVRequirement*"
    $ProgressPreference = "Continue"

    
    if ($computerInfo.HyperVRequirementVMMonitorModeExtensions) {
        Write-Log "CPU supports hardware virtualization (VT-x/AMD-V)." -Success
    }
    else {
        Write-Log "CPU does not support hardware virtualization (VT-x/AMD-V). WSL2 cannot run on this system." -Fail
    }

    if ($computerInfo.HyperVRequirementSecondLevelAddressTranslation) {
        Write-Log "CPU supports Second Level Address Translation (SLAT)." -Success
    }
    else {
        Write-Log "CPU does not support Second Level Address Translation (SLAT). WSL2 cannot run on this system." -Fail
    }

    if ($computerInfo.HyperVRequirementVirtualizationFirmwareEnabled) {
        Write-Log "Hardware virtualization is enabled in BIOS/UEFI." -Success
    }
    else {
        Write-Log "Hardware virtualization is disabled in BIOS/UEFI. Enable it to use WSL2." -Fail
    }

    return $false
}

# Tests to see if wsl is already installed and updates it if possible.
# Returns $true or $false
function Test-WSLInstallation {
    # Check installation
    & wsl --version
    if ($LASTEXITCODE -ne 0) {
        Write-Log "WSL is not installed." -Fail
        return $false
    }
    Write-Log "WSL is installed." -Success

    # Update
    $lines = & wsl --update 2>&1
    $output = ($lines -join "`n").Replace("`0", "")
    if ($LASTEXITCODE -ne 0) {
        Write-Log "WSL update failed with exit code $LASTEXITCODE. Output:`n$output" -Fail
        return $false
    }

    if ($output -match "already installed.") {
        Write-Log "WSL is up to date." -Success
    }
    else {
        Write-Log "WSL updated." -Success
    }

    # Print version
    $lines = & wsl --version
    $lines |
        ForEach-Object { $_ -replace "`0", "" } |
        Where-Object { $_.Contains("WSL version:") } |
        ForEach-Object { Write-Log "$_" -Info }

    return $true
}

# ==============================================================================
# =================================== SCRIPT ===================================
# ==============================================================================
Clear-Host

Write-StepTitle "Checking for WSL installation"
Test-WSLInstallation

Write-StepTitle "Checking software requirements"
Test-SoftwareRequirements

Write-StepTitle "Checking hardware requirements"
Test-HardwareRequirements

Stop-ScriptAfterKeyPress
