{
  config,
  pkgs,
  ...
}: {
  # ── Identity ──
  home.username = "bws428";
  home.homeDirectory = "/home/bws428";

  # Do not change after initial setup.
  home.stateVersion = "25.05";

  programs.home-manager.enable = true;

  # ── XDG ──
  xdg.enable = true;

  # Raw dotfiles symlinked into ~/.config.
  xdg.configFile = {
    "niri/config.kdl".source = ./config/niri/config.kdl;
  };

  # ── Per-program configs ──
  # Each file in config/ manages one program; add new ones here.
  imports = [
    ./config/niri/niri.nix
    ./config/noctalia/noctalia.nix
    ./config/shell.nix
    ./config/helix.nix
    ./config/alacritty.nix
    ./config/btop.nix
    ./config/ghostty.nix
    ./config/tmux.nix
    ./config/mpd.nix
    ./config/beets.nix
    ./config/herdr.nix
  ];

  # ── Session PATH ──
  # npm global + user-local binaries.
  home.sessionPath = [
    "$HOME/.npm-global/bin"
    "$HOME/.local/bin"
  ];

  # ── Cursor ──
  home.pointerCursor = {
    enable = true;
    gtk.enable = true;
    package = pkgs.adwaita-icon-theme;
    name = "Adwaita";
    size = 24;
    # Keep ~/.icons manual symlink intact (HM writes collide).
    dotIcons.enable = false;
  };

  # ── GTK + icons ──
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
    # Post-26.05 default: no theme name pushed into GTK4.
    gtk4.theme = null;
  };

  # ── Dark mode ──
  dconf.settings."org/gnome/desktop/interface".color-scheme = "prefer-dark";

  # ── Qt ──
  # Route Qt apps through the GTK3 plugin.
  qt = {
    enable = true;
    platformTheme.name = "gtk3";
  };
}
