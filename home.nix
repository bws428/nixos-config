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
    # Custom DMS theme — Material 3 mapping of the kape palette
    # (https://github.com/gabiuz/kape). Select via DMS Settings →
    # Theme & Colors → Custom, then pick this file.
    "DankMaterialShell/themes/kape/theme.json".source =
      ./assets/themes/kape/theme.json;
    # Custom Zed theme — kape palette mapped onto Zed's theme schema.
    # Pick "Kape" via Zed's theme selector (Cmd-K Cmd-T).
    "zed/themes/kape.json".source = ./assets/themes/kape/zed.json;
  };

  # Obsidian themes live inside the vault, not under $XDG_CONFIG_HOME,
  # so they're symlinked via home.file (path is relative to $HOME).
  # Update the vault path here if the vault is renamed or moved.
  home.file = {
    "Documents/Obsidian/Notes/.obsidian/themes/Kape/manifest.json".source =
      ./assets/themes/kape/obsidian/manifest.json;
    "Documents/Obsidian/Notes/.obsidian/themes/Kape/theme.css".source =
      ./assets/themes/kape/obsidian/theme.css;
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
    ./config/btop.nix
    ./config/ghostty.nix
    ./config/tmux.nix
  ];

  # ── Session PATH additions ──────────────────────────────────────────
  # npm global installs land in ~/.npm-global/bin (see config/shell.nix
  # for the NPM_CONFIG_PREFIX variable that redirects them there).
  home.sessionPath = [ "$HOME/.npm-global/bin" ];

  # ── GTK theme + icon theme ─────────────────────────────────────────
  # Canonical HM shape (writes gtk-3.0/settings.ini, gtk-4.0/settings.ini,
  # .gtkrc-2.0). Replaces the older GTK_THEME env-var approach, which set
  # the widget theme but had no equivalent for `gtk-icon-theme-name` —
  # so app-icon lookups had nothing to prefer over (mostly-empty)
  # hicolor and rendered as broken-image placeholders.
  gtk = {
    enable = true;
    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.papirus-icon-theme;
    };
    theme = {
      name = "Adwaita-dark";
      package = pkgs.gnome-themes-extra;
    };
  };

  # ── Qt theme ───────────────────────────────────────────────────────
  # Route Qt apps through the GTK3 platform plugin so they pick up the
  # GTK theme above. Replaces QT_STYLE_OVERRIDE / QT_QPA_PLATFORMTHEME
  # env vars with the canonical HM module.
  qt = {
    enable = true;
    platformTheme.name = "gtk3";
  };
}
