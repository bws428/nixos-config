{config, ...}: {
  # ── MPD ──
  # User service (not system) so it reads $HOME/Music without uid/gid.
  services.mpd = {
    enable = true;
    musicDirectory = "${config.home.homeDirectory}/Music";
    # Socket activation: spin up on first connect, idle to zero.
    network.startWhenNeeded = true;
    extraConfig = ''
      audio_output {
        type "pipewire"
        name "PipeWire"
      }
    '';
  };

  # MPRIS bridge so playerctl / media keys see MPD.
  services.mpd-mpris.enable = true;

  # ── rmpc ──
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
