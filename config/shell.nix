{ config, flakePath, ... }:

{
  # ── Zsh ────────────────────────────────────────────────────────────
  programs.zsh = {
    enable = true;

    # Store Zsh dotfiles under XDG_CONFIG_HOME instead of $HOME,
    # keeping the home directory clean.
    dotDir = "${config.xdg.configHome}/zsh";

    # Fish-style autosuggestions from command history (grey text).
    autosuggestion.enable = true;
    # Real-time syntax highlighting as you type.
    syntaxHighlighting.enable = true;
    # Keep the last 10,000 commands in history.
    history.size = 10000;

    shellAliases = {
      # Modern ls with icons and directories grouped first.
      ls = "eza -lh --group-directories-first --icons=auto";
      lsa = "ls -la";
      # One-shot rebuild: stage, commit, push, then switch.
      # Uses `nh os switch` (from programs.nh) which already knows
      # the flake path.
      rebuild = "cd ${flakePath} && git add . && git commit -m 'NixOS rebuild' && git push origin main && nh os switch";
      # Clean old generations, keeping only the 3 most recent.
      clean = "nh clean all --keep 3";
    };

    # Extra Zsh init sourced at the end of .zshrc.
    initContent = ''
      bindkey '^ ' autosuggest-accept  # Ctrl+Space to accept suggestion
      microfetch                        # Show system info on shell startup
    '';
  };

  # ── Starship prompt ────────────────────────────────────────────────
  # https://starship.rs
  # Minimal, fast, cross-shell prompt. This config follows the "Pure"
  # prompt style: user, host (SSH only), directory, git info, then a
  # colored prompt character that turns red on error.
  programs.starship = {
    enable = true;
    enableZshIntegration = true;

    settings = {
      format = "$username$hostname$directory$git_branch$git_status$character";

      character = {
        success_symbol = "[❯](purple)";
        error_symbol = "[❯](red)";
        vicmd_symbol = "[❮](green)";
      };

      username = {
        format = "[$user]($style) ";
        show_always = false;      # Only show in SSH or root sessions
      };

      hostname = {
        format = "[$hostname]($style) ";
        ssh_only = true;          # Only show when connected via SSH
      };

      directory = {
        format = "[$path]($style) ";
        truncation_length = 3;    # Show at most 3 path components
        truncate_to_repo = true;  # Truncate from the repo root
      };

      git_branch = {
        format = "[$symbol$branch]($style) ";
        symbol = "";              # No branch icon — just the name
      };

      git_status = {
        format = "([\\[$all_status$ahead_behind\\]]($style) )";
      };
    };
  };
}
