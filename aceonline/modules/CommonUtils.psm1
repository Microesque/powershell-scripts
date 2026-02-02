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

Export-ModuleMember -Function *
