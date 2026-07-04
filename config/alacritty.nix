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
      # Noctalia's wallpaper-driven theme, mirroring the ghostty
      # arrangement (config/ghostty.nix). Declaring the import here
      # keeps the file's content stable when Noctalia's alacritty
      # post-hook runs: with the import already present, its sed
      # substitutes nothing. Note alacritty gives the importing file
      # precedence, so the static kape colors below override the
      # imported theme — identical today (the Noctalia palette IS
      # kape), but if the palette ever goes wallpaper-driven, drop
      # the colors block to let the import take over.
      general.import = [ "~/.config/alacritty/themes/noctalia.toml" ];
      # Kape color scheme — kept in sync with config/ghostty.nix.
      # https://github.com/gabiuz/kape
      colors = {
        primary = {
          background = "#181616";
          foreground = "#d4be98";
        };
        cursor = {
          text = "#181616";
          cursor = "#d4be98";
        };
        selection = {
          text = "#d4be98";
          background = "#2e2a2a";
        };
        normal = {
          black = "#181616";
          red = "#b53535";
          green = "#b4c76e";
          yellow = "#d99a4a";
          blue = "#7b8fd4";
          magenta = "#b06880";
          cyan = "#689d8a";
          white = "#c2c2c2";
        };
        bright = {
          black = "#2e2a2a";
          red = "#c94040";
          green = "#cad98a";
          yellow = "#e6ad60";
          blue = "#9aaae0";
          magenta = "#c8889a";
          cyan = "#89b8a8";
          white = "#d4be98";
        };
      };
    };
  };
}
