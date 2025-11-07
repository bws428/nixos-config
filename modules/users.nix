{ config, pkgs, ... }:

{
  # Define a User account
  users.users.bws428 = {
    isNormalUser = true;
    description = "Brian W.";
    extraGroups = [ "networkmanager" "wheel" ];
    shell = pkgs.zsh;
  };
}
