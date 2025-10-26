{ ... }:

{
  programs.alacritty = {
    enable = true;
    theme = "catppuccin_macchiato";
    settings = {
      font.size = 16;
      font.normal = {
        family = "JetBrainsMono Nerd Font";
        style = "Regular";
      };
      env.TERM = "xterm-256color";
      window.opacity = 0.90;
      window.blur = true;
      scrolling.multiplier = 5;
      selection.save_to_clipboard = true;
    };
  };
}
