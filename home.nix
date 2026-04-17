{ config, pkgs, ... }:

{
  # ── Home Manager identity ──────────────────────────────────────────
  # These tell Home Manager which user it manages and where their
  # home directory lives. Must match the NixOS user definition.
  home.username = "bws428";
  home.homeDirectory = "/home/bws428";

  # Analogous to system.stateVersion — tracks the Home Manager release
  # this config was originally written for. Prevents breaking changes
  # on upgrade. Do not change after initial setup.
  home.stateVersion = "25.05";

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  # ── XDG base directories ──────────────────────────────────────────
  # Enable XDG directory management ($XDG_CONFIG_HOME, etc.) so that
  # programs follow the XDG Base Directory Specification.
  xdg.enable = true;

  # Raw dotfiles that don't have a dedicated Home Manager module.
  # These are symlinked into ~/.config/ via the Nix store.
  xdg.configFile = {
    "niri/config.kdl".source = ./config/niri/config.kdl;
  };

  # ── Per-program configs ────────────────────────────────────────────
  # Each file in config/ is a Home Manager module that manages one
  # program's settings. Add new programs by creating config/<name>.nix
  # and appending it here.
  imports = [
    ./config/niri/niri.nix
    ./config/polkit.nix
    ./config/shell.nix
    ./config/helix.nix
    ./config/alacritty.nix
  ];

  # ── Environment session variables ──────────────────────────────────
  # Force dark theme for GTK and Qt apps across all desktop environments.
  home.sessionVariables = {
    GTK_THEME = "Adwaita:dark";
    QT_STYLE_OVERRIDE = "adwaita-dark";
    QT_QPA_PLATFORMTHEME = "gtk3";
  };
}
