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

  # The login-screen avatar is NOT declared here: it's imperative user
  # state in /var/lib/AccountsService, managed through accounts-daemon
  # (enabled in modules/greeter.nix) via Noctalia's avatar picker.
}
