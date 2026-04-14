{ ... }:

{
  # ── MediaTek MT7927 (Filogic 380) WiFi/Bluetooth ─────────────────
  # Out-of-tree driver via github:cmspam/mt7927-nixos.
  # Remove this module once mainline kernel support is merged.
  hardware.mediatek-mt7927 = {
    enable = true;
    enableWifi = true;
    enableBluetooth = true;
    disableAspm = true;  # fixes upload speed / packet loss issues
  };
}
