{ config, pkgs, lib, ... }:

{
  imports = [
    ./modules/packages.nix
    ./modules/shell.nix
    ./modules/editors.nix
    ./modules/desktop/hyprland.nix
    ./modules/desktop/waybar.nix
    ./modules/desktop/alacritty.nix
  ];

  home.username = "bws428";
  home.homeDirectory = "/home/bws428";
  home.stateVersion = "25.05";

  # X resources for cursor/dpi
  xresources.properties = {
    "Xcursor.size" = 16;
    "Xft.dpi" = 172;
  };

  # Global Stylix settings
  stylix.targets.starship.enable = true;
  stylix.targets.helix.enable = true;
}
