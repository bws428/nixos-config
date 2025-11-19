{ config, pkgs, ... }:

{
  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Brother printer drivers
  services.printing.drivers = [
    pkgs.brlaser
    pkgs.brgenml1lpr
    pkgs.brgenml1cupswrapper
  ];

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # Enable Ollama LLM
  services.ollama = {
    enable = true;
    acceleration = "cuda";
  };

  # Enable OpenSSH
  # https://wiki.nixos.org/wiki/SSH
  services.openssh = {
    enable = true;
    ports = [ 22 ];
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";
    };
  };

  # Fail2ban to protect unauthorized SSH
  # https://wiki.nixos.org/wiki/Fail2ban
  services.fail2ban.enable = true;

}
