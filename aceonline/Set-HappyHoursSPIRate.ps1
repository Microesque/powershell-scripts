# ==============================================================================
# =================================== PARAMS ===================================
# ==============================================================================
[CmdletBinding()]
param (
    [string]$Server,
    [string]$Username,
    [string]$Password,
    [string]$Value,

    [switch]$NonInteractive
)

if ($NonInteractive) {
    foreach ($name in "Server", "Username", "Password", "Value") {
        if (-not $PSBoundParameters.ContainsKey($name)) {
            throw "Non-interactive execution missing $name parameter."
        }
    }
}

# ==============================================================================
# =================================== IMPORTS ==================================
# ==============================================================================
$ModulesPath = Join-Path $PSScriptRoot "modules"
Import-Module (Join-Path $ModulesPath "CommonUtils.psm1") -Force
Import-Module (Join-Path $ModulesPath "SqlExpressUtils.psm1") -Force

# ==============================================================================
# =========================== PARAM/INPUT VALIDATION ===========================
# ==============================================================================
Write-Host ""

# $Server
if (-not $NonInteractive) {
    $Server = (Read-Host "Enter SQL server address")
}
$Server = Assert-TrimStrIsValidServerAddress $Server -Name "Server"

# $Username
if (-not $NonInteractive) {
    $Username = (Read-Host "Enter SQL username")
}
$Username = Assert-TrimStrIsNotNullOrEmpty $Username -Name "Username"

# $Password
if (-not $NonInteractive) {
    $Password = (Read-Host "Enter SQL password" -AsSecureString)
    $Password = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($password))
}
$Password = Assert-TrimStrIsNotNullOrEmpty $Password -Name "Password"

# $Value
if (-not $NonInteractive) {
    $Value = (Read-Host "Enter the new happy hour SPI multiplier")
}
$Value = Assert-TrimStrIsPositiveFloat $Value -Name "SPI multiplier"

# ==============================================================================
# =================================== SCRIPT ===================================
# ==============================================================================
$table = "atum2_db_account.dbo.ti_HappyHourEvent"
$whereCondition = "UniqueNumber > 100"

# Set new value
try {
    $columnsAffected = Set-TableColumnValues `
        -Server $Server `
        -Username $Username `
        -Password $Password `
        -Table $table `
        -Column "SPIRate" `
        -Value "$Value" `
        -WhereCondition $whereCondition
    if ($columnsAffected -eq 0) {
        throw "Number of rows affected was 0!"
    }
}
catch {
    Stop-ScriptWithErrorMessage "Something went wrong during SQL execution:`n$($_.Exception.Message)"
}

# Update user and exit
Write-Host "Happy hours spi rate is set to $($Value * 100)%. (Requires server restart!)" -ForegroundColor Green
Stop-ScriptWithSuccessMessage "Script successful."
