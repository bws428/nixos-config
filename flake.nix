{
  description = "NixOS primary system configuration flake";

  inputs = {
    # NixOS official package source, using nixos-25.05 branch
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";

    # Add nixpkgs-unstable for packages not available in 25.05
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    # Add Home Manager
    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Add Stylix
    stylix.url = "github:nix-community/stylix/release-25.05";

    # Add Mango (provides NixOS and home-manager modules for mangowc)
    mango = {
      url = "github:DreamMaoMao/mango";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
  };

  outputs = inputs@{ self, nixpkgs, nixpkgs-unstable, home-manager, stylix, mango, ... }:
    let
      system = "x86_64-linux";

      # Create an overlay to make unstable packages available
      overlay-unstable = final: prev: {
        unstable = import nixpkgs-unstable {
          inherit system;
          config.allowUnfree = true;
        };
      };
    in {
      # NixOS system configuration - `ghost` is the hostname
      nixosConfigurations.ghost = nixpkgs.lib.nixosSystem {
        inherit system;

        specialArgs = {
          inherit inputs;
        };

        modules = [
          # Apply the unstable overlay
          ({ config, pkgs, ... }: {
            nixpkgs.overlays = [ overlay-unstable ];
          })

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

          # Mango (MangoWC compositor)
          mango.nixosModules.mango
        ];
      };
    };
}
