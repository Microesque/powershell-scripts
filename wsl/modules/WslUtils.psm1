<#
.SYNOPSIS
Provides utility functions for interacting with WSL.

.DESCRIPTION
This module contains functions to manage, query, and perform operations related
to Windows Subsystem for Linux (WSL). Functions include checking WSL versions,
testing installations, and initiating WSL-related commands. This is done mainly
via interacting with `wsl.exe` in the system PATH.
#>

# ==============================================================================
# ==============================================================================
# ==============================================================================

<#
.SYNOPSIS
Checks whether `wsl.exe` is available in the system PATH.

.DESCRIPTION
Checks whether `wsl.exe` is available in the system PATH. Also executes
`wsl.exe --help` to verify that the executable at leasts supports the `--status`
option.

.OUTPUTS
[bool]
Returns $true if `wsl.exe` is available ins the system PATH; otherwise $false.

.NOTES
Throws if `wsl.exe` returns a non-zero exit code.
#>
function Test-WslExecutable {
    [CmdletBinding()]
    [OutputType([bool])]
    param()

    if (-not (Get-Command wsl.exe -ErrorAction SilentlyContinue)) {
        return $false
    }

    $output = & wsl.exe --help 2>&1
    $output = ($output | Out-String).Replace("`0", "").Trim()
    # & wsl.exe --help always seems to return -1
    # if ($LASTEXITCODE -ne 0) { 
    #     throw "wsl.exe failed with exit code $LASTEXITCODE. Output:`n$output"
    # }
    return ($output -match "--status")
}

<#
.SYNOPSIS
Checks whether WSL is installed.

.DESCRIPTION
Executes `wsl.exe --status` to determine if the WSL is installed. Assumes
`wsl.exe` is available in the system PATH and supports this command.

.OUTPUTS
[bool]
Returns $true if WSL is installed; otherwise $false.

.NOTES
Throws if `wsl.exe` returns a non-zero exit code.
#>
function Test-WslInstallation {
    [CmdletBinding()]
    [OutputType([bool])]
    param()
    
    $output = & wsl.exe --status 2>&1
    $output = ($output | Out-String).Replace("`0", "").Trim()
    # Returns exitcode 50 if not installed
    if ($LASTEXITCODE -ne 0 -and $LASTEXITCODE -ne 50) {
        throw "wsl.exe failed with exit code $LASTEXITCODE. Output:`n$output"
    }
    if ($LASTEXITCODE -eq 50 -or $output -match "is not installed") {
        return $false
    }
    return $true
}

<#
.SYNOPSIS
Retrieves the installed WSL and kernel versions.

.DESCRIPTION
Executes `wsl.exe --version` to obtain version information. Parses the output 
to extract the WSL and kernel versions, and returns them as a custom object.
Assumes `wsl.exe` is available in the system PATH and supports this command.

.OUTPUTS
[PSCustomObject]
Returns an object with the following properties:
    - [string] WslVersion: The installed WSL version. If version information
    can't be determined, will return $null instead.
    - [string] KernelVersion: The installed Linux kernel version used by WSL. If
    version information can't be determined, will return $null instead.

.NOTES
Throws if `wsl.exe` returns a non-zero exit code.
#>
function Get-WslVersion {
    [CmdletBinding()]
    param()
    
    $output = & wsl.exe --version 2>&1
    $output = ($output | Out-String).Replace("`0", "").Trim()
    if ($LASTEXITCODE -ne 0) {
        throw "wsl.exe failed with exit code $LASTEXITCODE. Output:`n$output"
    }

    $wslVersion = $null
    if ($output -match "WSL version:\s*(\S+)") {
        $wslVersion = $Matches[1]
    }

    $kernelVersion = $null
    if ($output -match "Kernel version:\s*(\S+)") {
        $kernelVersion = $Matches[1]
    }
    
    return [PSCustomObject]@{
        WslVersion    = $wslVersion
        KernelVersion = $kernelVersion
    }
}

<#
.SYNOPSIS
Attempts to install WSL.

.DESCRIPTION
Executes `wsl.exe --install --no-distribution` to initiate the installation.
Evaluates the exit code to determine success. Assumes that `wsl.exe` is available
in the system PATH.

.NOTES
Throws if `wsl.exe` returns a non-zero exit code.
#>
function Install-Wsl {
    [CmdletBinding()]
    param()

    $output = & wsl.exe --install --no-distribution 2>&1
    if ($LASTEXITCODE -ne 0) {
        $output = ($output | Out-String).Replace("`0", "").Trim()
        throw "wsl.exe failed with exit code $LASTEXITCODE. Output:`n$output"
    }
}

<#
.SYNOPSIS
Attempts to update WSL to the latest version.

.DESCRIPTION
Executes `wsl.exe --update` to attempt updating WSL. Parses the output to
determine whether WSL was already up to date and returns a boolean result.
Assumes `wsl.exe` is available in the system PATH and supports this command.

.OUTPUTS
[bool]
Returns $true if WSL was already up to date; otherwise $false.

.NOTES
Throws if `wsl.exe` returns a non-zero exit code.
#>
function Update-Wsl {
    [CmdletBinding()]
    param()

    $output = & wsl.exe --update 2>&1
    $output = ($output | Out-String).Replace("`0", "").Trim()
    if ($LASTEXITCODE -ne 0) {
        throw "wsl.exe failed with exit code $LASTEXITCODE. Output:`n$output"
    }
    return ($output -match "already")
}

<#
.SYNOPSIS
Checks whether WSL2 is installed.

.DESCRIPTION
Executes `wsl.exe --version` to determine if a kernel version is present, which
indicates that WSL2 is installed. This does not guarantee that WSL2 can run
successfully; it only confirms that it is installed. Assumes `wsl.exe` is
available in the system PATH and supports this command.

