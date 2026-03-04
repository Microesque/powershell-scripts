<#
.SYNOPSIS
Provides utility functions for interacting with MSSQL servers.

.DESCRIPTION
This module contains functions to manage, query, and perform operations related
to Microsoft SQL Server (MSSQL). Functions include creating connections, making
queries, and updating tables.
#>

# ==============================================================================
# ==============================================================================
# ==============================================================================

<#
.SYNOPSIS
Creates a Microsoft SQL Server connection object.

.DESCRIPTION
Constructs and returns a [System.Data.SqlClient.SqlConnection] object using
the specified parameters.

The connection string is explicitly configured to:
- Use SQL authentication (Windows authentication is disabled)
- Use TCP port 1433
- Connect to the "master" database

This function does not open the connection. The caller is responsible for
opening and disposing of the connection object.

.PARAMETER ServerAddress
The DNS name or IP address of the SQL Server instance. Do not include the port
number; TCP port 1433 is always used.

.PARAMETER Credential
A [PSCredential] object containing the SQL Server username and password.

.OUTPUTS
[System.Data.SqlClient.SqlConnection]
Returns the SQL connection object. The connection is not yet opened.
#>
function Get-MSSQLConnection {
    [CmdletBinding()]
    [OutputType([System.Data.SqlClient.SqlConnection])]
    param (
        [Parameter(Mandatory)]
        [string]$ServerAddress,

        [Parameter(Mandatory)]
        [PSCredential]$Credential
    )
    $Builder = New-Object System.Data.SqlClient.SqlConnectionStringBuilder
    $Builder["Server"] = "$ServerAddress,1433" # Port 1433 only
    $Builder["Database"] = "master"
    $Builder["User ID"] = $Credential.UserName
    $Builder["Password"] = $Credential.GetNetworkCredential().Password

    $connection = New-Object System.Data.SqlClient.SqlConnection($Builder.ConnectionString)
    $Builder.Clear()
    return $connection
}

<#
.SYNOPSIS
Returns a scalar value from a Microsoft SQL Server query.

.DESCRIPTION
Executes a SELECT statement against the specified table and column and returns
the first value from the result set.

The connection string is explicitly configured to:
- Use SQL authentication (Windows authentication is disabled)
- Use TCP port 1433
- Connect to the "master" database

.PARAMETER ServerAddress
The DNS name or IP address of the SQL Server instance. Do not include the port
number; TCP port 1433 is always used.

.PARAMETER Credential
A [PSCredential] object containing the SQL Server username and password.

.PARAMETER Table
The name of the table to query.

.PARAMETER Column
The name of the column to query.

.PARAMETER WhereCondition
Optional condition to append to the WHERE clause of the query.

.OUTPUTS
[object]
The first value returned by the query. If multiple rows are selected, only the
first value is returned. If the resulting table was empty,
returns NULL.
#>
function Get-MSSQLScalarValue {
    [CmdletBinding()]
    [OutputType([object])]
    param (
        [Parameter(Mandatory)]
        [string]$ServerAddress,

        [Parameter(Mandatory)]
        [PSCredential]$Credential,

        [Parameter(Mandatory)]
        [string]$Table,

        [Parameter(Mandatory)]
        [string]$Column,

        [Parameter()]
        [string]$WhereCondition = $null
    )

    $query = "SELECT TOP (1) $Column FROM $Table"
    if (-not [string]::IsNullOrEmpty($WhereCondition)) {
        $query += " WHERE $WhereCondition"
    }
    
    $connection = Get-MSSQLConnection `
        -ServerAddress $ServerAddress `
        -Credential $Credential
    $command = $connection.CreateCommand()
    $command.CommandText = $query

    try {
        $connection.Open()
        $result = $command.ExecuteScalar()
    }
    catch {
        $msg = $_.Exception.Message + 
        "`n------------------------" + 
        "`nServer: $ServerAddress" + 
        "`nUsername: $($Credential.UserName)" + 
        "`nQuery: $query" +
        "`n------------------------"
        throw [System.Exception]::new($msg, $_.Exception)
    }
    finally {
        $connection.Close() # Silently fails if already closed
    }

    return $result
}

<#
.SYNOPSIS
Updates column values in a Microsoft SQL Server table.

.DESCRIPTION
Executes an UPDATE statement against the specified table and column. All rows
matching the optional WHERE condition will be updated.

The connection string is explicitly configured to:
- Use SQL authentication (Windows authentication is disabled)
- Use TCP port 1433
- Connect to the "master" database

.PARAMETER ServerAddress
The DNS name or IP address of the SQL Server instance. Do not include the port
number; TCP port 1433 is always used.

.PARAMETER Credential
A [PSCredential] object containing the SQL Server username and password.

.PARAMETER Table
The name of the target table to update.

.PARAMETER Column
The name of the column whose value will be updated.

.PARAMETER Value
The value to assign to the column. The caller is responsible for ensuring the
value is correctly formatted for SQL.

.PARAMETER WhereCondition
Optional condition to append to the WHERE clause of the query.

