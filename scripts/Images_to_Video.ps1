
# ==============================================================================
# ==================================== SETUP ===================================
# ==============================================================================
$ffmpeg_executable_path = "C:\Users\jdoe\Desktop\ffmpeg\bin\ffmpeg.exe"
$images_folder_path     = "C:\Users\jdoe\Desktop\ss"
$images_regex           = "^.*\.jpg$"
$output_folder_path     = "C:\Users\jdoe\Desktop"
$output_file_name       = "output.mp4"
$output_file_width      = "2560"
$output_file_height     = "1440"
$output_file_framerate  = "60"

# ==============================================================================
# ================================== FUNCTIONS =================================
# ==============================================================================
function Stop-ScriptAfterKeyPress {
    Write-Host "`nPress any key to exit."
    $null = $Host.UI.RawUI.ReadKey("NoEcho, IncludeKeyDown")
    exit
}

# ==============================================================================
# =================================== SCRIPT ===================================
# ==============================================================================
# Verify paths
Clear-Host
if (-not (Test-Path $ffmpeg_executable_path)) {
    Write-Host "ffmpeg executable not found at path `"$ffmpeg_executable_path`"." -ForegroundColor red
    Stop-ScriptAfterKeyPress
}
if (-not (Test-Path $images_folder_path)) {
    Write-Host "Source folder not found at path `"$images_folder_path`"." -ForegroundColor red
    Stop-ScriptAfterKeyPress
}
if (-not (Test-Path $output_folder_path)) {
    Write-Host "Destination folder not found at path `"$output_folder_path`"." -ForegroundColor red
    Stop-ScriptAfterKeyPress
}

# Fetch the matching images
$images = Get-ChildItem -Path $images_folder_path |
          Where-Object { $_.Name -match $images_regex } |
          Sort-Object Name

# Exit if no image was found
if (-not $images) {
    Clear-Host
    Write-Host "No files found at `"$images_folder_path`" that match `"$images_regex`"." -ForegroundColor red
    Stop-ScriptAfterKeyPress
}

# List found images (shorten if nececessary)
Write-Host "Files found ($($images.Count) total):" -ForegroundColor green
$show_limit = 40
if ($images.Count -gt $show_limit) {
    for ($i = 0; $i -lt ($show_limit / 2); $i++) {
        Write-Host "  $($images[$i].Name)" -ForegroundColor cyan
    }
    Write-Host "  ..." -ForegroundColor cyan
    for ($i = ($images.Count - ($show_limit / 2)); $i -lt $images.Count; $i++) {
        Write-Host "  $($images[$i].Name)" -ForegroundColor cyan
    }
}
else {
    foreach ($image in $images) {
        Write-Host "  $($image.Name)" -ForegroundColor cyan
    }
}

# Get confirmation from the user to proceed or exit
$confirmation = Read-Host "Do you want to continue? (y/n)"
if ($confirmation -ne 'y') {
    Clear-Host
    Write-Host "Abandoning..." -ForegroundColor red
    Stop-ScriptAfterKeyPress
}

try {
    Clear-Host

    # Create/overwrite a temporary file for the ffmpeg concat demuxer
    $temp_file_path = Join-Path $images_folder_path "_000temp.txt"
    $images | ForEach-Object { "file '$($_.FullName)'" } | Set-Content -Path $temp_file_path -Encoding ASCII

    # Run ffmpeg using the concat demuxer
    Write-Host "Total number of images: $($images.Count)" -ForegroundColor green
    $output_file_path = Join-Path $output_folder_path $output_file_name
    & $ffmpeg_executable_path `
        -y `
        -r $output_file_framerate `
        -safe 0 `
        -f concat `
        -i $temp_file_path `
        -vf "scale=$($output_file_width):$($output_file_height):force_original_aspect_ratio=decrease:flags=lanczos,pad=$($output_file_width):$($output_file_height):(ow-iw)/2:(oh-ih)/2:black" `
        -c:v libx264 `
        -crf 18 `
        -pix_fmt yuv420p `
        $output_file_path

    # Check if ffmpeg failed
    if ($LASTEXITCODE -eq 0) {
        Write-Host "`nVideo file created at `"$output_file_path`"." -ForegroundColor green
    }
    Stop-ScriptAfterKeyPress
}
catch {
    Clear-Host
    Write-Host "`nSomething went wrong:`n $_" -ForegroundColor red
    Stop-ScriptAfterKeyPress
}
finally {
    if (Test-Path $temp_file_path) {
        Remove-Item -Path $temp_file_path -Force
    }
}
