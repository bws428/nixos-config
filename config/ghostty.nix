{ ... }:

{
  # ── Ghostty terminal emulator ──────────────────────────────────────
  # Primary terminal. Font size, padding, and transparency mirror the
  # alacritty config (config/alacritty.nix) so the two terminals feel
  # interchangeable.
  # https://ghostty.org/docs/config/reference
  programs.ghostty = {
    enable = true;

    # Inline custom theme. HM writes this to
    # ~/.config/ghostty/themes/kape and validates it via ghostty
    # +validate-config on every rebuild.
    # Source: https://github.com/gabiuz/kape/blob/main/ports/ghostty/kape
    themes.kape = {
      background = "181616";
      foreground = "d4be98";
      cursor-color = "d4be98";
      selection-background = "2e2a2a";
      selection-foreground = "d4be98";
      palette = [
        "0=#181616"
        "1=#b53535"
        "2=#b4c76e"
        "3=#d99a4a"
        "4=#7b8fd4"
        "5=#b06880"
        "6=#689d8a"
        "7=#c2c2c2"
        "8=#2e2a2a"
        "9=#c94040"
        "10=#cad98a"
        "11=#e6ad60"
        "12=#9aaae0"
        "13=#c8889a"
        "14=#89b8a8"
        "15=#d4be98"
      ];
    };

    settings = {
      # Noctalia's wallpaper-driven theme, written by its ghostty
      # template to ~/.config/ghostty/themes/noctalia. Declaring it here
      # (rather than letting Noctalia sed it in) keeps this file an
      # intact HM symlink: Noctalia's post-hook no-ops when the theme is
      # already "noctalia". On a fresh install ghostty falls back to
      # default colors until the first wallpaper apply. The static kape
      # theme above is kept as a manual fallback (theme = "kape").
      theme = "noctalia";
      font-family = "JetBrainsMono Nerd Font";
      font-size = 15;
      # Frosted-glass window, matching alacritty.
      background-opacity = 0.9;
      background-blur = true;
      # Inner padding so text doesn't touch the edges.
      window-padding-x = 25;
      window-padding-y = 10;
      # Auto-copy selection to the system clipboard (alacritty parity).
      copy-on-select = "clipboard";
    };
  };
}