.OUTPUTS
[int]
The number of rows affected.
#>
function Set-MSSQLColumnValues {
    [CmdletBinding()]
    [OutputType([int])]
    param (
        [Parameter(Mandatory)]
        [string]$ServerAddress,

        [Parameter(Mandatory)]
        [PSCredential]$Credential,

        [Parameter(Mandatory)]
        [string]$Table,

        [Parameter(Mandatory)]
        [string]$Column,

        [Parameter(Mandatory)]
        [string]$Value,

        [Parameter()]
        [string]$WhereCondition = $null
    )

    $query = "UPDATE $Table SET $Column = $Value"
    if (-not [string]::IsNullOrEmpty($WhereCondition)) {
        $query += " WHERE $WhereCondition"
    }
    
    $connection = Get-MSSQLConnection `
        -ServerAddress $ServerAddress `
        -Credential $Credential
    $command = $connection.CreateCommand()
    $command.CommandText = $query

    try {
        $connection.Open()
        $result = $command.ExecuteNonQuery()
    }
    catch {
        $msg = $_.Exception.Message + 
        "`n------------------------" + 
        "`nServer: $ServerAddress" + 
        "`nUsername: $($Credential.UserName)" + 
        "`nQuery: $query" +
        "`n------------------------"
        throw [System.Exception]::new($msg, $_.Exception)
    }
    finally {
        $connection.Close() # Silently fails if already closed
    }

    return $result
}

<#
.SYNOPSIS
Inserts a row into a Microsoft SQL Server table.

.DESCRIPTION
Executes an INSERT INTO VALUES statement against the specified table.

The connection string is explicitly configured to:
- Use SQL authentication (Windows authentication is disabled)
- Use TCP port 1433
- Connect to the "master" database

.PARAMETER ServerAddress
The DNS name or IP address of the SQL Server instance. Do not include the port
number; TCP port 1433 is always used.

.PARAMETER Credential
A [PSCredential] object containing the SQL Server username and password.

.PARAMETER Table
The name of the target table to insert into.

.PARAMETER Columns
Hashtable containing the columns and their values to insert. The hashtable
should be string-string key-value pair. It is the caller's responsibility to
format the strings as SQL compatible.

.OUTPUTS
[int]
The number of rows affected.
#>
function Add-MSSQLRowIntoTable {
    [CmdletBinding()]
    [OutputType([int])]
    param (
        [Parameter(Mandatory)]
        [string]$ServerAddress,

        [Parameter(Mandatory)]
        [PSCredential]$Credential,

        [Parameter(Mandatory)]
        [string]$Table,

        [Parameter(Mandatory)]
        [hashtable]$Columns
    )
    
    $columnsList = [System.Collections.Generic.List[string]]::new()
    $valuesList = [System.Collections.Generic.List[string]]::new()
    foreach ($entry in $Columns.GetEnumerator()) {
        if ($entry.Key -isnot [string] -or $entry.Value -isnot [string]) {
            throw "Non-string or null key or value found!"
        }
        $columnsList.Add($entry.Key)
        $valuesList.Add($entry.Value)
    }

    $query = "INSERT INTO $Table ($($columnsList -join ', ')) VALUES ($($valuesList -join ', '))"

    $connection = Get-MSSQLConnection `
        -ServerAddress $ServerAddress `
        -Credential $Credential
    $command = $connection.CreateCommand()
    $command.CommandText = $query

    try {
        $connection.Open()
        $result = $command.ExecuteNonQuery()
    }
    catch {
        $msg = $_.Exception.Message + 
        "`n------------------------" + 
        "`nServer: $ServerAddress" + 
        "`nUsername: $($Credential.UserName)" + 
        "`nQuery: $query" +
        "`n------------------------"
        throw [System.Exception]::new($msg, $_.Exception)
    }
    finally {
        $connection.Close() # Silently fails if already closed
    }

    return $result
}

<#
.SYNOPSIS
Returns the maximum value from a Microsoft SQL Server table column.

.DESCRIPTION
Executes a SELECT MAX(<column>) statement against the specified table and column
and returns the result.

The connection string is explicitly configured to:
- Use SQL authentication (Windows authentication is disabled)
- Use TCP port 1433
- Connect to the "master" database

.PARAMETER ServerAddress
The DNS name or IP address of the SQL Server instance. Do not include the port
number; TCP port 1433 is always used.

.PARAMETER Credential
A [PSCredential] object containing the SQL Server username and password.

.PARAMETER Table
The name of the table to query.

.PARAMETER Column
The name of the column to query.

.PARAMETER WhereCondition
Optional condition to append to the WHERE clause of the query.

.OUTPUTS
[object]
Returns the scalar result of the query. If the resulting table was empty,
returns NULL.
#>
function Get-MSSQLMaxColumnValue {
    [CmdletBinding()]
    [OutputType([object])]
    param (
        [Parameter(Mandatory)]
        [string]$ServerAddress,

        [Parameter(Mandatory)]
        [PSCredential]$Credential,

        [Parameter(Mandatory)]
        [string]$Table,

        [Parameter(Mandatory)]
        [string]$Column,

        [Parameter()]
        [string]$WhereCondition = $null
    )

    $query = "SELECT Max($Column) FROM $Table"
    if (-not [string]::IsNullOrEmpty($WhereCondition)) {
        $query += " WHERE $WhereCondition"
    }
    
    $connection = Get-MSSQLConnection `
        -ServerAddress $ServerAddress `
        -Credential $Credential
    $command = $connection.CreateCommand()
    $command.CommandText = $query

    try {
        $connection.Open()
        $result = $command.ExecuteScalar()
    }
    catch {
        $msg = $_.Exception.Message + 
        "`n------------------------" + 
        "`nServer: $ServerAddress" + 
        "`nUsername: $($Credential.UserName)" + 
        "`nQuery: $query" +
        "`n------------------------"
        throw [System.Exception]::new($msg, $_.Exception)
    }
    finally {
        $connection.Close() # Silently fails if already closed
    }

    return $result
}

Export-ModuleMember -Function *
