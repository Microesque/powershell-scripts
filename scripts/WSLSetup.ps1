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

# ==============================================================================
# =================================== SCRIPT ===================================
# ==============================================================================
