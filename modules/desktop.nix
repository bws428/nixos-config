{ config, pkgs, ... }:

{
  # Niri compositor
  programs.niri.enable = true;

  # Hyprland compositor
  programs.hyprland.enable = true;

  # Enable XWayland for compatibility (Steam, etc.)
  programs.xwayland.enable = true;

  # Gnome Display Manager (NixOS 25.11+)
  # https://wiki.nixos.org/wiki/GNOME
  services.displayManager.gdm = {
    enable = true;
    wayland = true;
  };

  # Gnome Desktop Manager
  services.desktopManager.gnome.enable = true;

  # # Gnome default application suite
  # services.gnome = {
  #   games.enable = false;
  #   core-apps.enable = false;
  #   core-developer-tools.enable = false;
  # };

  # # Exclude unwanted Gnome packages
  # environment.gnome.excludePackages = with pkgs; [
  #   gnome-tour gnome-user-docs
  # ];

  # Security
  security.polkit.enable = true;
  security.pam.services.swaylock = {}; # needed with DMS?

  # Keyring
  services.gnome.gnome-keyring.enable = true;

  # I need to understand what this does
  # System fails to rebuild without it
  services.dbus.implementation = "broker";

}
