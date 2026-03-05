<#
.SYNOPSIS
Provides general-purpose utility functions and standardized console output for
scripts.

.DESCRIPTION
This module contains a set of reusable helper functions for common scripting
tasks. Also includes functions to produce standardized output to the console for
uniform presentation of scripts.
#>

# ==============================================================================
# ==============================================================================
# ==============================================================================

<#
.SYNOPSIS
Prompts the user for a secure string and returns it as a plain text string.

.DESCRIPTION
Prompts the user to enter a secure string using `Read-Host -AsSecureString`.
Converts the secure string into a standard string and returns it.

.PARAMETER Prompt
The message displayed to the user when requesting input.

.OUTPUTS
[string]
Returns the plain text version of the entered secure string.
#>
function Read-SecureStringAsString {
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Prompt
    )

    $input = Read-Host $Prompt -AsSecureString
    return [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($input))
}

<#
.SYNOPSIS
Validates that a string is not null or empty after trimming.

.DESCRIPTION
Checks whether the provided value is a non-null string and that its trimmed
version is not empty. If the value is null, not a string, or empty after
trimming, an exception is thrown. Otherwise, the trimmed string is returned.

.PARAMETER Str
The string value to validate.

.PARAMETER Name
(Optional) A name to include in error messages for clarity.

.OUTPUTS
[string]
Returns the trimmed string if validation succeeds.

.NOTES
Throws an exception if the string is null, empty, or not of type string.
#>
function Assert-TrimStrIsNotNullOrEmpty {
    [CmdletBinding()]
    [OutputType([string])]
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

<#
.SYNOPSIS
Validates that a server address is non-empty and reachable on port 1433.

.DESCRIPTION
Checks whether the provided server address is non-null and non-empty after
trimming. Then tests TCP connectivity to the server on port 1433. If the
server cannot be reached or the input is invalid, an exception is thrown.
Returns the trimmed server address if validation succeeds.

.PARAMETER Server
The server address to validate.

.PARAMETER Name
(Optional) A name to include in error messages for clarity.

.OUTPUTS
[string]
Returns the trimmed server address if validation succeeds.

.NOTES
Uses a TCP connection attempt with a 2-second timeout to test connectivity.
Throws an exception on failure.
#>
function Assert-TrimStrIsValidServerAddress {
    [CmdletBinding()]
    [OutputType([string])]
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

<#
.SYNOPSIS
Validates that a value is a positive integer.

.DESCRIPTION
Checks whether the specified value can be converted into a positive integer.
Trims the value first, and throws an exception if it is null, empty, not a
string, or not a positive integer. Returns the trimmed string if validation succeeds.

.PARAMETER Value
The value to validate.

.PARAMETER Name
(Optional) A name to include in error messages for clarity.

.OUTPUTS
[string]
Returns the trimmed string representing a valid positive integer.

.NOTES
Zero is considered a valid positive integer.
#>
function Assert-TrimStrIsPositiveInt {
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(Mandatory = $true)]
        $Value,
        
        [string]$Name = "_variable_"
    )

    $Value = Assert-TrimStrIsNotNullOrEmpty $Value -Name $Name
    [int]$intValue = 0
    if (-not [int]::TryParse($Value, [ref]$intValue) -or $intValue -lt 0) {
        throw "Invalid [$Name] value [$Value]. Needs to be a positive int."
    }

    return $Value
}

<#
.SYNOPSIS
Validates that a value is a positive floating-point number.

.DESCRIPTION
Checks whether the specified value can be converted into a positive float.
Trims the value first, and throws an exception if it is null, empty, not a
string, or less than zero. Returns the trimmed string if validation succeeds.

.PARAMETER Value
The value to validate.

.PARAMETER Name
(Optional) A name to include in error messages for clarity.

.OUTPUTS
[string]
Returns the trimmed string representing a valid positive float.

.NOTES
Zero is considered valid.
#>
function Assert-TrimStrIsPositiveFloat {
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(Mandatory = $true)]
        $Value,
        
        [string]$Name = "_variable_"
    )

    $Value = Assert-TrimStrIsNotNullOrEmpty $Value -Name $Name
    [double]$floatValue = 0.0
    if (-not [double]::TryParse($Value, [ref]$floatValue) -or $floatValue -lt 0.0) {
        throw "Invalid [$Name] value [$Value]. Needs to be a positive float."
    }

    return $Value
}

<#
.SYNOPSIS
Validates that a value is an integer, optionally prefixed with + or -.

.DESCRIPTION
Checks whether the specified value can be cast to an integer and allows an
optional '+' or '-' prefix. Trims the value first and throws an exception if
it is null, empty, not a string, or does not match the required integer format.
Returns the trimmed string if validation succeeds.

.PARAMETER Value
The value to validate.

.PARAMETER Name
(Optional) A name to include in error messages for clarity.

.OUTPUTS
[string]
Returns the trimmed string representing a valid optionally prefixed integer.
#>
function Assert-TrimStrIsPrefixedInt {
    [CmdletBinding()]
    [OutputType([string])]
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

<#
.SYNOPSIS
Validates that a value is a valid account type (0, 128, or 256).

.DESCRIPTION
Checks whether the provided value matches one of the allowed account types:
0, 128, or 256. Trims the value first and throws an exception if the value
is null, empty, not a string, or does not match one of the valid account types.
Returns the trimmed string if validation succeeds.

.PARAMETER Value
The account type value to validate.

.PARAMETER Name
(Optional) A name to include in error messages for clarity.

.OUTPUTS
[string]
Returns the trimmed string representing a valid account type.
#>
function Assert-TrimStrIsValidAccountType {
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(Mandatory = $true)]
        $Value,
        
        [string]$Name = "_variable_"
    )

    $Value = Assert-TrimStrIsNotNullOrEmpty $Value -Name $Name
    if ($Value -ne "0" -and
        $Value -ne "128" -and
        $Value -ne "256") {
        throw "Invalid [$Name]. Needs to be one of [0, 128, 256]."
    }

    return $Value
}

Export-ModuleMember -Function *
