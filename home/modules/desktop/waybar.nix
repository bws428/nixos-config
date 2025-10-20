{ lib, ... }:

{
  programs.waybar = {
    enable = true;
    # Last attempt before removing everything
    settings = {

    };
    # Font override
    style = lib.mkAfter ''
      * {
        font-size: 16px;
        font-family: MesloLGS Nerd Font Propo;
      }
    '';
  };
}
