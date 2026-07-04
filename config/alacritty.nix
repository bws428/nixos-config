{ ... }:

{
  # ── Alacritty terminal emulator ────────────────────────────────────
  # GPU-accelerated terminal. Used as a secondary/fallback terminal
  # alongside Ghostty.

  # Noctalia's alacritty post-hook rewrites alacritty.toml with
  # `sed -i` on every theme apply, which replaces the HM symlink with
  # a regular file (GNU sed doesn't follow symlinks). Content stays
  # identical thanks to the import declared below, but HM would still
  # refuse to relink once a .hm-bak backup exists — that broke every
  # HM activation from 2026-07-04 10:02 until caught at 13:29. force
  # lets HM reclaim the file without the backup dance.
  xdg.configFile."alacritty/alacritty.toml".force = true;

  programs.alacritty = {
    enable = true;
    settings = {
      font.size = 15;
      font.normal = {
        family = "JetBrainsMono Nerd Font";
        style = "Regular";
      };
      # Ensure 256-color support in remote sessions.
      env.TERM = "xterm-256color";
      # Semi-transparent window with blur for a frosted-glass look.
      window.opacity = 0.9;
      window.blur = true;
      # Inner padding so text doesn't touch the window edges.
      window.padding = { x = 25; y = 10; };
      # Faster scrolling (5 lines per scroll event instead of default 3).
      scrolling.multiplier = 5;
      # Automatically copy selected text to the system clipboard.
      selection.save_to_clipboard = true;
      # Colors come entirely from Noctalia's wallpaper-driven theme,
      # mirroring the ghostty arrangement (config/ghostty.nix).
      # Declaring the import here keeps the file's content stable when
      # Noctalia's alacritty post-hook runs: with the import already
      # present, its sed substitutes nothing. No static colors block —
      # alacritty gives the importing file precedence, so declaring
      # colors here would override the Noctalia theme. Until the first
      # wallpaper apply on a fresh install, alacritty falls back to
      # its built-in defaults.
      general.import = [ "~/.config/alacritty/themes/noctalia.toml" ];
    };
  };
}
