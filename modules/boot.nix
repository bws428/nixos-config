{ config, pkgs, lib, ... }:

{
  # Bootloader (systemd)
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Bootloader configuration
  boot.loader.timeout = 5;  # 3 second timeout

  # Choose Linux kernel packages (LTS or latest)
  # boot.kernelPackages = pkgs.linuxPackages;
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Nix settings
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # System state version
  system.stateVersion = "25.05";
}
