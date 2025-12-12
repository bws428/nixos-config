{ pkgs, ... }:

{
  # Niri support packages
  home.packages = with pkgs; [
    # Most of these aren't needed with DMS working...
    mako # notification daemon
    waybar # desktop menu bar
    swaybg # desktop wallpaper
    swayidle # idle management
    swaylock # lockscreen
    mako # notification daemon
    fuzzel # default app launcher
    walker # better app launcher
    xwayland-satellite # xwayland support
  ];

  # Niri services
  services.mako.enable = true;
  services.swayidle.enable = true;
}
