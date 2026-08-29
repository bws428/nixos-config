{
  config,
  flakePath,
  ...
}: {
  # ── Zsh ────────────────────────────────────────────────────────────
  programs.zsh = {
    enable = true;

    # Keep zsh dotfiles under XDG_CONFIG_HOME.
    dotDir = "${config.xdg.configHome}/zsh";

    # Fish-style autosuggestions from command history (grey text).
    autosuggestion.enable = true;
    # Real-time syntax highlighting as you type.
    syntaxHighlighting.enable = true;
    # Keep the last 10,000 commands in history.
    history.size = 10000;

    shellAliases = {
      # Use eza, but don't alias `ls`; the LLMs hate it
      lsa = "eza -la";
      lsl = "eza -l";
      # Zed editor
      zed = "zeditor";
    };

    # Redirect npm global installs to a writable directory.
    # The Nix store is read-only, so `npm install -g` fails without this.
    sessionVariables = {
      NPM_CONFIG_PREFIX = "$HOME/.npm-global";
    };

    # Extra Zsh init sourced at the end of .zshrc.
    initContent = ''
      bindkey '^ ' autosuggest-accept  # Ctrl+Space to accept suggestion
      microfetch                       # system info on shell startup
      fortune                          # greeting

      # Warn when a newer generation is built but not booted.
      if [[ "$(readlink -f /nix/var/nix/profiles/system 2>/dev/null)" \
         != "$(readlink -f /run/booted-system 2>/dev/null)" ]]; then
        print -P "\n%F{yellow}NixOS has been updated. Please reboot for the changes to take effect.%f"
      fi

      # One-shot rebuild: commit, switch, push only on success.
      # `git add .` must precede the build (git fetcher ignores untracked).
      # Arg = commit message: rebuild "gc: fix flags"
      rebuild() {
        cd "${flakePath}" || return
        git add .
        if ! git diff --cached --quiet; then
          git commit -m "''${1:-NixOS rebuild}" || return
        fi
        nh os switch && git push origin main
      }
    '';
  };

  # ── Starship prompt ──
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
        show_always = false; # Only show in SSH or root sessions
      };

      hostname = {
        format = "[$hostname]($style) ";
        ssh_only = true; # Only show when connected via SSH
      };

      directory = {
        format = "[$path]($style) ";
        truncation_length = 3; # Show at most 3 path components
        truncate_to_repo = true; # Truncate from the repo root
      };

      git_branch = {
        format = "[$symbol$branch]($style) ";
        symbol = ""; # No branch icon — just the name
      };

      git_status = {
        format = "([\\[$all_status$ahead_behind\\]]($style) )";
      };
    };
  };
}
