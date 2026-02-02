# Reads a secure string from the user and returns it as a normal string.
function Read-SecureStringAsString {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Prompt
    )
    $input = Read-Host $Prompt -AsSecureString
    return [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($input))
}

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
