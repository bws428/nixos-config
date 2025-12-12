{ pkgs, ... }:

{
  # Dank Material Shell
  # https://danklinux.com

  programs.dankMaterialShell = {
    enable = true;
    quickshell.package = pkgs.quickshell;
  };

  # programs.dankMaterialShell = {
  #   # Niri keybinds (requires sodiboo flake)
  #   niri = {
  #     enableKeybinds = true;   # Automatic keybinding configuration
  #     enableSpawn = true;      # Auto-start DMS with niri
  #   };

  #   # Core features
  #   systemd = {
  #     enable = true;                   # Systemd service for auto-start
  #     restartIfChanged = true;         # Auto-restart dms.service
  #   };
  #   enableSystemMonitoring = true;     # System monitoring widgets (dgop)
  #   enableVPN = true;                  # VPN management widget
  #   enableDynamicTheming = true;       # Wallpaper-based theming (matugen)
  #   enableAudioWavelength = true;      # Audio visualizer (cava)
  #   enableCalendarEvents = true;       # Calendar integration (khal)

  #   default.settings = {
  #     theme = "dark";
  #     dynamicTheming = true;
  #     useFahrenheit = true;
  #   };
  # };
}
