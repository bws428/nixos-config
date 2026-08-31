{...}: {
  # ── Helix ──
  programs.helix = {
    enable = true;

    # Transparent theme wrappers: clear editor bg for terminal opacity.
    themes = {
      noctalia_transparent = {
        inherits = "noctalia";
        "ui.background" = {};
      };
      carbonfox_transparent = {
        inherits = "carbonfox";
        "ui.background" = {};
      };
    };

    languages = {
      language = [
        {
          name = "rust";
          formatter = {
            command = "rustfmt";
            # stdin rustfmt defaults to 2015; ours is 2024.
            args = [ "--edition" "2024" ];
          };
          auto-format = true;
        }
      ];
    };

    settings = {
      theme = "catppuccin_macchiato";

      editor = {
        # Vim-style relative line numbers.
        line-number = "relative";
        cursorline = true;
        # Tint status line by mode.
        color-modes = true;
        # Tab bar only with multiple buffers.
        bufferline = "multiple";
        cursor-shape = {
          insert = "bar";
          normal = "block";
          select = "underline";
        };
        statusline = {
          left = ["mode" "spinner" "file-name" "file-modification-indicator"];
          center = [];
          right = ["diagnostics" "selections" "position" "file-encoding"];
        };
        lsp = {
          display-messages = true;
          display-inlay-hints = true;
        };
        indent-guides = {
          render = true;
          character = "│";
        };
      };
    };
  };
}
