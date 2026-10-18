# Install NixOS-WSL (https://github.com/nix-community/NixOS-WSL) and configure WSL networking.
# Run from an elevated PowerShell. Re-runnable: skips steps that are already done.
param([string]$Distro = "NixOS")
$ErrorActionPreference = "Stop"

# Native commands don't trip $ErrorActionPreference, so check exit codes explicitly
function Invoke-Wsl {
    wsl @args
    if ($LASTEXITCODE -ne 0) { throw "wsl $args failed with exit code $LASTEXITCODE" }
}

# 1. WSL itself (no default distro); needs WSL >= 2.4.4 for --from-file
wsl --install --no-distribution
wsl --update

# 2. Mirrored networking: WSL and Windows share localhost, so a dev server on
#    0.0.0.0/127.0.0.1:PORT in WSL opens at http://localhost:PORT in a Windows browser
$cfg = "$env:USERPROFILE\.wslconfig"
if (-not ((Test-Path $cfg) -and (Select-String -Path $cfg -Pattern "networkingMode" -Quiet))) {
    Add-Content $cfg "[wsl2]`nnetworkingMode=mirrored"
}

# 3. NixOS distro from the latest release image
if (-not ((wsl -l -q) -replace "`0" -contains $Distro)) {
    $img = "$env:TEMP\nixos.wsl"
    Invoke-WebRequest "https://github.com/nix-community/NixOS-WSL/releases/latest/download/nixos.wsl" -OutFile $img
    Invoke-Wsl --install --from-file $img --name $Distro
    Remove-Item $img
}

# 4. Apply the flake straight from GitHub (no git needed yet). Uses `boot` + restart
#    because it renames the default user (nixos -> josh), per the NixOS-WSL docs.
$flake = "github:joshua-dean/dotfiles/nixos-wsl#nixos"
Invoke-Wsl -d $Distro -- sudo nixos-rebuild boot --refresh --flake $flake --option experimental-features "nix-command flakes"
wsl --shutdown  # also applies .wslconfig
wsl -d $Distro --user root exit
wsl -t $Distro

# 5. Clone the repo inside WSL; Home Manager's symlinks point at this checkout
Invoke-Wsl -d $Distro -- bash -c '[ -d ~/code/dotfiles ] || git clone -b nixos-wsl https://github.com/joshua-dean/dotfiles ~/code/dotfiles'
Write-Host "Done. Start with: wsl -d $Distro"
