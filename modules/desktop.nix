{ config, pkgs, ... }:

{
  # Niri compositor
  programs.niri.enable = true;

  # Enable XWayland for compatibility (Steam, etc.)
  programs.xwayland.enable = true;

  # Gnome Display Manager (NixOS 25.11+)
  services.displayManager.gdm = {
    enable = true;
    wayland = true;
  };

  # Security
  security.polkit.enable = true;
  security.pam.services.swaylock = {}; # needed with DMS?

  # Keyring
  services.gnome.gnome-keyring.enable = true;

  # Power management for desktop shell
  services.power-profiles-daemon.enable = true;
  services.upower.enable = true;

}
