{ pkgs, ... }:

{
  # Dank Material Shell
  # https://danklinux.com

  programs.dankMaterialShell = {
    enable = true;
    quickshell.package = pkgs.quickshell; # Custom Quickshell version

    # Core features
    systemd = {
      enable = true;                   # Systemd service for auto-start
      restartIfChanged = true;         # Auto-restart dms.service
    };
    enableSystemMonitoring = true;     # System monitoring widgets (dgop)
    # enableClipboard = true;            # Clipboard history manager
    enableVPN = true;                  # VPN management widget
    # enableBrightnessControl = false;   # Backlight/brightness controls
    # enableColorPicker = true;          # Color picker tool
    enableDynamicTheming = true;       # Wallpaper-based theming (matugen)
    enableAudioWavelength = true;      # Audio visualizer (cava)
    enableCalendarEvents = true;       # Calendar integration (khal)
    # enableSystemSound = true;          # System sound effects

    default.settings = {
      theme = "dark";
      dynamicTheming = true;
      useFahrenheit = true;
      # Add any other settings here
    };

    default.session = {
      # Session state defaults
    };

  };
}
