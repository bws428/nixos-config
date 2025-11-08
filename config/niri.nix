{ pkgs, ... }:

{
  # Niri helper packages
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

  # Niri settings
  programs.niri.enable = true;
  programs.niri.settings = {
    outputs."eDP-1".scale = 2.0;
  };
}
