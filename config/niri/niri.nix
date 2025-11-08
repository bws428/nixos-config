{ pkgs, ... }:

{
  # Niri support packages
  home.packages = with pkgs; [
    fuzzel # default app launcher
    mako # notifications
    grim # screenshot
    slurp # screenshot
    swaybg # wallpaper
    swaylock # lock screen
    swayidle # idle daemon
    xwayland-satellite # xwayland support
  ];
}
