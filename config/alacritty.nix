{...}: {
  # ── Alacritty ──
  # Primary terminal (Ghostty secondary).

  # Noctalia's sed rewrites this file; force lets HM relink it.
  xdg.configFile."alacritty/alacritty.toml".force = true;

  programs.alacritty = {
    enable = true;
    settings = {
      font.size = 15;
      font.normal = {
        family = "JetBrainsMono Nerd Font";
        style = "Regular";
      };
      # 256-color support in remote sessions.
      env.TERM = "xterm-256color";
      # Frosted-glass window with compositor-side blur.
      # window.opacity = 0.9;
      # window.blur = true;
      # Inner padding.
      window.padding = {
        x = 25;
        y = 10;
      };
      # 5 lines per scroll event.
      scrolling.multiplier = 5;
      # Auto-copy selection to clipboard.
      selection.save_to_clipboard = true;
      # Colors come from Noctalia's theme; no static block here.
      general.import = ["~/.config/alacritty/themes/noctalia.toml"];
    };
  };
}