.OUTPUTS
[bool]
Returns $true if WSL2 is installed; otherwise $false.

.NOTES
Throws if `wsl.exe` returns a non-zero exit code.
#>
function Test-Wsl2Installation {
    [CmdletBinding()]
    [OutputType([bool])]
    param()
    
    $output = & wsl.exe --version 2>&1
    $output = ($output | Out-String).Replace("`0", "").Trim()
    if ($LASTEXITCODE -ne 0) {
        throw "wsl.exe failed with exit code $LASTEXITCODE. Output:`n$output"
    }
    return ($output -match "Kernel version: ")
}

<#
.SYNOPSIS
Checks whether a specific WSL distribution is installed.

.DESCRIPTION
Executes `wsl.exe --list --quiet` to retrieve the installed distributions and
checks whether the specified distribution is present. Assumes `wsl.exe` is
available in the system PATH and supports this command.

.PARAMETER Distro
The name of the WSL distribution to check (e.g., 'Debian, 'Ubuntu-22.04').

.OUTPUTS
[bool]
Returns $true if the specified distribution is installed; otherwise $false.

.NOTES
Throws if `wsl.exe` returns a non-zero exit code.
#>
function Test-WSLDistroInstallation {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Distro
    )

    $output = & wsl.exe --list --quiet 2>&1
    if ($LASTEXITCODE -ne 0) {
        $output = ($output | Out-String).Replace("`0", "").Trim()
        throw "wsl.exe failed with exit code $LASTEXITCODE. Output:`n$output"
    }
    $distros = @($output | ForEach-Object { $_.ToString().Replace("`0", "").Trim() } | Where-Object { $_ })
    return ($distros -contains $Distro)
}

<#
.SYNOPSIS
Returns the current default WSL version.

.DESCRIPTION
Executes `wsl.exe --status` and parses its output to determine the current
default WSL version. Assumes `wsl.exe` is available in the system PATH and
supports this command.

.OUTPUTS
[int]
The default WSL version reported by `wsl.exe`.

.NOTES
Throws if `wsl.exe` returns a non-zero exit code.
Throws if the output cannot be parsed for a valid version number.
#>
function Get-WslDefaultVersion {
    [CmdletBinding()]
    [OutputType([int])]
    param()

    $output = & wsl.exe --status 2>&1
    $output = ($output | Out-String).Replace("`0", "").Trim()
    
    if ($LASTEXITCODE -ne 0) {
        throw "wsl.exe failed with exit code $LASTEXITCODE. Output:`n$output"
    }

    if ($output -match "Default Version:\s+(\d+)") {
        return ([int]$Matches[1])
    }
    throw "WSL returned an unknown default version. Output:`n$output"
}

<#
.SYNOPSIS
Sets WSL2 as the default WSL version.

.DESCRIPTION
Executes `wsl.exe --set-default-version 2` to set WSL2 as the default version.
Assumes `wsl.exe` is available in the system PATH and supports this command.

.NOTES
Throws if `wsl.exe` returns a non-zero exit code.
#>
function Update-Wsl2AsDefault {
    [CmdletBinding()]
    param()

    $output = & wsl.exe --set-default-version 2 2>&1  # Idempotent
    if ($LASTEXITCODE -ne 0) {
        $output = ($output | Out-String).Replace("`0", "").Trim()
        throw "wsl.exe failed with exit code $LASTEXITCODE. Output:`n$output"
    }
}

<#
.SYNOPSIS
Installs the specified WSL distribution.

.DESCRIPTION
Executes `wsl.exe --install -d $Distro --no-launch` to install the specified
WSL distribution. Assumes the specified distribution is not currently installed.
Assumes `wsl.exe` is available in the system PATH and supports this command.

.PARAMETER Distro
The name of the WSL distribution to install (e.g., 'Debian, 'Ubuntu-22.04').

.NOTES
Throws if `wsl.exe` returns a non-zero exit code.
#>
function Install-WSLDistro {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Distro
    )

    $output = & wsl.exe --install -d $Distro --no-launch 2>&1
    if ($LASTEXITCODE -ne 0) {
        $output = ($output | Out-String).Replace("`0", "").Trim()
        throw "wsl.exe failed with exit code $LASTEXITCODE. Output:`n$output"
    }
}

<#
.SYNOPSIS
Executes the specified bash command as root in a WSL distribution.

.DESCRIPTION
Executes `wsl.exe -d $Distro --user root -- bash -c "`"$Command`""` to execute
the specified bash command inside the specified WSL distribution. Assumes
`wsl.exe` is available in the system PATH and supports this command.

.PARAMETER Distro
The name of the WSL distribution to run the command on (e.g., 'Debian, 'Ubuntu-22.04').

.PARAMETER Command
The Bash command to execute inside the WSL distribution.

.NOTES
Throws if `wsl.exe` itself returns a non-zero exit code.
Throws if the command itself fails and returns a non-zero exit code.
#>
function Invoke-WSLRootCommand {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Distro,

        [Parameter(Mandatory = $true)]
        [string]$Command
    )

    $output = wsl.exe -d $Distro --user root -- bash -c "`"$Command`"" 2>&1
    if ($LASTEXITCODE -eq -1) {
        $output = ($output | Out-String).Replace("`0", "").Trim()
        throw "wsl.exe failed with exit code $LASTEXITCODE. Output:`n$output"
    }
    elseif ($LASTEXITCODE -ne 0) {
        throw "Command [$Command] failed in WSL distribution [$Distro]. Output:`n$output"
    }
}

Export-ModuleMember -Function *
