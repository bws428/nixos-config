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

  # XDG configuration directories
  xdg.enable = true;

  # Configure niri
  xdg.configFile."niri/config.kdl".source = ./config/niri/config.kdl;

  # Configurations to manage
  imports = [
    ./config/shell.nix
    ./config/helix.nix
    ./config/alacritty.nix
    ./config/niri/niri.nix
    ./config/dms.nix
  ];

  # Environment session variables
  home.sessionVariables = {
    GTK_THEME = "Adwaita:dark";
    QT_STYLE_OVERRIDE = "adwaita-dark";
    QT_QPA_PLATFORMTHEME = "gtk3";
  };
  
  # GTK theme (and icons!)
  gtk = {
    enable = true;
    theme = {
      name = "Adwaita-dark";
      package = pkgs.gnome-themes-extra;
    };
    iconTheme = {
      name = "Adwaita";
      package = pkgs.adwaita-icon-theme;
    };
  };
}
