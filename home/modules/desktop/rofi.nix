{ ... }:

{
  programs.rofi = {
    enable = true;
    theme = "~/.config/rofi/launchers/type-4/style-5.rasi";

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
