{ config, pkgs, ... }:

{
  # Set hostname and network manager
  networking = {
    hostName = "ghost";
    networkmanager.enable = true;
  };
}
