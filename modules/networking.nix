{ config, pkgs, ... }:

{
  networking = {
    hostName = "ghost";
    wireless.enable = false;
    networkmanager.enable = true;
  };
}
