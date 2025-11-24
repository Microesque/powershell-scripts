
# ==============================================================================
# =============================== Self Elevation ===============================
# ==============================================================================
$CurrentPrincipal = New-Object Security.Principal.WindowsPrincipal $([Security.Principal.WindowsIdentity]::GetCurrent())
$Admin = [Security.Principal.WindowsBuiltinRole]::Administrator
if (-not $CurrentPrincipal.IsInRole($Admin)) {
    Start-Process Powershell.exe -Verb RunAs -ArgumentList "-file `"$($myinvocation.MyCommand.Definition)`""
    exit
}
