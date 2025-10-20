{ ... }:

{
  programs.alacritty = {
    enable = true;
    theme = "gruvbox_material_hard_dark";
    settings = {
      env.TERM = "xterm-256color";
      scrolling.multiplier = 5;
      selection.save_to_clipboard = true;
    };
  };
}
