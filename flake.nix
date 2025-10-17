{
  description = "NixOS primary system configuration flake";

  inputs = {
    # NixOS official package source, using nixos-20.05 branch
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
  };

  outputs = { self, nixpkgs, ...}@inputs: {
    # NixOS system configuration - `ghost` is the hostname
    nixosConfigurations.ghost = nixpkgs.lib.nixosSystem {
      modules = [
        ./configuration.nix
      ];
    };
  };
}
