{ config, pkgs, ... }:

{
  # ── User accounts ──────────────────────────────────────────────────
  users.users.bws428 = {
    isNormalUser = true;
    description = "Brian W.";
    # networkmanager: manage Wi-Fi/VPN without sudo
    # wheel: sudo access
    extraGroups = [ "networkmanager" "wheel" ];
    # Default login shell. Must also be enabled system-wide
    # (programs.zsh.enable in packages.nix).
    shell = pkgs.zsh;
  };
}
