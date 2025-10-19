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

    # What is flake-parts?
    flake-parts.url = "github:hercules-ci/flake-parts";

    # Mango compositor
    mango.url = "github:DreamMaoMao/mango";
  };

    outputs =
        inputs@{ self, flake-parts, ... }:
        flake-parts.lib.mkFlake { inherit inputs; } {
          debug = true;
          systems = [ "x86_64-linux" ];
          flake = {
            nixosConfigurations = {
              hostname = inputs.nixpkgs.lib.nixosSystem {
                system = "x86_64-linux";
                modules = [
                  inputs.home-manager.nixosModules.home-manager

                  # Add mango nixos module
                  inputs.mango.nixosModules.mango
                  {
                    programs.mango.enable = true;
                  }
                  {
                    home-manager = {
                      useGlobalPkgs = true;
                      useUserPackages = true;
                      backupFileExtension = "backup";
                      users."username".imports =
                        [
                          (
                            { ... }:
                            {
                              wayland.windowManager.mango = {
                                enable = true;
                                settings = ''
                                  # see config.conf
                                '';
                                autostart_sh = ''
                                  # see autostart.sh
                                  # Note: here no need to add shebang
                                '';
                              };
                            }
                          )
                        ]
                        ++ [
                          # Add mango hm module
                          inputs.mango.hmModules.mango
                        ];
                    };
                  }
                ];
              };
            };
          };
        };
}
