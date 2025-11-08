{ config, pkgs, ... }:

{
  # User for Home Manager to manage
  home.username = "bws428";
  home.homeDirectory = "/home/bws428";

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  home.stateVersion = "25.05";

  # Let Home Manager install and manage itself
  programs.home-manager.enable = true;

  # Configurations to manage
  imports = [
    ./config/shell.nix
    ./config/helix.nix
    ./config/alacritty.nix
    ./config/niri.nix
    ./config/dms.nix
  ];

  # Niri helper packages
  home.packages = with pkgs; [
    fuzzel # default app launcher
    mako # notifications
    grim # screenshot
    slurp # screenshot
    swaybg # wallpaper
    swaylock # lock screen
    swayidle # idle daemon
    xwayland-satellite # xwayland support
  ];

}
