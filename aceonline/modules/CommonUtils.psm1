# Simple function to prompt a message in red and exit with status code 1.
function Stop-ScriptWithErrorMessage {
    param (
        [Parameter(Mandatory = $true)]
        $msg
    )

    Write-Host $msg -ForegroundColor Red
    exit 1
}

# Very basic validation for IPv4 addresses. Doesn't check for localhost.
function Test-ServerIP {
    param (
        [Parameter(Mandatory = $true)]
        $Ip
    )
    $Ip -match "^(?:[0-9]{1,3}\.){3}[0-9]{1,3}$"
}

Export-ModuleMember -Function Stop-ScriptWithErrorMessage, Test-ServerIP
