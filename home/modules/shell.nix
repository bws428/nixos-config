{ ... }:

{
  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    
    shellAliases = {
      ls = "eza -lh --group-directories-first --icons=auto";
      rebuild = "sudo nixos-rebuild switch";
    };
    
    initContent = ''
      bindkey '^ ' autosuggest-accept  # Ctrl+Space
    '';
  };

  programs.starship = {
    enable = true;
    enableZshIntegration = true;

    settings = {
      # Pure preset format
      format = "$username$hostname$directory$git_branch$git_status$character";

      # Pure-style components
      character = {
        success_symbol = "[❯](purple)";
        error_symbol = "[❯](red)";
        vicmd_symbol = "[❮](green)";
      };

      username = {
        format = "[$user]($style) ";
        show_always = false;
      };

      hostname = {
        format = "[$hostname]($style) ";
        ssh_only = true;
      };

      directory = {
        format = "[$path]($style) ";
        truncation_length = 3;
        truncate_to_repo = true;
      };

      git_branch = {
        format = "[$symbol$branch]($style) ";
        symbol = "";
      };

      git_status = {
        format = "([\\[$all_status$ahead_behind\\]]($style) )";
      };
    };
  };
}
