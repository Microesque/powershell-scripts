# Queries the user for a server ip, username, and password.
# Inputs are validated and trimmed. Server value can be 'localhost'.
# Throws if validation goes wrong.
# Returns -> @(serverIP, $username, $password)
function Read-ServerAndCredentials {
    [CmdletBinding()]
    param()

    $server = (Read-Host "Enter SQL server ip (leave empty for 'localhost')").Trim()
    if ([string]::IsNullOrEmpty($server)) {
        $server = "localhost"
    }
    elseif ($server -notmatch "^(?:[0-9]{1,3}\.){3}[0-9]{1,3}$") {
        throw "Invalid SQL server IP: $server"
    }

    $username = (Read-Host "Enter SQL username").Trim()
    if ([string]::IsNullOrEmpty($username)) {
        throw "Empty SQL username!"
    }

    $password = Read-Host "Enter SQL password" -AsSecureString
    $password = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($password)).Trim()
    
    if ([string]::IsNullOrEmpty($password)) {
        throw "Empty SQL password!"
    }

    return @($server, $username, $password)
}

# Fetches and returns a single value from the specified table, column, and condition.
# If the condition returns multiple rows and/or columns, the top left most value will be returned.
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

    $connectionString = "Server=$Server;Database=master;User ID=$Username;Password=$Password;"
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
        throw "$($_.Exception.Message)`nQuery was: $query"
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

    $connectionString = "Server=$Server;Database=master;User ID=$Username;Password=$Password;"
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
        throw "$($_.Exception.Message)`nQuery was: $query"
    }
    finally {
        $connection.Close() # Silently fails if already closed
    }

    return $result
}

Export-ModuleMember -Function *
