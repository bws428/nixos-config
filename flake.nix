{
  description = "NixOS primary system configuration flake";

  inputs = {
    # NixOS official package source, using nixos-20.05 branch
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    # NixOS plymouth boot splash
    nixos-plymouth.url = "github:BeatLink/nixos-plymouth";
  };

  outputs = { self, nixpkgs, nixos-plymouth, ...}@inputs: {
    # NixOS system configuration - `ghost` is the hostname
    nixosConfigurations.ghost = nixpkgs.lib.nixosSystem {
      modules = [
        ./configuration.nix
        nixos-plymouth.nixosModules.default
      ];
      system = "x86_64-linux";
    };
  };
}
