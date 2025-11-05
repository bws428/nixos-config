{ pkgs, ... }:

{
  # Dank Material Shell
  # https://danklinux.com

  programs.dankMaterialShell = {
    enable = true;

    # Core features
    enableSystemd = true;              # Systemd service for auto-start
    enableSystemMonitoring = true;     # System monitoring widgets (dgop)
    enableClipboard = true;            # Clipboard history manager
    enableVPN = true;                  # VPN management widget
    enableBrightnessControl = false;   # Backlight/brightness controls
    enableColorPicker = true;          # Color picker tool
    enableDynamicTheming = true;       # Wallpaper-based theming (matugen)
    enableAudioWavelength = true;      # Audio visualizer (cava)
    enableCalendarEvents = true;       # Calendar integration (khal)
    enableSystemSound = true;          # System sound effects

    default.settings = {
      theme = "dark";
      dynamicTheming = true;
      # Add any other settings here
    };

    default.session = {
      # Session state defaults
    };

  };
}
