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
