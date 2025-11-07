{ config, pkgs, ... }:

{
  # Set hostname and network manager
  networking = {
    hostName = "ghost";
    wireless.enable = false;
    networkmanager.enable = true;
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
