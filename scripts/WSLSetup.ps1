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

# ==============================================================================
# =================================== SCRIPT ===================================
# ==============================================================================

Test-SoftwareRequirements

Stop-ScriptAfterKeyPress
