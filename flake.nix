{
  description = "NixOS primary system configuration";

  inputs = {
    # NixOS unstable branch
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # Home Manager
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Mango compositor
    mango.url = "github:DreamMaoMao/mango";

    # Dank Material Shell (Mango theme & tools)
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

  outputs = inputs @ { self, nixpkgs, home-manager, mango, dankMaterialShell,  ... }: {
    
    # NixOS system configuration ("ghost" is the hostname)
    nixosConfigurations.ghost = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs; };
          modules = [
            
            # NixOS system config
            ./configuration.nix
            
            # Home Manager ("bws428" is the username)
            home-manager.nixosModules.home-manager {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.backupFileExtension = "backup";
              home-manager.users.bws428 = {
                imports = [
                  ./home/home.nix
                  mango.hmModules.mango
                  dankMaterialShell.homeModules.dankMaterialShell.default
                ];
              };
            }
            
            # Mango compositor
            mango.nixosModules.mango
          ];
        };
      };
}
