# SCRIPT USAGE

>- The `modules` directory contains reusable functions required by the main scripts in this directory. Scripts will not function correctly if this directory is missing.
>- These scripts require admin privalages to run.
>- These scripts are non-interactive but provide detailed logging output. Reading the logs is optional, as their primary use case relies on exit codes.
>- Scripts should be executed in the following order:
>   1. `Test-Wsl2Requirements.ps1` -> Verifies hardware and software requirements for WSL2.
>   2. `Install-Wsl2.ps1` -> Installs WSL2.
>   3. `Initialize-Wsl2Debian.ps1` -> Installs Debian and configures packages.
>- While scripts can be run individually, each assumes that the preceding steps have been completed. For example, `Install-Wsl2.ps1` expects that the system already meets WSL2 requirements.

---
