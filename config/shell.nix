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
      # Clean old generations, keeping only the 5 most recent.
      clean = "nh clean all --keep 5";
    };

    # Extra Zsh init sourced at the end of .zshrc.
    initContent = ''
      bindkey '^ ' autosuggest-accept  # Ctrl+Space to accept suggestion
      microfetch                        # Show system info on shell startup

      # One-shot rebuild: stage and commit if there are local changes,
      # push, then `nh os switch`. A function rather than an alias so
      # the commit step is skipped cleanly when the tree is already
      # clean (e.g. right after `git pull`) instead of aborting the
      # whole chain. Uses `nh os switch` (from programs.nh), which
      # already knows the flake path.
      rebuild() {
        cd "${flakePath}" || return
        git add .
        if ! git diff --cached --quiet; then
          git commit -m 'NixOS rebuild' && git push origin main || return
        fi
        nh os switch
      }
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
