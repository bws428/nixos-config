{
  description = "NixOS primary system configuration";

  inputs = {
    # NixOS official package source, unstable branch
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # Add Home Manager
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Add Stylix
    stylix = {
      url = "github:nix-community/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Add MangoWC
    mangowc = {
      url = "github:DreamMaoMao/mangowc";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ self, nixpkgs, home-manager, stylix, mangowc, ... }: {
    # NixOS system configuration - `ghost` is the hostname
    nixosConfigurations.ghost = nixpkgs.lib.nixosSystem {
      modules = [
        # Legacy NixOS config file
        ./configuration.nix

        # Home Manager module
        home-manager.nixosModules.home-manager {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.backupFileExtension = "backup";
            home-manager.users.bws428 = import ./home/home.nix;
        }

        # Stylix
        stylix.nixosModules.stylix

        # MangoWC
        mangowc.nixosModules.default
      ];
    };
  };
}
