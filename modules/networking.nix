{
  config,
  pkgs,
  ...
}: {
  # ── Networking ─────────────────────────────────────────────────────
  networking = {
    # Machine hostname — appears in the shell prompt, Avahi/mDNS, and logs.
    hostName = "ghost";

    # Use NetworkManager for connection management (Wi-Fi, VPN, etc.).
    # Provides the `nmcli` / `nmtui` CLI and desktop applet integration.
    networkmanager.enable = true;

    # Bambu Lab X1-C discovery (LAN mode): the printer announces itself
    # via SSDP broadcasts to UDP 1990/2021 (not the standard 1900), and
    # OrcaSlicer listens on those ports. Without these rules the printer
    # never appears in the device list. Control traffic (MQTT 8883,
    # FTPS 990) is outbound-only and needs no rules.
    firewall.allowedUDPPorts = [1990 2021];
  };
}
