{ pkgs, ... }:

{
  # Dank Material Shell
  # https://danklinux.com

  programs.dankMaterialShell = {
    enable = true;
    quickshell.package = pkgs.quickshell;
    
    systemd = {
      enable = true;                   # Systemd service for auto-start
      restartIfChanged = true;         # Auto-restart dms.service
    };

    default.settings = {
      theme = "dark";
      dynamicTheming = true;
      useFahrenheit = true;
    };
  };
}
