{ lib, ... }:

{
  programs.waybar = {
    enable = true;
    # Last attempt before removing everything
    settings = {
      mainBar = {
        layer = "top";
        position = "top";
        modules-left = [ "dwl/tags" ];
        modules-center = [ "dwl/window" ];
        modules-right = [
          "tray"
          "network"
          "pulseaudio"
          "clock"
        ];
        "dwl/tags" = {
          num-tags = 9;
          hide-vacant = true;
          expand = false;
          tag-labels = [];
        };
        "dwl/window" = {
          format = "{title}";
          max-length = 50;
          rewrite = {};
        };
      };
    };

    # Stylix font override
    style = lib.mkAfter ''
      * {
        font-size: 16px;
        font-family: MesloLGS Nerd Font Propo;
      }
    '';
  };
}
