
# ==============================================================================
# =============================== SELF ELEVATION ===============================
# ==============================================================================
$CurrentPrincipal = New-Object Security.Principal.WindowsPrincipal $([Security.Principal.WindowsIdentity]::GetCurrent())
$Admin = [Security.Principal.WindowsBuiltinRole]::Administrator
if (-not $CurrentPrincipal.IsInRole($Admin)) {
    try {
        Start-Process `
            "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe" `
            -Verb RunAs `
            -ArgumentList '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', "`"$PSCommandPath`""
    }
    catch {
        Write-Host "Self elevation failed:`n$_" -ForegroundColor Red
        Pause
    }
    exit
}

# ==============================================================================
# ============================== FILTER FUNCTIONS ==============================
# ==============================================================================

# ==============================================================================
# =============================== User Functions ===============================
# ==============================================================================
function Wait-CustomPause {
    Write-Host "`nPress any key to continue..." -ForegroundColor White
    [void][System.Console]::ReadKey($true)
}

function Show-Processes {
    param(
        [System.Diagnostics.Process[]] $Processes,
        [string[]] $Suffixes,
        [string[]] $Colors,
        [switch] $IsUniform = $false,
        [string] $UniformColor = "Yellow",
        [string] $UniformSuffix = ""
    )

    # If not uniform
    if ($IsUniform -eq $false) {
        if ($Processes.Count -ne $Suffixes.Count -or $Processes.Count -ne $Colors.Count) {
            throw "Processes, Suffixes, and Colors must all have the same length."
        }
    }

    for ($i = 0; $i -lt $Processes.Count; $i++) {
        #Extract parameters
        $Process = $Processes[$i]
        if ($IsUniform -eq $false) {
            $Suffix = $Suffixes[$i]
            $Color = $Colors[$i]
        }
        else {
            $Color = $UniformColor
            $Suffix = $UniformSuffix
        }

        # Extract and format strings
        $Num = ($i + 1).ToString().PadLeft(4)
        $Id = $Process.Id.ToString().PadLeft(5)
        $Name = $Process.ProcessName
        if ($Name.Length -ge 20) {
            $Name = $Name.Substring(0, 17) + "..."
        }
        else {
            $Name = $Name.PadRight(20)
        }

        # User output
        if ($Color -eq "default") {
            Write-Host "    $Num-)" -ForegroundColor Green -NoNewline
            Write-Host " $Id"       -ForegroundColor Red   -NoNewline
            Write-Host " - "        -ForegroundColor Green -NoNewline 
            Write-Host "$Name "     -ForegroundColor Cyan  -NoNewline 
            Write-Host " $Suffix"   -ForegroundColor White
        }
        else {
            Write-Host "    $Num - ) $Id - $Name $Suffix" -ForegroundColor $Color
        }
    }
}

function Stop-AllFilteredProcesses {
    param(
        [System.Diagnostics.Process[]] $Processes
    )

    Clear-Host    
    Write-Host "Killing all found processes...:" -ForegroundColor Green
    
    $Suffixes = [System.Collections.Generic.List[string]]::new()
    $Colors = [System.Collections.Generic.List[string]]::new()
    foreach ($Process in $Processes) {
        if ($Process.HasExited) {
            $Suffixes.Add("(Already Exited)")
            $Colors.Add("DarkYellow")
            continue
        }
        try {
            $Process.Kill()
            $Suffixes.Add("(Killed)")
            $Colors.Add("Green")
        }
        catch {
            $Failed.Add($Count, "$_.Exception")
            $Suffixes.Add("(Failed)")
            $Colors.Add("Red")
        }
    }

    Show-Processes $Processes $Suffixes.ToArray() $Colors.ToArray()
    Wait-CustomPause
}

