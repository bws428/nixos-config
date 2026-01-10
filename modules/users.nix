{ config, pkgs, ... }:

{
  # Define User accounts
  users.users.bws428 = {
    isNormalUser = true;
    description = "Brian W.";
    extraGroups = [ "networkmanager" "wheel" ];
    shell = pkgs.zsh;
  };

  users.users.lyndsey = {
    isNormalUser = true;
    description = "Lyndsey B.";
    extraGroups = [];
    shell = pkgs.zsh;
  };
}
