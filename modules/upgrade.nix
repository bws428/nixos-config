{ config, pkgs, ... }:

{
  # Automatic system upgrades (with flakes)
  # https://wiki.nixos.org/wiki/Automatic_system_upgrades
  system.autoUpgrade = {
    enable = true;
    flake = "github:bws428/nixos-config";
    flags = [
      "--print-build-logs"
      "--no-write-lock-file"
    ];
    dates = "02:00";
    randomizedDelaySec = "45min";
  };

  # Automatic system cleanup
  # https://wiki.nixos.org/wiki/Storage_optimization
  nix.gc = {
    automatic = true;
    dates = "03:00";
    options = "--delete-older-than 5d";
  };

  # Automatic system storage optimization
  nix.optimise.automatic = true;
}
