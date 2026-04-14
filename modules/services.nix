{ config, pkgs, ... }:

{
  # ── Printing (CUPS) ────────────────────────────────────────────────
  services.printing.enable = true;

  # Brother printer drivers. brlaser covers most Brother laser printers;
  # brgenml1* adds support for older models via generic Brother drivers.
  services.printing.drivers = [
    pkgs.brlaser
    pkgs.brgenml1lpr
    pkgs.brgenml1cupswrapper
  ];

  # ── Audio (PipeWire) ───────────────────────────────────────────────
  # PipeWire replaces PulseAudio and provides low-latency audio,
  # screen sharing, and Bluetooth codec support. The PulseAudio
  # compatibility layer (pulse.enable) lets legacy apps work unchanged.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;  # Realtime scheduling for PipeWire
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;  # Needed by 32-bit games (Steam/Proton)
    pulse.enable = true;
  };

  # ── SSH server ─────────────────────────────────────────────────────
  # https://wiki.nixos.org/wiki/SSH
  #
  # Hardened: password and keyboard-interactive auth are disabled,
  # root login is forbidden. Only key-based authentication is accepted.
  services.openssh = {
    enable = true;
    ports = [ 22 ];
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";
    };
  };

  # ── Fail2ban ───────────────────────────────────────────────────────
  # https://wiki.nixos.org/wiki/Fail2ban
  #
  # Monitors SSH logs and bans IPs after repeated failed login attempts,
  # reducing brute-force exposure.
  services.fail2ban.enable = true;
}
