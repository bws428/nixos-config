{ config, ... }:

{
  # ── Music Player Daemon ────────────────────────────────────────────
  # Single-user desktop setup: MPD runs as a Home Manager *user* service
  # (not a system service), so it can read $HOME/Music without uid/gid
  # gymnastics and is tied to the login session.
  #
  # `network.startWhenNeeded = true` enables socket activation — the
  # daemon spins up on first client connect, idles to zero otherwise.
  # No always-on process.
  services.mpd = {
    enable = true;
    musicDirectory = "${config.home.homeDirectory}/Music";
    network.startWhenNeeded = true;
    extraConfig = ''
      audio_output {
        type "pipewire"
        name "PipeWire"
      }
    '';
  };

  # MPRIS bridge — without this, `playerctl`, the shell's media widget, and
  # the keyboard media keys can't see MPD. With it, MPD appears alongside
  # Spotify in the same control surface.
  services.mpd-mpris.enable = true;

  # ── rmpc (Rusty MPD client, TUI) ───────────────────────────────────
  # The HM module writes `~/.config/rmpc/config.ron` from `config` below;
  # theme files are separate. The active "noctalia" theme is RENDERED by
  # Noctalia (theme.templates.user.rmpc in config/noctalia/noctalia.nix) into
  # ~/.config/rmpc/themes/noctalia.ron on every theme/wallpaper apply,
  # so rmpc follows the shell's colors. If noctalia.ron is ever missing
  # (fresh machine before the first theme apply), re-apply the color
  # scheme in Noctalia's settings to regenerate it.
  programs.rmpc = {
    enable = true;
    config = ''
      (
        address: "127.0.0.1:6600",
        theme: Some("noctalia"),
        volume_step: 5,
        enable_mouse: true,
        enable_config_hot_reload: true,
      )
    '';
  };
}
