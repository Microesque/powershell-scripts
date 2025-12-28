param (
    [Parameter(Mandatory = $true)]
    [string] $FfmpegExecutablePath,

    [Parameter(Mandatory = $true)]
    [string] $ImagesFolderPath,

    [Parameter(Mandatory = $true)]
    [string] $ImagesRegex,

    [Parameter(Mandatory = $true)]
    [string] $OutputFolderPath,

    [Parameter(Mandatory = $true)]
    [string] $OutputFileName,

    [Parameter(Mandatory = $true)]
    [int] $OutputFileWidth,

    [Parameter(Mandatory = $true)]
    [int] $OutputFileHeight,

    [Parameter(Mandatory = $true)]
    [int] $OutputFileFramerate,

    [switch] $Y
)

# ==============================================================================
# ================================== FUNCTIONS =================================
# ==============================================================================
function Stop-ScriptWithErrorMessage {
    param (
        [Parameter(Mandatory = $true)]
        $msg
    )

    Write-Host $msg -ForegroundColor Red
    exit 1
}

# ==============================================================================
# ================================= VALIDATION =================================
# ==============================================================================
# FfmpegExecutablePath
if (-not (Test-Path $FfmpegExecutablePath -PathType Leaf)) {
    Stop-ScriptWithErrorMessage "ffmpeg executable is invalid or not found: `"$FfmpegExecutablePath`""
}

# ImagesFolderPath
if (-not (Test-Path $ImagesFolderPath -PathType Container)) {
    Stop-ScriptWithErrorMessage "Images source folder is invalid or not found: `"$ImagesFolderPath`""
}

# ImagesRegex
try {
    [void][regex]::new($ImagesRegex)
}
catch {
    Stop-ScriptWithErrorMessage "Invalid regex: $ImagesRegex"
}

# OutputFolderPath
if (-not (Test-Path $OutputFolderPath -PathType Container)) {
    Stop-ScriptWithErrorMessage "Output destination folder is invalid or not found: `"$OutputFolderPath`""
}

# OutputFileName
if ($OutputFileName.IndexOfAny([System.IO.Path]::GetInvalidFileNameChars()) -ne -1 -or
    $OutputFileName.Trim().Length -eq 0) {
    Stop-ScriptWithErrorMessage "Invalid file name: `"$OutputFileName`""
}

# OutputFileWidth
if ($OutputFileWidth -le 0) {
    Stop-ScriptWithErrorMessage "Invalid output file width: `"$OutputFileWidth`""
}

# OutputFileHeight
if ($OutputFileHeight -le 0) {
    Stop-ScriptWithErrorMessage "Invalid output file height: `"$OutputFileHeight`""
}

# OutputFileFramerate
if ($OutputFileFramerate -le 0) {
    Stop-ScriptWithErrorMessage "Invalid output file framerate: `"$OutputFileFramerate`""
}

# ==============================================================================
# =================================== SCRIPT ===================================
# ==============================================================================
$images = Get-ChildItem -Path $ImagesFolderPath | Where-Object { $_.Name -match $ImagesRegex } | Sort-Object Name
if (-not $images) {
    Stop-ScriptWithErrorMessage "Output destination folder contains no matching images:`n    Path: `"$ImagesFolderPath`"`n    Pattern: `"$ImagesRegex`""
}

if (-not $Y) {
    # Print images found (shorten if too long)
    Write-Host "Files found ($($images.Count) total):" -ForegroundColor Green
    $showLimit = 40
    if ($images.Count -gt $showLimit) {
        for ($i = 0; $i -lt ($showLimit / 2); $i++) {
            Write-Host "  $($images[$i].Name)" -ForegroundColor Cyan
        }
        Write-Host "  ..." -ForegroundColor cyan
        for ($i = ($images.Count - ($showLimit / 2)); $i -lt $images.Count; $i++) {
            Write-Host "  $($images[$i].Name)" -ForegroundColor Cyan
        }
    }
    else {
        foreach ($image in $images) {
            Write-Host "  $($image.Name)" -ForegroundColor Cyan
        }
    }

    # Get confirmation
    while (1) {
        $confirmation = Read-Host "`nDo you want to continue? (y/n)"
        if ($confirmation -eq 'y') {
            break
        }
        elseif ($confirmation -eq 'n') {
            Write-Host "`nAbandoning..." -ForegroundColor Green
            exit 0
        }
    }
}

try {
    # Create/overwrite a temporary file for the ffmpeg concat demuxer
    $tempFilePath = Join-Path $ImagesFolderPath "_000temp.txt"
    $images | ForEach-Object { "file '$($_.FullName)'" } | Set-Content -Path $tempFilePath -Encoding ASCII

    # Run ffmpeg using the concat demuxer
    Write-Host "Total number of images: $($images.Count)" -ForegroundColor Green
    $outputFilePath = Join-Path $OutputFolderPath $OutputFileName
    & $FfmpegExecutablePath `
        -y `
        -r $OutputFileFramerate `
        -safe 0 `
        -f concat `
        -i $tempFilePath `
        -vf "scale=$($OutputFileWidth):$($OutputFileHeight):force_original_aspect_ratio=decrease:flags=lanczos,pad=$($OutputFileWidth):$($OutputFileHeight):(ow-iw)/2:(oh-ih)/2:black" `
        -c:v libx264 `
        -crf 18 `
        -pix_fmt yuv420p `
        $outputFilePath

    # Check if ffmpeg failed
    if ($LASTEXITCODE -eq 0) {
        Write-Host "`nVideo file created at: `"$outputFilePath`"" -ForegroundColor Green
    }
    exit 0
}
catch {
    Stop-ScriptWithErrorMessage "`nSomething went wrong:`n $_"
}
finally {
    if (Test-Path $tempFilePath) {
        Remove-Item -Path $tempFilePath -Force
    }
}
