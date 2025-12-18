{ config, pkgs, ... }:

{
  # Niri, a scrollable-tiling Wayland compositor
  # https://wiki.nixos.org/wiki/Niri
  programs.niri.enable = true;

  # Dank Material Shell
  # https://danklinux.com/
  programs.dms-shell = {
    enable = true;
    quickshell.package = pkgs.quickshell;
  };

  # Enable XWayland for compatibility (Steam, etc.)
  programs.xwayland.enable = true;

  # Gnome Display Manager (NixOS 25.11+)
  services.displayManager.gdm = {
    enable = true;
    wayland = true;
  };

  # Security
  security.polkit.enable = true;
  # security.pam.services.swaylock = {};

  # Keyring
  services.gnome.gnome-keyring.enable = true;
}