function Stop-SelectedFilteredProcesses {
    param(
        [System.Diagnostics.Process[]] $Processes
    )

    Clear-Host
    Write-Host "Waiting for selection:" -ForegroundColor Green
    Show-Processes $Processes -IsUniform $true
    Write-Host "`nEnter row number(s), separated by commas:" -ForegroundColor White
    
    $UserInput = (Read-Host)
    if ($UserInput -ne "") {
        $Rows = $UserInput -split ',' | ForEach-Object { $_.Trim() }
        foreach ($Row in $Rows) {
            if ($Row -notmatch "^\d+$") {
                Clear-Host
                Write-Host "Invalid number or character. Please enter row number(s), separated by commas. -> [$UserInput]" -ForegroundColor Red
                Wait-CustomPause
                return
            }

            $RowInt = [int]$Row
            if ($RowInt -eq 0 -or $RowInt -gt $Processes.Count) {
                Clear-Host
                Write-Host "Number out of range. Please enter row number(s), separated by commas. -> [$UserInput]" -ForegroundColor Red
                Wait-CustomPause
                return
            }
        }
    }

    Clear-Host    
    Write-Host "Killing selected processes...:" -ForegroundColor Green
    
    $Suffixes = [System.Collections.Generic.List[string]]::new()
    $Colors = [System.Collections.Generic.List[string]]::new()
    for ($i = 0; $i -lt $Processes.Count; $i++) {
        $Process = $Processes[$i]
        if (($i + 1).ToString() -notin $Rows) {
            $Suffixes.Add("(Not Selected)")
            $Colors.Add("Yellow")
            continue
        }
        if ($Process.HasExited) {
            $Suffixes.Add("(Already Exited)")
            $Colors.Add("Green")
            continue
        }
        try {
            $Process.Kill()
            $Suffixes.Add("(Killed)")
            $Colors.Add("Green")
        }
        catch {
            $Failed.Add($Count, "$_.Exception")
            $Suffixes.Add("(Failed)")
            $Colors.Add("Red")
        }
    }

    Show-Processes $Processes $Suffixes.ToArray() $Colors.ToArray()
    Wait-CustomPause
}

function Show-ProcessesAndAddFilter {
    $Processes = Get-Process

    Clear-Host
    Write-Host "List of all running processes:" -ForegroundColor Green
    Show-Processes $Processes -IsUniform $true
    Write-Host "`nEnter a row number to add as a filter (leave empty to skip):" -ForegroundColor White

    $UserInput = (Read-Host).Trim()
    if ($UserInput -eq "") {
        return
    }
    if ($UserInput -notmatch '^\d+$') {
        Clear-Host
        Write-Host "Invalid number. Please enter a row number or skip. -> [$UserInput]" -ForegroundColor Red
        Wait-CustomPause
        return
    }

    $Row = [int]$UserInput
    if ($Row -eq 0 -or $Row -gt $Processes.Count) {
        Clear-Host
        Write-Host "Number out of range. Please enter a row number or skip. -> [$UserInput]" -ForegroundColor Red
        Wait-CustomPause
        return
    }

    $Process = $Processes[$Row - 1]
    Clear-Host
    Write-Host "Processes Selected - PID:"  -ForegroundColor Green -NoNewline
    Write-Host " $($Process.Id)"            -ForegroundColor Cyan
    Write-Host "Processes Selected - Name:" -ForegroundColor Green -NoNewline
    Write-Host " $($Process.ProcessName)"   -ForegroundColor Cyan
    Write-Host "`nEnter a description for the filter (max 40 chars):" -ForegroundColor White
    $Description = (Read-Host).Trim()
    if ($Description.Length -gt 40) {
        $Description = $Description.Substring(0, 40)
    }
    
    # Add-Filter $Process.ProcessName $Description

    Clear-Host
    Write-Host "Filter added - Name:"        -ForegroundColor Green -NoNewline
    Write-Host " $($Process.ProcessName)"    -ForegroundColor Yellow
    Write-Host "Filter added - Description:" -ForegroundColor Green -NoNewline
    Write-Host " $Description"               -ForegroundColor Yellow
    Wait-CustomPause
}

# ==============================================================================
# =================================== Script ===================================
# ==============================================================================
# List of process names to filter (process name - description)
$ProcessFilter = @{
    "msedge"       = "Microsoft edge"
    "chromedriver" = "Chrome driver instance"
}

# User interface loop
while ($true) {
    Clear-Host
    Write-Host "List of processes found:" -ForegroundColor Green -NoNewline
    Write-Host " (PID)"                   -ForegroundColor Red   -NoNewline
    Write-Host " (ProcessName)"           -ForegroundColor Cyan

    $FilteredProcesses = Get-Process | Where-Object { $ProcessFilter.ContainsKey($_.ProcessName) }
    Show-Processes $FilteredProcesses -IsUniform $true -UniformColor "default"

    Write-Host (
        "`nList of commands:`n" +
        "    (K) Kill all`n" +
        "    (S) Select to kill`n" +
        "    (A) Show all processes (add to filters)`n" +
        "    (F) Show all filters (edit/remove filters)`n" +
        "    (E) Exit`n" +
        "    ( * ) Press any other key to update:"
    ) -ForegroundColor White
    
    $UserInput = $Host.UI.RawUI.ReadKey("NoEcho, IncludeKeyDown")
    switch ($UserInput.Character) {
        'k' { Stop-AllFilteredProcesses $FilteredProcesses }
        's' { Stop-SelectedFilteredProcesses $FilteredProcesses }
        'a' { Show-ProcessesAndAddFilter }
        'f' { }
        'e' { Exit }
    }
}
