# Herdr — AI terminal workspace manager for coding agents.
# Writes ~/.config/herdr/config.toml; see herdr.dev/docs/configuration.
# The binary comes from nixpkgs (no flake input needed).
{ ... }:
{
  programs.herdr = {
    enable = true;

    settings = {
      # First-run wizard — already set up, don't show it again.
      onboarding = false;

      # nixpkgs updates the binary, so background self-update checks
      # would only nag. Keep the agent-detection manifest current.
      update = {
        version_check = false;
        manifest_check = true;
      };

      # Match the rest of the desktop (Catppuccin, like ghostty).
      theme.name = "catppuccin";

      # Default shell for new panes (matches the login shell).
      terminal.default_shell = "zsh";

      ui = {
        accent = "cyan";
        toast = {
          delivery = "herdr";
          delay_seconds = 1;
          herdr.position = "bottom-right";
        };
      };

      # Relaunch pi/claude/codex panes into their previous sessions
      # after a herdr restart.
      session.resume_agents_on_restore = true;
    };
  };
}
