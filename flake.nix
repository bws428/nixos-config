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

    # Zen browser
    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Dank Material Shell
    dgop = {
      url = "github:AvengeMedia/dgop";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    dms-cli = {
      url = "github:AvengeMedia/danklinux";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    dankMaterialShell = {
      url = "github:AvengeMedia/DankMaterialShell";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.dgop.follows = "dgop";
      inputs.dms-cli.follows = "dms-cli";
    };

  };

  outputs = inputs @ { self, nixpkgs, home-manager, zen-browser, ... }: {
    nixosConfigurations.ghost = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs; };
          modules = [
            # NixOS legacy system config
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
                home-manager.extraSpecialArgs = { inherit inputs; system = "x86_64-linux";};
              };
            }
          ];
        };
      };
}
