{ pkgs, ... }:

{
  # Niri support packages
  home.packages = with pkgs; [
    fuzzel # default app launcher
    xwayland-satellite # xwayland support
  ];
}
