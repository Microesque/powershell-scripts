
# ==============================================================================
# =============================== Self Elevation ===============================
# ==============================================================================
$CurrentPrincipal = New-Object Security.Principal.WindowsPrincipal $([Security.Principal.WindowsIdentity]::GetCurrent())
$Admin = [Security.Principal.WindowsBuiltinRole]::Administrator
if (-not $CurrentPrincipal.IsInRole($Admin)) {
    Start-Process Powershell.exe -Verb RunAs -ArgumentList "-file `"$($myinvocation.MyCommand.Definition)`""
    exit
}

# ==============================================================================
# ================================== Functions =================================
# ==============================================================================
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
            Write-Host "    $Num-) $Id - $Name $Suffix" -ForegroundColor $Color
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
    Write-Host "`nPress any key to continue..." -ForegroundColor White
    [void][System.Console]::ReadKey($true)
}

# ==============================================================================
# =================================== Script ===================================
# ==============================================================================
# List of process names to filter
$ProcessFilter = @(
    "msedge",
    "chromedriver"
)

# User interface loop
while ($true) {
    Clear-Host
    Write-Host "List of processes found:" -ForegroundColor Green -NoNewline
    Write-Host " (PID)"                   -ForegroundColor Red   -NoNewline
    Write-Host " (ProcessName)"           -ForegroundColor Cyan

    $FilteredProcesses = Get-Process | Where-Object { $ProcessFilter -contains $_.ProcessName }
    Show-Processes $FilteredProcesses -IsUniform $true -UniformColor "default"

    Write-Host (
        "`nList of commands:`n" +
        "    (K) Kill all`n" +
        "    (S) Select to kill`n" +
        "    (A) Show all processes (add to filters)`n" +
        "    (F) Show all filters (edit/remove filters)`n" +
        "    (E) Exit`n" +
        "    (*) Press any other key to update:"
    ) -ForegroundColor White
    
    $UserInput = $Host.UI.RawUI.ReadKey("NoEcho, IncludeKeyDown")
    switch ($UserInput.Character) {
        'k' { Stop-AllFilteredProcesses $FilteredProcesses }
        's' { }
        'a' { }
        'f' { }
        'e' { Exit }
    }
}
