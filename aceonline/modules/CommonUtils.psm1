# Function to prompt a message in red and exit with status code 1.
function Stop-ScriptWithErrorMessage {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        $Msg
    )

    Write-Host $Msg -ForegroundColor Red
    exit 1
}

# Function to prompt a message in green and exit with status code 0.
function Stop-ScriptWithSuccessMessage {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        $Msg
    )

    Write-Host $Msg -ForegroundColor Green
    exit 0
}

Export-ModuleMember -Function *
