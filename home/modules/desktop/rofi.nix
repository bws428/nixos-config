{ ... }:

{
  programs.rofi = {
    enable = true;
    theme = "material";

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
