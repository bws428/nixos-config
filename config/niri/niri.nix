{ pkgs, ... }:

{
  # Niri support packages
  home.packages = with pkgs; [
    fuzzel # default app launcher
    mako # notifications
    grim # screenshot
    slurp # screenshot
    xwayland-satellite # xwayland support
  ];
}
