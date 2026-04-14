{ config, pkgs, flakePath, ... }:

{
  # Automatic system upgrades (with flakes)
  # https://wiki.nixos.org/wiki/Automatic_system_upgrades
  system.autoUpgrade = {
    enable = true;
    flake = "${flakePath}#ghost";
    flags = [
      "--print-build-logs"
    ];
    dates = "02:00";
    randomizedDelaySec = "45min";
  };

  # Pull latest commits and update flake inputs before rebuilding
  systemd.services.nixos-upgrade = {
    path = [ pkgs.git ];
    preStart = ''
      git config --global safe.directory ${flakePath}
      cd ${flakePath}
      git checkout -- flake.lock
      git pull
      nix flake update
    '';
  };

  # Automatic system cleanup
  # https://wiki.nixos.org/wiki/Storage_optimization
  nix.gc = {
    automatic = true;
    dates = "03:00";
    options = "--keep 3";
  };

  # Automatic system storage optimization
  nix.optimise.automatic = true;
}
