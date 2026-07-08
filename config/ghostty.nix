{ ... }:

{
  # ── Ghostty terminal emulator ──────────────────────────────────────
  # Primary terminal. Font size, padding, and transparency mirror the
  # alacritty config (config/alacritty.nix) so the two terminals feel
  # interchangeable.
  # https://ghostty.org/docs/config/reference
  programs.ghostty = {
    enable = true;

    settings = {
      # Noctalia's wallpaper-driven theme, written by its ghostty
      # template to ~/.config/ghostty/themes/noctalia. Declaring it here
      # (rather than letting Noctalia sed it in) keeps this file an
      # intact HM symlink: Noctalia's post-hook no-ops when the theme is
      # already "noctalia". On a fresh install ghostty falls back to
      # default colors until the first wallpaper apply.
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
