{
  description = "NixOS primary system configuration flake";

  inputs = {
    # NixOS official package source, using nixos-20.05 branch
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    # MangoWC Wayland compositor
    mangowc = {
      url = "github:DreamMaoMao/mangowc";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, mangowc, ... }@inputs: {
    # NixOS system configuration - `ghost` is the hostname
    nixosConfigurations.ghost = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./configuration.nix
        mangowc.nixosModules.default
      ];
    };
  };
}
