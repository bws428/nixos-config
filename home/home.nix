{ config, pkgs, lib, ... }:

{
  imports = [
    ./modules/packages.nix
    ./modules/shell.nix
    ./modules/helix.nix
    ./modules/desktop/waybar.nix
    ./modules/desktop/rofi.nix
    ./modules/desktop/alacritty.nix
    ./modules/desktop/ghostty.nix
    ./modules/desktop/mango.nix
    ./modules/desktop/hyprland.nix
    ./modules/desktop/ashell.nix
    ./modules/desktop/dmshell.nix
  ];

  home.username = "bws428";
  home.homeDirectory = "/home/bws428";
  home.stateVersion = "25.05";

  # X resources for cursor/dpi
  xresources.properties = {
    "Xcursor.size" = 16;
    "Xft.dpi" = 172;
  };
}
