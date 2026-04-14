{ config, pkgs, ... }:

{
  # ── Networking ─────────────────────────────────────────────────────
  networking = {
    # Machine hostname — appears in the shell prompt, Avahi/mDNS, and logs.
    hostName = "ghost";

    # Use NetworkManager for connection management (Wi-Fi, VPN, etc.).
    # Provides the `nmcli` / `nmtui` CLI and desktop applet integration.
    networkmanager.enable = true;
  };
}
