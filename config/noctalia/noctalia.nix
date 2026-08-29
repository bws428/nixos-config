{
  config,
  pkgs,
  ...
}: let
  wallpaperDir = "${config.home.homeDirectory}/Pictures/Wallpapers";
in {
  # ── Noctalia v5 desktop shell ──────────────────────────────────────
  # Bar, launcher, lock screen, notifications, OSD, wallpaper.
  # https://docs.noctalia.dev/v5/
  #
  # The home module is bundled with Home Manager (upstreamed from the
  # Noctalia repo), and the package is pkgs.noctalia from nixpkgs —
  # deliberately unpinned, so the shell moves with the weekly
  # nixpkgs auto-upgrade. System prerequisites (upower,
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
        order = ["Default"];
        Default = {
          background_opacity = 0.6;
          thickness = 40;
          scale = 1.15;
          padding = 20;
          radius = 0;
          margin_edge = 0;
          margin_ends = 0;
          widget_spacing = 10;
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
        launcher.scale = 1.3;
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
      };

      # Alacritty is spawned by Noctalia's started hook rather than niri
      # spawn-at-startup: the hook fires only once the session is fully
      # up, avoiding a session-start race.
      #
      # systemd-run detaches alacritty into its own transient scope
      # instead of noctalia.service's cgroup — otherwise every noctalia
      # restart (any rebuild that touches it) kills all terminals,
      # including the one running the rebuild.
      #
      # The pgrep guard spawns only when no alacritty is running, so a
      # mid-session noctalia restart doesn't add extra windows but a
      # fresh login still gets one.
      hooks.started = "sh -c 'pgrep alacritty >/dev/null || systemd-run --user alacritty'";

      # ── Idle / lock ──────────────────────────────────────────────────
      idle = {
        behavior_order = ["lock" "screen-off" "lock-and-suspend"];
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

      # ── Misc shell behavior ──────────────────────────────────────────
      location.auto_locate = true;
      nightlight.enabled = true;
      osd.kinds.nightlight = false;
      weather.unit = "imperial";

      # Official screen-recorder plugin. The plugin files themselves are
      # downloaded imperatively into ~/.local/state/noctalia/plugins; on
      # a fresh install, reinstall from Settings → Plugins if it doesn't
      # fetch on its own.
      plugins.enabled = ["noctalia/screen_recorder"];

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
        # "content" scheme).
        source = "wallpaper";
        wallpaper_scheme = "m3-content";
        builtin = "Ayu";
        # Community palettes auto-download from api.noctalia.dev on
        # first use and cache locally — safe to declare on a fresh box.
        community_palette = "Oxocarbon";

        templates = {
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
      # Only the portable pieces are declared: directory and transition.
      # The current wallpaper, per-monitor assignments, and favorites
      # are runtime curation in settings.toml and reference files under
      # ~/Pictures/Wallpapers that a fresh install won't have.
      wallpaper = {
        directory = wallpaperDir;
        transition = ["fade"];
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
