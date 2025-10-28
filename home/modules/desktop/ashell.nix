{ ... }:

{
  programs.ashell = {
    enable = true;
    settings = {
      appearance = {
        scale_factor = 1.2;
        style = "Solid";
        opacity = 0.8;
      };
      modules = {
        center = [ "WindowTitle" ];
        left = [ "Workspaces" ];
        right = [ "Tray" "SystemInfo" [ "Clock" "Settings" ] ];
      };
      workspaces = {
        
      };
    };
  };
}
