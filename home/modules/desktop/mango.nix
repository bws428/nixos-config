{ pkgs, ... }:

{
  wayland.windowManager.mango = {
    enable = true;
    settings = ''
        # see config.conf
    '';
    };
}
