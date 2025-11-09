{ config, pkgs, lib, ... }:

{
  # Bootloader (systemd)
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Use LTS kernel (so that NVIDIA drivers will build)
  # https://wiki.nixos.org/wiki/Linux_kernel
  #boot.kernelPackages = pkgs.linuxPackages;

  # Latest kernel (probably won't work with NVIDIA?)
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Nix settings
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # System state version
  system.stateVersion = "25.05";
}
