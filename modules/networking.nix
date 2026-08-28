{
  config,
  pkgs,
  ...
}: {
  # ── Networking ──
  networking = {
    hostName = "ghost";
    # Wi-Fi/VPN management (nmcli/nmtui).
    networkmanager.enable = true;
    # Bambu X1-C SSDP discovery ports.
    firewall.allowedUDPPorts = [1990 2021];
  };
}
