{ ... }:

{
  # ── MediaTek MT7927 (Filogic 380) WiFi/Bluetooth ─────────────────
  # Patched driver via github:clemenscodes/linux-mt7927.
  # Remove this module once mainline kernel support is merged.
  mt7927.enable = true;

  # Disable ASPM for MT7927 to avoid upload speed / packet loss issues.
  boot.kernelParams = [ "mt7925.disable_aspm=1" ];
}
