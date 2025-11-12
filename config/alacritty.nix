{ ... }:

{
  programs.alacritty = {
    enable = true;
    # theme = "autumn";
    settings = {
      font.size = 15;
      font.normal = {
        family = "JetBrainsMono Nerd Font";
        style = "Regular";
      };
      env.TERM = "xterm-256color";
      window.opacity = 0.85;
      window.blur = true;
      window.padding = { x = 20; y = 20; };
      scrolling.multiplier = 5;
      selection.save_to_clipboard = true;
    };
  };
}
