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
      theme = {
        mode = "dark";
        source = "custom";
        custom_palette = "kape";
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
}
