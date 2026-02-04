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

# Checks if the trimmed version of the specified string is null or empty.
# Returns the trimmed string.
# Throws on fail.
function Assert-TrimStrIsNotNullOrEmpty {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        $Str,
        
        [string]$Name = "_variable_"
    )

    if ($null -eq $Str) {
        throw "[$Name] is null!"
    }
    if ($Str -isnot [string]) {
        throw "[$Name] is not a string!"
    }

    $Str = $Str.Trim()
    if ([string]::IsNullOrEmpty($Str)) {
        throw "[$Name] is empty!"
    }

    return $Str
}

# Checks if the trimmed version of the specified server address is reachable on port 1433.
# Returns the trimmed address string.
# Throws on fail.
function Assert-TrimStrIsValidServerAddress {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        $Server,
        
        [string]$Name = "_variable_"
    )

    $Server = Assert-TrimStrIsNotNullOrEmpty $Server -Name $Name
    
    # if (-not (Test-NetConnection -ComputerName $Server -Port 1433 -InformationLevel Quiet -WarningAction SilentlyContinue 6>$null)) {
    #     throw "Cannot reach SQL Server at [$Server] on port 1433!"
    # }
    $tcpClient = New-Object System.Net.Sockets.TcpClient
    $connect = $tcpClient.BeginConnect($Server, 1433, $null, $null)
    $wait = $connect.AsyncWaitHandle.WaitOne(2000)
    if (-not $wait -or -not $tcpClient.Connected) {
        $tcpClient.Close()
        throw "Cannot reach SQL Server at [$Server] on port 1433!"
    }
    $tcpClient.Close()

    return $Server
}

# Checks if the trimmed version of the specified value can be cast into a positive float.
# Returns the trimmed string.
# Throws on fail.
function Assert-TrimStrIsPositiveFloat {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        $Value,
        
        [string]$Name = "_variable_"
    )

    $Value = Assert-TrimStrIsNotNullOrEmpty $Value -Name $Name
    $floatValue = 0.0
    if (-not [double]::TryParse($Value, [ref]$floatValue) -or $floatValue -lt 0.0) {
        throw "Invalid [$Name] value [$Value]. Needs to be a positive float."
    }

    return $Value
}

# Checks if the trimmed version of the specified value can be cast into an optionally prefixed int.
# Returns the trimmed string.
# Throws on fail.
function Assert-TrimStrIsPrefixedInt {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        $Value,
        
        [string]$Name = "_variable_"
    )

    $Value = Assert-TrimStrIsNotNullOrEmpty $Value -Name $Name
    if ($Value -notmatch "^[+-]?\d+$") {
        throw "Invalid [$Name] value [$Value]. Needs to be an integer, optionally prefixed with + or -."
    }

    return $Value
}

# Checks if the trimmed version of the specified value is a valid account type (0, 128, 256).
# Returns the trimmed string.
# Throws on fail.
function Assert-TrimStrIsValidAccountType {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        $Value,
        
        [string]$Name = "_variable_"
    )

    $Value = Assert-TrimStrIsNotNullOrEmpty $Value -Name $Name
    if ($AccountType -ne "0" -and
        $AccountType -ne "128" -and
        $AccountType -ne "256") {
        throw "Invalid [$Name]. Needs to be one of [0, 128, 256]."
    }

    return $Value
}

Export-ModuleMember -Function *
