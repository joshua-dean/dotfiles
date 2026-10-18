# Install NixOS-WSL (https://github.com/nix-community/NixOS-WSL) and configure WSL networking.
# Run from an elevated PowerShell. Re-runnable: skips steps that are already done.
param([string]$Distro = "NixOS")
$ErrorActionPreference = "Stop"

# 1. WSL itself (no default distro); needs WSL >= 2.4.4 for --from-file
wsl --install --no-distribution
wsl --update

# 2. Mirrored networking: WSL and Windows share localhost, so a dev server on
#    0.0.0.0/127.0.0.1:PORT in WSL opens at http://localhost:PORT in a Windows browser
$cfg = "$env:USERPROFILE\.wslconfig"
if (-not (Select-String -Path $cfg -Pattern "networkingMode" -Quiet -ErrorAction SilentlyContinue)) {
    Add-Content $cfg "[wsl2]`nnetworkingMode=mirrored"
}

# 3. NixOS distro from the latest release image
if (-not ((wsl -l -q) -replace "`0" -contains $Distro)) {
    $img = "$env:TEMP\nixos.wsl"
    Invoke-WebRequest "https://github.com/nix-community/NixOS-WSL/releases/latest/download/nixos.wsl" -OutFile $img
    wsl --install --from-file $img --name $Distro
    Remove-Item $img
}

# 4. TODO: install dotfiles inside the distro (approach pending)
wsl --shutdown  # apply .wslconfig
Write-Host "Done. Start with: wsl -d $Distro"
