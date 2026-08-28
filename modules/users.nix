{
  config,
  pkgs,
  ...
}: {
  # ── User ──
  users.users.bws428 = {
    isNormalUser = true;
    description = "Brian W.";
    # networkmanager: Wi-Fi/VPN without sudo; wheel: sudo.
    extraGroups = ["networkmanager" "wheel"];
    # Login shell (enabled system-wide in packages.nix).
    shell = pkgs.zsh;
  };

  # Avatar is imperative state in /var/lib/AccountsService.
}
