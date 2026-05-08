{ ... }:

{
  # ── btop — interactive resource monitor ────────────────────────────
  # Uses the kape theme (themes.<name> writes to
  # ~/.config/btop/themes/<name>.theme; color_theme references it by name).
  # Source: https://github.com/gabiuz/kape/blob/main/ports/btop/kape.theme
  programs.btop = {
    enable = true;
    themes.kape = ./../assets/themes/kape/btop.theme;
    settings = {
      color_theme = "kape";
      theme_background = false;
    };
  };
}
