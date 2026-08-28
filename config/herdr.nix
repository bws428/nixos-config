# Herdr — AI terminal workspace manager.
{ ... }:
{
  programs.herdr = {
    enable = true;

    settings = {
      # Skip first-run wizard.
      onboarding = false;

      # nixpkgs updates the binary; keep manifest checks only.
      update = {
        version_check = false;
        manifest_check = true;
      };

      # Match desktop theme.
      theme.name = "catppuccin";

      # Default shell for new panes.
      terminal.default_shell = "zsh";

      ui = {
        accent = "cyan";
        toast = {
          delivery = "herdr";
          delay_seconds = 1;
          herdr.position = "bottom-right";
        };
      };

      # Relaunch agent panes into previous sessions on restore.
      session.resume_agents_on_restore = true;
    };
  };
}
