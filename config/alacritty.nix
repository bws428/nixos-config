{ ... }:

{
  # ── Alacritty terminal emulator ────────────────────────────────────
  # GPU-accelerated terminal. Used as a secondary/fallback terminal
  # alongside Ghostty.
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
