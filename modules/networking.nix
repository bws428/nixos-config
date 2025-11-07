{ config, pkgs, ... }:

{
  # Set hostname and network manager
  networking = {
    hostName = "ghost";
    wireless.enable = false;
    networkmanager.enable = true;
  };
}
