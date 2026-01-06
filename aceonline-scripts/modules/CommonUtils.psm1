# Simple function to prompt a message in red and exit with status code 1.
function Stop-ScriptWithErrorMessage {
    param (
        [Parameter(Mandatory = $true)]
        $msg
    )

    Write-Host $msg -ForegroundColor Red
    exit 1
}

Export-ModuleMember -Function Stop-ScriptWithErrorMessage
