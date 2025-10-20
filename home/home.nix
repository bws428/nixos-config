{ config, pkgs, lib, ... }:

{
  imports = [
    ./modules/packages.nix
    ./modules/shell.nix
    ./modules/editors.nix
    ./modules/desktop/hyprland.nix
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

  # Global Stylix settings
  # Stylix fonts
  stylix.fonts = {
    monospace = {
      package = pkgs.nerd-fonts.meslo-lg;
      name = "MesloLGS Nerd Font Mono";
    };

    sansSerif = {
      package = pkgs.dejavu_fonts;
      name = "DejaVu Sans";
    };

    serif = {
      package = pkgs.dejavu_fonts;
      name = "DejaVu Serif";
    };

    sizes = {
      applications = 12;
      terminal = 14;
      desktop = 12;
      popups = 10;
    };
  };
  # Stylix targets
  stylix.targets.starship.enable = true;
  stylix.targets.helix.enable = true;
  stylix.targets.rofi.enable = true;
  stylix.targets.neovim.enable = true;
}
