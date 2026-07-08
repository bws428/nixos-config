{...}: {
  # ── btop — interactive resource monitor ────────────────────────────
  # Uses Noctalia's wallpaper-driven theme, written by its btop template
  # to ~/.config/btop/themes/noctalia.theme. Declaring it here (rather
  # than letting Noctalia sed it in) keeps btop.conf an intact HM
  # symlink: Noctalia's post-hook no-ops when color_theme is already
  # "noctalia". On a fresh install btop uses default colors until the
  # first wallpaper apply.
  programs.btop = {
    enable = true;
    settings = {
      color_theme = "noctalia";
      theme_background = false;
    };
  };
}
