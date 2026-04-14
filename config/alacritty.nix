{ ... }:

{
  # ── Alacritty terminal emulator ────────────────────────────────────
  # GPU-accelerated terminal. Used as a secondary/fallback terminal
  # alongside Ghostty.
  programs.alacritty = {
    enable = true;
    # Pre-built color scheme from the alacritty-theme collection.
    theme = "github_dark";
    settings = {
      font.size = 15;
      font.normal = {
        family = "JetBrainsMono Nerd Font";
        style = "Regular";
      };
      # Ensure 256-color support in remote sessions.
      env.TERM = "xterm-256color";
      # Semi-transparent window with blur for a frosted-glass look.
      window.opacity = 0.85;
      window.blur = true;
      # Inner padding so text doesn't touch the window edges.
      window.padding = { x = 25; y = 10; };
      # Faster scrolling (5 lines per scroll event instead of default 3).
      scrolling.multiplier = 5;
      # Automatically copy selected text to the system clipboard.
      selection.save_to_clipboard = true;
    };
  };
}
