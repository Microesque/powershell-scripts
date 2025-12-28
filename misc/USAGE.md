### <u>New-VideoFromImage</u>
`Description:`
>- Turns specified list of images into a video.

`Parameters:`
```powershell
param (
    [Parameter(Mandatory = $true)]
    [string] $FfmpegExecutablePath,  # ffmpeg.exe executable on your computer

    [Parameter(Mandatory = $true)]
    [string] $ImagesFolderPath,      # Source folder where your images reside

    [Parameter(Mandatory = $true)]
    [string] $ImagesRegex,           # Regex for file names too look for

    [Parameter(Mandatory = $true)]
    [string] $OutputFolderPath,      # Destination folder for the output

    [Parameter(Mandatory = $true)]
    [string] $OutputFileName,        # Name of the video (with extension)

    [Parameter(Mandatory = $true)]
    [int] $OutputFileWidth,          # Width of the output video

    [Parameter(Mandatory = $true)]
    [int] $OutputFileHeight,         # Height of the output video

    [Parameter(Mandatory = $true)]
    [int] $OutputFileFramerate,      # Framerate of the output video

    [switch] $Y                      # Flag to skip confirmation
)
```

`Notes:`
>- Each image represents a single frame, so the framerate parameter directly determines the speed of the video.
>- Images are fed by alphabetical order.
>- Originally made for creating fast-forward videos of game state screenshots like Rimworld.

`Example:`
```powershell
.\New-VideoFromImage.ps1 `
  -FfmpegExecutablePath "C:\Users\jdoe\Desktop\execs\ffmpeg\bin\ffmpeg.exe" `
  -ImagesFolderPath "C:\Users\jdoe\Desktop\Screen_Shots" `
  -ImagesRegex "^.*\.jpg$" `
  -OutputFolderPath "C:\Users\jdoe\Desktop" `
  -OutputFileName "out.mp4" `
  -OutputFileWidth 2560 `
  -OutputFileHeight 1440 `
  -OutputFileFramerate 30
```

---
