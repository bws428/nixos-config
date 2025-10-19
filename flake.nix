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

    # Stylix auto-themer
    stylix.url = "github:nix-community/stylix";
  };

  outputs = inputs@{ self, nixpkgs, home-manager, mango, stylix, ... }: {
    # NixOS system configuration ("ghost" is the hostname)
    nixosConfigurations.ghost = nixpkgs.lib.nixosSystem {
          modules = [
            # NixOS system config
            ./configuration.nix
            # Home Manager ("bws428" is the username)
            home-manager.nixosModules.home-manager {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.backupFileExtension = "backup";
              home-manager.users.bws428 = import ./home/home.nix;

              imports = [ mango.hmModules.mango ];
            }
            # Mango compositor
            mango.nixosModules.mango
            # Stylix
            stylix.nixosModules.stylix
          ];
        };
      };
}
