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
      microfetch                        # Show system info on shell startup

      # Warn if a newer system generation has been built but not booted
      # into. Happens after `nixos-rebuild boot` — most notably the
      # weekly auto-upgrade (modules/upgrade.nix), which uses `boot`
      # mode so critical-component changes can't fail live activation.
      if [[ "$(readlink -f /nix/var/nix/profiles/system 2>/dev/null)" \
         != "$(readlink -f /run/booted-system 2>/dev/null)" ]]; then
        print -P "%F{yellow}NixOS has been updated. Please reboot for the changes to take effect.%f"
      fi

      # One-shot rebuild: stage and commit local changes, `nh os switch`,
      # then push only if the switch succeeded — so origin/main (which
      # the weekly auto-upgrade consumes) only ever receives configs
      # that just built on this machine. The `git add .` must precede
      # the build: Nix's git fetcher ignores untracked files, so a new
      # module would otherwise be invisible to the switch.
      # Optional argument = commit message: rebuild "gc: fix flags"
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
