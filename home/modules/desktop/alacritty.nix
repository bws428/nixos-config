{ ... }:

{
  programs.alacritty = {
    enable = true;
    
    settings = {
      env.TERM = "xterm-256color";
      
      scrolling.multiplier = 5;
      
      selection.save_to_clipboard = true;
    };
  };
}
