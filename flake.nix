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

    # Mango compositor
    mango = {
      url = "github:DreamMaoMao/mango";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Niri compositor
    niri = {
      url = "github:YaLTeR/niri";
      inputs.nixpkgs.follows = "nixpkgs";
    };

  };

  outputs = inputs @ { self, nixpkgs, home-manager, mango, niri, ... }: {

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
                ];
              };
            }

            # Mango compositor
            mango.nixosModules.mango

          ];
        };
      };
}
