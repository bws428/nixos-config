{
  description = "NixOS configuration with Home Manager";

  inputs = {
    # NixOS unstable branch
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # Home Manager
    home-manager = {
      url = "github:nix-community/home-manager";
    };

    # Dank Material Shell
    dgop = {
      url = "github:AvengeMedia/dgop";
    };

    dms-cli = {
      url = "github:AvengeMedia/danklinux";
    };

    dankMaterialShell = {
      url = "github:AvengeMedia/DankMaterialShell";
      inputs.dgop.follows = "dgop";
      inputs.dms-cli.follows = "dms-cli";
    };

  };

  outputs = inputs @ { self, nixpkgs, home-manager, ... }: {
    nixosConfigurations.ghost = nixpkgs.lib.nixosSystem {
          modules = [
            # Hardware
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

            # NixOS legacy config file
            # TODO: phase this out
            ./configuration.nix

            # Home Manager ("bws428" is the username)
            home-manager.nixosModules.home-manager {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.backupFileExtension = "backup";
              home-manager.users.bws428 = {
                imports = [
                  ./home/home.nix
                  inputs.dankMaterialShell.homeModules.dankMaterialShell.default
                ];
              };
            }
          ];
        };
      };
}
