{ config, pkgs, ... }:

{
  # ── Bluetooth ──────────────────────────────────────────────────────
  # https://nixos.wiki/wiki/Bluetooth
  hardware.bluetooth = {
    enable = true;

    # Power on the Bluetooth adapter at boot so devices reconnect
    # automatically (headphones, controllers, etc.).
    powerOnBoot = true;

    settings = {
      General = {
        # Enable experimental D-Bus features (battery level reporting,
        # improved codec negotiation, etc.).
        Experimental = true;
        # Allow the adapter to use page scan for faster connections
        # at the cost of slightly higher power draw.
        FastConnectable = true;
      };
      Policy = {
        # Automatically enable newly paired devices.
        AutoEnable = true;
      };
    };
  };
}
