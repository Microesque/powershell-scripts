<#
.SYNOPSIS
Writes a formatted step title to the console.

.DESCRIPTION
Writes a formatted step header to the console by surrounding the message
with brackets and padding it with '=' characters to create a visual divider
for the logs.
#>
function Write-StepTitle {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateLength(1, 80)]
        [string]$Message
    )

    $Message = "[$Message]".PadRight(80, '=')
    Write-Host "`n$Message`n"
}

<#
.SYNOPSIS
Writes a formatted log message to the console.

.DESCRIPTION
Writes a message to the host with a prefixed indicator and color based on log
type. Supported log types: -Success, -Fail, -Warning, -Info
If no switch is provided, defaults to Info.
#>
function Write-Log {
    [CmdletBinding(DefaultParameterSetName = "Info")]
    param (
        [Parameter(ParameterSetName = "Success")] [switch]$Success,
        [Parameter(ParameterSetName = "Fail")]    [switch]$Fail,
        [Parameter(ParameterSetName = "Warning")] [switch]$Warning,
        [Parameter(ParameterSetName = "Info")]    [switch]$Info,

        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string]$Message
    )

    switch ($PSCmdlet.ParameterSetName) {
        "Success" { Write-Host "[/] $Message" -ForegroundColor Green }
        "Fail" { Write-Host "[!] $Message" -ForegroundColor Red }
        "Warning" { Write-Host "[?] $Message" -ForegroundColor Yellow }
        Default { Write-Host "[i] $Message" -ForegroundColor Magenta }
    }
}

Export-ModuleMember -Function *
