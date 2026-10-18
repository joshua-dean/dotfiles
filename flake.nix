# NixOS-WSL system. Rebuild: sudo nixos-rebuild switch --flake ~/code/dotfiles#nixos
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    nixos-wsl.url = "github:nix-community/NixOS-WSL/release-26.05";
    nixos-wsl.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager/release-26.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    {
      nixpkgs,
      nixos-wsl,
      home-manager,
      ...
    }:
    {
      nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
        modules = [
          nixos-wsl.nixosModules.default
          home-manager.nixosModules.home-manager
          ({ pkgs, ... }: {
            nixpkgs.hostPlatform = "x86_64-linux";
            system.stateVersion = "26.05";
            wsl.enable = true;
            wsl.defaultUser = "josh";
            security.sudo.wheelNeedsPassword = false;
            nix.settings.experimental-features = [
              "nix-command"
              "flakes"
            ];
            environment.systemPackages = [ pkgs.git ];
            programs.bash.blesh.enable = true; # fish-style autosuggestions in bash
            programs.nix-ld.enable = true; # run prebuilt binaries: VS Code server, uv-managed Python

            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.backupFileExtension = "bak";
            home-manager.users.josh = import ./home.nix;
          })
        ];
      };
    };
}
