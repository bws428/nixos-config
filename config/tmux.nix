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

      # ── Theme: carbonfox (matches alacritty + helix) ─────────────────
      # Palette from EdenEast/nightfox.nvim carbonfox.
      set -g status-style "bg=#78a9ff,fg=#0c0c0c"
      set -g status-left  "#[fg=#f2f4f8,bg=#252525,bold] #S #[default] "
      set -g status-right "#[fg=#0c0c0c] %Y-%m-%d #[fg=#f2f4f8,bg=#252525,bold] %H:%M "
      set -g status-left-length 40

      set -g window-status-format         "#[fg=#0c0c0c] #I:#W "
      set -g window-status-current-format "#[fg=#78a9ff,bg=#161616,bold] #I:#W "
      set -g window-status-separator ""

      set -g pane-border-style        "fg=#353535"
      set -g pane-active-border-style "fg=#78a9ff"

      set -g message-style         "bg=#252525,fg=#f2f4f8"
      set -g message-command-style "bg=#252525,fg=#f2f4f8"

      set -g mode-style "bg=#525253,fg=#f2f4f8"
      set -g clock-mode-colour "#78a9ff"

      set -g copy-mode-match-style         "bg=#525253,fg=#f2f4f8"
      set -g copy-mode-current-match-style "bg=#ff7eb6,fg=#0c0c0c"
    '';
  };
}
