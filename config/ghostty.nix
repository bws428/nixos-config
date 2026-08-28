{...}: {
  # ── Ghostty ──
  programs.ghostty = {
    enable = true;

    settings = {
      theme = "Catppuccin Macchiato";
      font-family = "JetBrainsMono Nerd Font";
      font-size = 15;
      # Frosted-glass window (disabled).
      # background-opacity = 0.9;
      # background-blur = true;
      # Inner padding.
      window-padding-x = 25;
      window-padding-y = 10;
      # Auto-copy selection to clipboard.
      copy-on-select = "clipboard";
    };
  };
}
