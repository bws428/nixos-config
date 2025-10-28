{ ... }:

{
  programs.ashell = {
    enable = true;
    settings = {
      appearance = {
        scale_factor = 1.5;
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
