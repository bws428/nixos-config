{ config, pkgs, ... }:

let
  # Assets shipped inside the noctalia package, referenced through the
  # package so the path survives version bumps. (The GUI had baked a
  # versioned /nix/store/...-noctalia-5.0.0 path into settings.toml,
  # which would silently break on upgrade.)
  noctaliaAssets = "${config.programs.noctalia.package}/share/noctalia/assets";

  # Fresh-install fallback wallpaper — comes from nixpkgs, so it always
  # exists. Real wallpapers live in ~/Pictures/Wallpapers (user data,
  # not in this repo); picking one in the GUI overrides this per-key in
  # ~/.local/state/noctalia/settings.toml.
  fallbackWallpaper = "${pkgs.nixos-artwork.wallpapers.simple-dark-gray}/share/backgrounds/nixos/nix-wallpaper-simple-dark-gray.png";

  wallpaperDir = "${config.home.homeDirectory}/Pictures/Wallpapers";
in
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
    # the rebuild instead of the session.
    #
    # LAYERING: this file is the declarative base. Changes made in the
    # Settings UI land in ~/.local/state/noctalia/settings.toml, which
    # loads last and wins per-key. That is the intended workflow (GUI
    # tweaks override the base day-to-day) — but it also means any key
    # ever touched in the GUI is shadowed on this machine, and edits
    # here won't take effect for that key until its entry is removed
    # from settings.toml. On a fresh install, settings.toml is empty
    # and everything below applies as-is.
    settings = {
      # ── Bar ──────────────────────────────────────────────────────────
      bar = {
        order = [ "Default" ];
        Default = {
          background_opacity = 0.6;
          thickness = 40;
          scale = 1.15;
          padding = 20;
          radius = 0;
          margin_edge = 0;
          margin_ends = 0;
          widget_spacing = 10;
          start = [ "launcher" "Spacer" "workspaces" "Spacer" ];
          center = [ "date" "clock" "Spacer" "media" ];
          end = [ "tray" "notifications" "network" "bluetooth" "Spacer" "volume" "Spacer" "session" ];
        };
      };

      # Per-widget settings for the instances referenced in the bar
      # layout above.
      widget = {
        Spacer = {
          type = "spacer";
          anchor = true;
        };
        clock.anchor = true;
        date.format = "{:%a %d %B}";
        launcher = {
          custom_image = "${noctaliaAssets}/images/distros/nixos.svg";
          scale = 1.3;
        };
        media = {
          hide_album_art = true;
          max_length = 160;
          title_scroll = "on_hover";
        };
        network.show_label = false;
        workspaces = {
          minimal = true;
          active_pill_size = 2.5;
          inactive_pill_size = 1.3;
          scale = 1.3;
        };
      };

      control_center.width = 900;

      # ── Dock ─────────────────────────────────────────────────────────
      dock = {
        enabled = true;
        background_opacity = 0.8;
        icon_size = 50;
        magnification_scale = 1.35;
        launcher_position = "start";
        show_dots = true;
        pinned = [ "chromium-browser" "com.mitchellh.ghostty" "obsidian" "signal" "dev.zed.Zed" "steam" ];
      };

      # Ghostty is spawned by Noctalia's started hook rather than niri
      # spawn-at-startup: the hook fires only once the shell (and thus
      # the session) is fully up, which fixed the ghostty startup race.
      #
      # systemd-run detaches ghostty into its own transient scope
      # instead of living in noctalia.service's cgroup. Without it,
      # every noctalia restart (any rebuild after a flake-input bump
      # that touches noctalia) kills all terminals — including, on
      # 2026-07-07, the very shell running the rebuild, which aborted
      # the switch mid-activation.
      hooks.started = "systemd-run --user ghostty";

      # ── Idle / lock ──────────────────────────────────────────────────
      idle = {
        behavior_order = [ "lock" "screen-off" "lock-and-suspend" ];
        behavior = {
          lock = {
            action = "lock";
            enabled = true;
            timeout = 600.0;
          };
          "screen-off" = {
            action = "screen_off";
            enabled = true;
            timeout = 1260.0;
          };
          "lock-and-suspend" = {
            action = "lock_and_suspend";
            enabled = false;
            timeout = 900.0;
          };
        };
      };

      lockscreen.fingerprint = false;

      # Lock screen layout: login box, digital clock, and weather card.
      # Positions (cx/cy) and the login-box key are tied to output DP-1
      # (the 2560x1440 desktop monitor). On hardware without a DP-1,
      # Noctalia creates its default login box for whatever output
      # exists, so this degrades safely.
      lockscreen_widgets = {
        enabled = true;
        schema_version = 2;
        widget_order = [
          "lockscreen-login-box@DP-1"
          "lockscreen-widget-0000000000000001"
          "lockscreen-widget-0000000000000002"
        ];
        grid = {
          cell_size = 16;
          major_interval = 4;
          visible = true;
        };
        widget = {
          "lockscreen-login-box@DP-1" = {
            type = "login_box";
            output = "DP-1";
            box_width = 448.0;
            box_height = 80.0;
            cx = 1280.0;
            cy = 784.0;
            rotation = 0.0;
            settings = {
              background_color = "surface_variant";
              background_opacity = 0.88;
              background_radius = 12.0;
              input_opacity = 1.0;
              input_radius = 6.0;
              show_caps_lock = true;
              show_keyboard_layout = true;
              show_login_button = true;
              show_password_hint = true;
            };
          };
          "lockscreen-widget-0000000000000001" = {
            type = "clock";
            output = "DP-1";
            box_width = 512.0;
            box_height = 192.0;
            cx = 1280.0;
            cy = 560.0;
            rotation = 0.0;
            settings = {
              background = false;
              background_opacity = 0.88;
              background_radius = 12;
              center_text = true;
              clock_style = "digital";
              font_family = "MesloLGL Nerd Font"; # declared in modules/fonts.nix
              shadow = true;
            };
          };
          "lockscreen-widget-0000000000000002" = {
            type = "weather";
            output = "DP-1";
            box_width = 320.0;
            box_height = 144.0;
            cx = 2368.0;
            cy = 96.0;
            rotation = 0.0;
            settings = {
              background = true;
              forecast_days = 1;
              show_forecast = true;
            };
          };
        };
      };

      # ── Misc shell behavior ──────────────────────────────────────────
      location.auto_locate = true;
      nightlight.enabled = true;
      osd.kinds.nightlight = false;
      weather.unit = "imperial";

      # Official screen-recorder plugin. The plugin files themselves are
      # downloaded imperatively into ~/.local/state/noctalia/plugins; on
      # a fresh install, reinstall from Settings → Plugins if it doesn't
      # fetch on its own.
      plugins.enabled = [ "noctalia/screen_recorder" ];

      shell = {
        polkit_agent = true;
        ui_scale = 1.05;
        animation.enabled = false;
      };

      # ── Theme ────────────────────────────────────────────────────────
      # Greeter appearance sync is manual-only (Auto-Sync disabled in
      # the Settings UI) and prompts for an admin password each time —
      # see the upstream-policy-bug note in modules/greeter.nix.
      theme = {
        mode = "dark";

        # Active colors derive from the current wallpaper (Material You
        # "content" scheme). kape stays declared below as the custom
        # palette, one click away in Settings → Color Scheme.
        source = "wallpaper";
        wallpaper_scheme = "m3-content";
        custom_palette = "kape";
        builtin = "Ayu";
        # Community palettes auto-download from api.noctalia.dev on
        # first use and cache locally — safe to declare on a fresh box.
        community_palette = "Oxocarbon";

        templates = {
          builtin_ids = [ "alacritty" "btop" "cava" "emacs" "gtk3" "gtk4" "ghostty" "helix" "kitty" "niri" "qt" "wezterm" ];
          # Community templates are fetched into
          # ~/.local/state/noctalia/community-templates and re-download
          # on a fresh install.
          community_ids = [ "spicetify" "zen-browser" "neovim" "obsidian" "vscode" "zed" "steam" "telegram" "yazi" ];

          # ── User templates ─────────────────────────────────────────
          # Apps outside Noctalia's built-in template catalog. Rendered
          # from the {{...}}-tokenized input on every theme/wallpaper
          # apply. The Obsidian output lands in the vault's snippets
          # dir; enable the "noctalia" snippet once in Obsidian
          # (Settings → Appearance → CSS snippets) and Obsidian
          # hot-reloads it on every rewrite. output_path takes a list
          # if more vaults appear later.
          user.obsidian = {
            input_path = "$XDG_CONFIG_HOME/noctalia/templates/obsidian.css";
            output_path = "/home/bws428/Documents/Obsidian/Notes/.obsidian/snippets/noctalia.css";
          };

          # rmpc reads its theme by name from ~/.config/rmpc/themes/;
          # the output is a NEW file there (not an HM symlink — see the
          # alacritty clobber lesson), referenced as theme "noctalia" in
          # config/mpd.nix. The post_hook live-swaps the theme in any
          # running instances; `|| true` keeps the hook quiet when none
          # are running (new instances pick it up from config.ron).
          user.rmpc = {
            input_path = "$XDG_CONFIG_HOME/noctalia/templates/rmpc.ron";
            output_path = "/home/bws428/.config/rmpc/themes/noctalia.ron";
            post_hook = "sh -c 'rmpc remote set theme /home/bws428/.config/rmpc/themes/noctalia.ron || true'";
          };
        };
      };

      # ── Wallpaper ────────────────────────────────────────────────────
      # Only the portable pieces are declared: directory, transition,
      # and a store-path fallback. The current wallpaper, per-monitor
      # assignments, and favorites are runtime curation in settings.toml
      # and reference files under ~/Pictures/Wallpapers that a fresh
      # install won't have.
      wallpaper = {
        directory = wallpaperDir;
        transition = [ "fade" ];
        default.path = fallbackWallpaper;
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
      # NOTE: theme.source above is "wallpaper", so this palette is the
      # declared base/fallback, not necessarily what's active.
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

  # Make sure the wallpaper directory exists on a fresh install so the
  # wallpaper picker has somewhere to look.
  home.file."Pictures/Wallpapers/.keep".text = "";

  # User template sources for theme.templates.user.* above.
  # Deployed next to where Noctalia looks for user template inputs.
  xdg.configFile."noctalia/templates/obsidian.css".source = ./obsidian.css;
  xdg.configFile."noctalia/templates/rmpc.ron".source = ./rmpc.ron;
}
