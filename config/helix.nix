{...}: {
  # ── Helix text editor ──────────────────────────────────────────────
  # Modal editor inspired by Kakoune and Vim. Uses Tree-sitter for
  # syntax highlighting and built-in LSP support.
  programs.helix = {
    enable = true;

    # ── Custom themes ────────────────────────────────────────────────
    # Transparent wrappers: inherit a full theme and just clear the
    # editor background so the terminal's opacity (0.9) shows through.
    themes = {
      # Noctalia's wallpaper-driven theme. The base theme is written
      # to ~/.config/helix/themes/noctalia.toml by the Helix template
      # (enabled in Noctalia settings → color scheme templates; no
      # post-hook, so unlike alacritty it never touches HM symlinks).
      # Helix doesn't watch theme files — run :config-reload in live
      # instances after a wallpaper change; new ones pick it up.
      # Until the template's first render, helix warns and falls back
      # to its default theme.
      noctalia_transparent = {
        inherits = "noctalia";
        "ui.background" = {};
      };
      # Static fallback (:theme carbonfox_transparent).
      carbonfox_transparent = {
        inherits = "carbonfox";
        "ui.background" = {};
      };
    };

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
      theme = "noctalia_transparent";

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
