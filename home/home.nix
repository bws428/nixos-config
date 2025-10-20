{ config, pkgs, lib, ... }:

{
  imports = [
    ./modules/packages.nix
    ./modules/shell.nix
    ./modules/editors.nix
    #./modules/desktop/hyprland.nix
    ./modules/desktop/waybar.nix
    ./modules/desktop/rofi.nix
    ./modules/desktop/alacritty.nix
    ./modules/desktop/mango.nix
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
