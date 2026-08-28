{pkgs, ...}: {
  # ── Niri packages ──
  # Only XWayland support; Noctalia provides bar/launcher/etc.
  home.packages = with pkgs; [
    xwayland-satellite # Rootless XWayland (X11 app compat)
  ];
}
