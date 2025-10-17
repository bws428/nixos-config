{
  description = "NixOS primary system configuration flake";

  inputs = {
    # NixOS official package source, using nixos-20.05 branch
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    # Add Home Manager
    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ self, nixpkgs, home-manager, ... }: {
    # NixOS system configuration - `ghost` is the hostname
    nixosConfigurations.ghost = nixpkgs.lib.nixosSystem {
      modules = [
        # Legacy NixOS config file
        ./configuration.nix
        # Home Manager module
        home-manager.nixosModules.home-manager {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.bws428 = import ./home.nix;
        }
      ];
    };
  };
}
