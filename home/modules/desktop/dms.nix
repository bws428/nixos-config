{ pkgs, ... }:

{
  programs.dankMaterialShell = {
    enable = true;
    niri = {
      enableKeybinds = true;  # Automatic keybinding configuration
      enableSpawn = true;      # Auto-start DMS with niri
    };
  };
}
