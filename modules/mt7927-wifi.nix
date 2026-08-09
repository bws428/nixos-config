{...}: {
  # ── MediaTek MT7927 (Filogic 380) WiFi/Bluetooth ─────────────────
  # Out-of-tree mt76 and btusb/btmtk modules plus extracted firmware,
  # via github:cmspam/mt7927-nixos. Remove once mainline support lands.
  hardware.mediatek-mt7927 = {
    enable = true;
    enableWifi = true;
    enableBluetooth = true;

    # Clears link/l1_aspm for 14c3:7927 via udev; without it the card
    # stalls uploads and drops packets.
    disableAspm = true;
  };
}
