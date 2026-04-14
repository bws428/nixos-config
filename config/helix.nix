{ ... }:

{
  # ── Helix text editor ──────────────────────────────────────────────
  # Modal editor inspired by Kakoune and Vim. Uses Tree-sitter for
  # syntax highlighting and built-in LSP support.
  programs.helix = {
    enable = true;

    # ── Language overrides ───────────────────────────────────────────
    languages = {
      language = [
        {
          name = "rust";
          # Auto-format on save using rustfmt.
          auto-format = true;
          formatter = {
            command = "rustfmt";
          };
        }
      ];
    };

    # ── Editor settings ──────────────────────────────────────────────
    settings = {

      theme = "catppuccin_macchiato";

      editor = {
        # Relative line numbers for easier vim-style motions (5j, 12k).
        line-number = "relative";
        # Highlight the line the cursor is on.
        cursorline = true;
        # Tint the status line by mode (insert = green, select = blue).
        color-modes = true;
        # Show a tab bar only when multiple buffers are open.
        bufferline = "multiple";

        # Cursor shape changes by mode for visual feedback.
        cursor-shape = {
          insert = "bar";
          normal = "block";
          select = "underline";
        };

        # Status line layout.
        statusline = {
          left = ["mode" "spinner" "file-name" "file-modification-indicator"];
          center = [];
          right = ["diagnostics" "selections" "position" "file-encoding"];
        };

        # Show LSP messages and inlay type hints inline.
        lsp = {
          display-messages = true;
          display-inlay-hints = true;
        };

        # Vertical indent guides for visual nesting.
        indent-guides = {
          render = true;
          character = "│";
        };
      };
    };
  };
}
