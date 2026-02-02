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
        throw "$Name is null!"
    }
    if ($Str -isnot [string]) {
        throw "$Name is not a string!"
    }

    $Str = $Str.Trim()
    if ([string]::IsNullOrEmpty($Str)) {
        throw "$Name is empty!"
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
        throw "Invalid $Name value [$Value]. Needs to be a positive float."
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
        throw "Invalid $Name value [$Value]. Needs to be an integer, optionally prefixed with + or -."
    }

    return $Value
}

# Fetches and returns a single value from the specified table, column, and condition.
# If the condition returns multiple rows and/or columns, the top left most value will be returned.
# If the condition returns no rows, $null will be returned.
# Throws if something goes wrong.
# Returns the fetched value.
function Get-TableColumnValue {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$Server,

        [Parameter(Mandatory)]
        [string]$Username,

        [Parameter(Mandatory)]
        [string]$Password,

        [Parameter(Mandatory)]
        [string]$Table,

        [Parameter(Mandatory)]
        [string]$Column,

        [Parameter()]
        [string]$WhereCondition = $null
    )

    $connectionString = "Server=$Server,1433;Database=master;User ID=$Username;Password=$Password;"
    $query = "SELECT TOP (1) $Column FROM $Table"
    if (-not [string]::IsNullOrEmpty($WhereCondition)) {
        $query += " WHERE $WhereCondition"
    }

    $connection = New-Object System.Data.SqlClient.SqlConnection $connectionString
    $command = $connection.CreateCommand()
    $command.CommandText = $query

    try {
        $connection.Open()
        $result = $command.ExecuteScalar()
    }
    catch {
        throw "$($_.Exception.Message)`n-----`nServer: $Server`nUsername: $Username`nQuery: $query"
    }
    finally {
        $connection.Close() # Silently fails if already closed
    }

    return $result
}

# Sets the values of the specified table, column, and condition.
# If the condition selects multiple entries, all of their column values will be set.
# Throws if something goes wrong.
# Returns the number of rows affected.
function Set-TableColumnValues {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$Server,

        [Parameter(Mandatory)]
        [string]$Username,

        [Parameter(Mandatory)]
        [string]$Password,

        [Parameter(Mandatory)]
        [string]$Table,

        [Parameter(Mandatory)]
        [string]$Column,

        [Parameter(Mandatory)]
        [string]$Value,

        [Parameter()]
        [string]$WhereCondition = $null
    )

    $connectionString = "Server=$Server,1433;Database=master;User ID=$Username;Password=$Password;"
    $query = "UPDATE $Table SET $Column = $Value"
    if (-not [string]::IsNullOrEmpty($WhereCondition)) {
        $query += " WHERE $WhereCondition"
    }

    $connection = New-Object System.Data.SqlClient.SqlConnection $connectionString
    $command = $connection.CreateCommand()
    $command.CommandText = $query

    try {
        $connection.Open()
        $result = $command.ExecuteNonQuery()
    }
    catch {
        throw "$($_.Exception.Message)`n-----`nServer: $Server`nUsername: $Username`nQuery: $query"
    }
    finally {
        $connection.Close() # Silently fails if already closed
    }

    return $result
}

Export-ModuleMember -Function *
