{ ... }:

{
  programs.tmux = {
    enable = true;

    # ── Prefix & key style ─────────────────────────────────────────────
    # Default prefix is C-b, which is an awkward two-handed stretch.
    # C-a is the near-universal rebind (hits the home row with pinky).
    shortcut = "a";

    # Vi-style keys in copy-mode — matches helix muscle memory.
    keyMode = "vi";

    # ── Behavior ───────────────────────────────────────────────────────
    # Default escape-time (10ms) adds noticeable lag to ESC in helix/vim.
    # Setting to 0 makes modal editors feel native inside tmux.
    escapeTime = 0;

    # Let helix/yazi detect focus changes (e.g. re-read files on regain).
    focusEvents = true;

    # Click panes to focus, drag dividers to resize, scroll into copy-mode.
    mouse = true;

    # Start windows/panes at 1 — matches keyboard layout (1 is next to ~,
    # 0 is far away). Default is 0.
    baseIndex = 1;

    # Default 2000 lines of scrollback is stingy for build/log output.
    historyLimit = 10000;

    # Modern tmux-native terminfo entry; true-color is enabled below
    # via terminal-overrides.
    terminal = "tmux-256color";

    # Pre-load tmux-sensible defaults (tmux-plugins/tmux-sensible) so our
    # settings layer on top of a known-good baseline.
    sensibleOnTop = true;

    # Rebind h/j/k/l to move between panes and H/J/K/L to resize —
    # pairs naturally with keyMode = "vi".
    customPaneNavigationAndResize = true;

    # ── Extra config ──────────────────────────────────────────────────
    extraConfig = ''
      # Intuitive split bindings: | splits vertically, - splits horizontally.
      # Both open the new pane in the current pane's working directory.
      unbind '"'
      unbind %
      bind | split-window -h -c "#{pane_current_path}"
      bind - split-window -v -c "#{pane_current_path}"

      # Reload config without restarting tmux.
      bind r source-file ~/.config/tmux/tmux.conf \; display "tmux.conf reloaded"

      # Advertise 24-bit color to programs running inside tmux.
      set -ga terminal-overrides ",alacritty:Tc,xterm-256color:Tc"
    '';
  };
}
