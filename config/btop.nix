{ ... }:

{
  # ── btop — interactive resource monitor ────────────────────────────
  # Uses Noctalia's wallpaper-driven theme, written by its btop template
  # to ~/.config/btop/themes/noctalia.theme. Declaring it here (rather
  # than letting Noctalia sed it in) keeps btop.conf an intact HM
  # symlink: Noctalia's post-hook no-ops when color_theme is already
  # "noctalia". The static kape theme stays installed as a manual
  # fallback (color_theme = "kape").
  # Kape source: https://github.com/gabiuz/kape/blob/main/ports/btop/kape.theme
  programs.btop = {
    enable = true;
    themes.kape = ./../assets/themes/kape/btop.theme;
    settings = {
      color_theme = "noctalia";
      theme_background = false;
    };
  };
}
