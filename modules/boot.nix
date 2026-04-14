{ config, pkgs, ... }:

{
  # Bootloader (systemd)
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Bootloader configuration
  boot.loader.timeout = 5;

  # Linux LTS kernel (best stability with Nvidia drivers)
  boot.kernelPackages = pkgs.linuxPackages;

  # Nix settings (use flakes)
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # System state version
  system.stateVersion = "25.05";
}
