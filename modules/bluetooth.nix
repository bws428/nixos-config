{
  config,
  pkgs,
  ...
}: {
  # ── Bluetooth ──
  hardware.bluetooth = {
    enable = true;
    # Power on at boot so devices reconnect.
    powerOnBoot = true;
    settings = {
      General = {
        # D-Bus battery reporting + codec negotiation.
        Experimental = true;
        # Faster connections, slightly higher power draw.
        FastConnectable = true;
      };
      Policy = {
        # Auto-enable newly paired devices.
        AutoEnable = true;
      };
    };
  };
}
