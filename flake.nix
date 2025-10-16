{
  description = "NixOS primary system configuration flake";

  inputs = {
    # NixOS official package source, using nixos-20.05 branch
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
  };

  outputs = { self, nixpkgs, ...}@inputs: {
    # System configuration - replace `ghost` with your hostname
    nixosConfigurations.ghost = nixpkgs.lib.nixosSystem {
      modules = [
        # Import legacy `configuration.nix` file
        ./configuration.nix
      ];
    };
  };
}
