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

  # XDG configuration directories
  xdg.enable = true;

  # Configure niri
  xdg.configFile."niri/config.kdl".source = ./config/niri/config.kdl;

}
