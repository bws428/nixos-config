{ ... }:

{
  programs.rofi = {
    enable = true;
    theme = "Arc-Dark";

      extraConfig = {
        modi = "drun,run,window";
        show-icons = true;
        icon-theme = "Papirus-Dark";
        display-drun = "Applications";
        display-window = "Windows";
        drun-display-format = "{name}";
      };
  };
}
