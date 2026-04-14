{ config, pkgs, ... }:

{
  # ── Networking ─────────────────────────────────────────────────────
  # MT7927 WiFi card needs its driver loaded explicitly (PCI ID not yet
  # in the module's auto-load alias table for this kernel).
  boot.kernelModules = [ "mt7925e" ];

  networking = {
    # Machine hostname — appears in the shell prompt, Avahi/mDNS, and logs.
    hostName = "ghost";

    # Use NetworkManager for connection management (Wi-Fi, VPN, etc.).
    # Provides the `nmcli` / `nmtui` CLI and desktop applet integration.
    networkmanager.enable = true;
  };
}
