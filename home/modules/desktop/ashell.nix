{ ... }:

{
  programs.ashell = {
    enable = true;
    settings = {
      appearance = {
        scale_factor = 1.3;
        style = "Solid";
        opacity = 0.9;
      };
      modules = {
        center = [ "Window Title" ];
        left = [ "Workspaces" ];
        right = [ "SystemInfo"
          [
            "Clock"
            "Privacy"
            "Settings"
          ]
        ];
         };
          workspaces = {};
        };
  };
}
