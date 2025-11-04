{ pkgs, ... }:

{
  # Niri required packages
  home.packages = with pkgs; [
    fuzzel
  ];
}
