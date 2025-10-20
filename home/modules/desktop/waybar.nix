{ lib, ... }:

{
  programs.waybar = {
    enable = true;

  settings = ''''

    # Font override
    style = lib.mkAfter ''
      * {
        font-size: 16px;
        font-family: MesloLGS Nerd Font Propo;
      }
    '';
  };
}
