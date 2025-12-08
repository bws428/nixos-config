{
  description = "NixOS configuration with Home Manager";

  inputs = {
    # NixOS unstable branch
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # Home Manager
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Dank Material Shell
    dgop = {
      url = "github:AvengeMedia/dgop";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    quickshell = {
      url = "git+https://git.outfoxxed.me/outfoxxed/quickshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    dankMaterialShell = {
      url = "github:AvengeMedia/DankMaterialShell";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.dgop.follows = "dgop";
    };
  };

  outputs = inputs @ { self, nixpkgs, home-manager, ... }: {
    nixosConfigurations.ghost = nixpkgs.lib.nixosSystem {
          modules = [
            # Hardware configuration
            ./hardware-configuration.nix

            # System modules
            ./modules/boot.nix
            ./modules/users.nix
            ./modules/locale.nix
            ./modules/nvidia.nix
            ./modules/networking.nix
            ./modules/bluetooth.nix
            ./modules/services.nix
            ./modules/upgrade.nix

            # Desktop environments
            ./modules/desktop.nix

            # Installed fonts & packages
            ./modules/fonts.nix
            ./modules/packages.nix

            # Home Manager ("bws428" is the username)
            home-manager.nixosModules.home-manager {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.bws428 = {
                imports = [
                  ./home.nix
                  inputs.dankMaterialShell.homeModules.dankMaterialShell.default
                  # inputs.dankMaterialShell.homeModules.dankMaterialShell.niri
                ];
              };
            }
          ];
        };
      };
}
