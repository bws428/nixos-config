{...}: {
  programs.tmux = {
    enable = true;

    # ── Keys ──
    # C-a instead of C-b.
    shortcut = "a";
    # Vi-style copy-mode keys.
    keyMode = "vi";

    # ── Behavior ──
    # No escape delay, so ESC in helix/vim is instant.
    escapeTime = 0;
    # Let apps detect focus changes.
    focusEvents = true;
    # Click panes, drag dividers, scroll into copy-mode.
    mouse = true;
    # Windows/panes start at 1.
    baseIndex = 1;
    # Big scrollback for build/log output.
    historyLimit = 10000;
    terminal = "tmux-256color";
    # Known-good tmux-sensible baseline.
    sensibleOnTop = true;
    # h/j/k/l panes, H/J/K/L resize.
    customPaneNavigationAndResize = true;

    # ── Extra config ──
    extraConfig = ''
      # | splits vertical, - splits horizontal; open in cwd.
      unbind '"'
      unbind %
      bind | split-window -h -c "#{pane_current_path}"
      bind - split-window -v -c "#{pane_current_path}"

      # Reload config.
      bind r source-file ~/.config/tmux/tmux.conf \; display "tmux.conf reloaded"

      # Advertise 24-bit color.
      set -ga terminal-overrides ",alacritty:Tc,xterm-256color:Tc"

      # carbonfox theme.
      set -g status-style "bg=#78a9ff,fg=#0c0c0c"
      set -g status-left  "#[fg=#f2f4f8,bg=#252525,bold] #S #[default] "
      set -g status-right "#[fg=#0c0c0c] %Y-%m-%d #[fg=#f2f4f8,bg=#252525,bold] %H:%M "
      set -g status-left-length 40

      set -g window-status-format         "#[fg=#0c0c0c] #I:#W "
      set -g window-status-current-format "#[fg=#0c0c0c,bold] #I:#W "
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
