# Invokes an sql statement as non-query and returns the number of rows affected.
# Throws if something goes wrong.
# Returns the number of rows affected.
function Invoke-SqlExecuteNonQuery {
    param (
        [Parameter(Mandatory)]
        [string]$ConnectionString,

        [Parameter(Mandatory)]
        [string]$Query
    )

    try {
        $connection = New-Object System.Data.SqlClient.SqlConnection
        $connection.ConnectionString = $ConnectionString
        $connection.Open()
    }
    catch {
        $connection.Close()
        throw "Database connection failed to open:`n$_"
    }

    try {
        $command = $connection.CreateCommand()
        $command.CommandText = $Query
        $rowsAffected = $command.ExecuteNonQuery()
    }
    catch {
        throw "Failed executing the query:`n$_"
    }
    finally {
        $connection.Close()
    }

    return $rowsAffected
}

# Invokes the given query and returns the first row and first column value.
# Throws if something goes wrong.
# Returns a single value.
function Invoke-SqlExecuteScalar {
    param (
        [Parameter(Mandatory)]
        [string]$ConnectionString,

        [Parameter(Mandatory)]
        [string]$Query
    )

    try {
        $connection = New-Object System.Data.SqlClient.SqlConnection
        $connection.ConnectionString = $ConnectionString
        $connection.Open()
    }
    catch {
        $connection.Close()
        throw "Database connection failed to open:`n$_"
    }

    try {
        $command = $connection.CreateCommand()
        $command.CommandText = $Query
        $rowsAffected = $command.ExecuteScalar()
    }
    catch {
        throw "Failed executing the query:`n$_"
    }
    finally {
        $connection.Close()
    }

    return $rowsAffected
}

Export-ModuleMember -Function Invoke-SqlExecuteNonQuery, Invoke-SqlExecuteScalar
