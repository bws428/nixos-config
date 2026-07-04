{ config, pkgs, ... }:

{
  # ── Noctalia v5 desktop shell ──────────────────────────────────────
  # Bar, launcher, lock screen, notifications, OSD, wallpaper.
  # https://docs.noctalia.dev/v5/
  #
  # The package and module come from the noctalia flake input (see
  # flake.nix); binaries are substituted from noctalia.cachix.org
  # (see modules/desktop.nix). System prerequisites (upower,
  # power-profiles-daemon) also live in modules/desktop.nix.
  programs.noctalia = {
    enable = true;

    # Run as a systemd user service bound to graphical-session.target:
    # starts with niri, restarts on failure, and restarts when the
    # config or palette below changes. Replaces spawn-at-startup.
    systemd.enable = true;

    # Written to ~/.config/noctalia/config.toml and validated with
    # `noctalia config validate` at build time, so a typo here fails
    # the rebuild instead of the session. Runtime changes made in the
    # Settings UI are merged on top of this file, not written to it.
    settings = {
      # Greeter appearance sync is manual-only (Auto-Sync disabled in
      # the Settings UI) and prompts for an admin password each time —
      # see the upstream-policy-bug note in modules/greeter.nix.
      theme = {
        mode = "dark";
        source = "custom";
        custom_palette = "kape";

        # ── User templates ───────────────────────────────────────────
        # Apps outside Noctalia's built-in template catalog. Rendered
        # from the {{...}}-tokenized input on every theme/wallpaper
        # apply. The Obsidian output lands in the vault's snippets
        # dir; enable the "noctalia" snippet once in Obsidian
        # (Settings → Appearance → CSS snippets) and Obsidian
        # hot-reloads it on every rewrite. output_path takes a list
        # if more vaults appear later.
        templates.user.obsidian = {
          input_path = "$XDG_CONFIG_HOME/noctalia/templates/obsidian.css";
          output_path = "/home/bws428/Documents/Obsidian/Notes/.obsidian/snippets/noctalia.css";
        };

        # rmpc reads its theme by name from ~/.config/rmpc/themes/; the
        # output is a NEW file there (not an HM symlink — see the
        # alacritty clobber lesson), referenced as theme "noctalia" in
        # config/mpd.nix. The post_hook live-swaps the theme in any
        # running instances; `|| true` keeps the hook quiet when none
        # are running (new instances pick it up from config.ron).
        templates.user.rmpc = {
          input_path = "$XDG_CONFIG_HOME/noctalia/templates/rmpc.ron";
          output_path = "/home/bws428/.config/rmpc/themes/noctalia.ron";
          post_hook = "sh -c 'rmpc remote set theme /home/bws428/.config/rmpc/themes/noctalia.ron || true'";
        };
      };
    };

    # ── Kape palette ─────────────────────────────────────────────────
    # Material-role mapping of the kape palette (autumn-amber variant,
    # https://github.com/gabiuz/kape) — the same mapping previously in
    # assets/themes/kape/theme.json for DMS, renamed onto Noctalia's
    # token names. Written to ~/.config/noctalia/palettes/kape.json.
    # Terminal ANSI colors mirror the ghostty "kape" theme
    # (config/ghostty.nix), which is the authoritative 16-color set.
    # No light variant is defined; Noctalia falls back to dark.
    customPalettes.kape = {
      # NOTE: the user runs wallpaper-driven colors at runtime (set in
      # the Settings UI, which merges over this file) — this palette
      # is the declared base/fallback, not necessarily what's active.
      dark = {
        mPrimary = "#d99a4a";          # amber
        mOnPrimary = "#181616";
        mSecondary = "#b8642e";        # burnt sienna
        mOnSecondary = "#181616";
        mTertiary = "#689d8a";         # sage teal (DMS "info")
        mOnTertiary = "#181616";
        mError = "#b53535";
        mOnError = "#181616";
        mSurface = "#181616";
        mOnSurface = "#d4be98";
        mSurfaceVariant = "#2e2a2a";
        mOnSurfaceVariant = "#bdae8b";
        mOutline = "#928374";
        mShadow = "#0a0808";
        mHover = "#b8642e";
        mOnHover = "#181616";
        terminal = {
          normal = {
            black = "#181616";
            red = "#b53535";
            green = "#b4c76e";
            yellow = "#d99a4a";
            blue = "#7b8fd4";
            magenta = "#b06880";
            cyan = "#689d8a";
            white = "#c2c2c2";
          };
          bright = {
            black = "#2e2a2a";
            red = "#c94040";
            green = "#cad98a";
            yellow = "#e6ad60";
            blue = "#9aaae0";
            magenta = "#c8889a";
            cyan = "#89b8a8";
            white = "#d4be98";
          };
          foreground = "#d4be98";
          background = "#181616";
          selectionFg = "#d4be98";
          selectionBg = "#2e2a2a";
          cursorText = "#181616";
          cursor = "#d4be98";
        };
      };
    };
  };

  # User template sources for theme.templates.user.* above.
  # Deployed next to where Noctalia looks for user template inputs.
  xdg.configFile."noctalia/templates/obsidian.css".source = ./noctalia/obsidian.css;
  xdg.configFile."noctalia/templates/rmpc.ron".source = ./noctalia/rmpc.ron;
}
