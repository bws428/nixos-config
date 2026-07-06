{ pkgs, ... }:

{
  # ── Niri support packages ──────────────────────────────────────────
  # Niri is a scrollable-tiling Wayland compositor with no built-in
  # shell components. Noctalia (config/noctalia/noctalia.nix) provides the bar,
  # notifications, wallpaper, launcher, and idle/lock screen, so the
  # only companion package Niri needs is XWayland support.
  home.packages = with pkgs; [
    xwayland-satellite  # Rootless XWayland for Niri (X11 app compat)
  ];
}
