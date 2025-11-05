{ config, pkgs, lib, inputs, ... }:

{
  # User for Home Manager to manage
  home.username = "bws428";
  home.homeDirectory = "/home/bws428";

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  home.stateVersion = "25.05";

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
    ./modules/desktop/niri.nix
    ./modules/desktop/ashell.nix
    ./modules/desktop/noctalia.nix
  ];

}
