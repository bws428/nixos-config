{pkgs, ...}: {
  # ── Data drives ──
  # Boot-time mounts (not udisks2). nofail + automount + short timeout
  # so a missing drive degrades instead of wedging an unattended boot.
  # UUIDs from `lsblk -f`; update here if a drive is replaced.
  fileSystems."/mnt/crucial500" = {
    device = "/dev/disk/by-uuid/631819dd-b905-4090-a3b3-e6f6df04f3ac";
    fsType = "ext4";
    options = ["nofail" "x-systemd.automount" "x-systemd.device-timeout=5s" "x-gvfs-show"];
  };

  fileSystems."/mnt/seagate500" = {
    device = "/dev/disk/by-uuid/f250b534-1c8c-40ac-ac40-b83c51d2e349";
    fsType = "ext4";
    options = ["nofail" "x-systemd.automount" "x-systemd.device-timeout=5s" "x-gvfs-show"];
  };

  fileSystems."/mnt/toshiba250" = {
    device = "/dev/disk/by-uuid/da0b4442-6972-4a68-beae-b047e182e7b9";
    fsType = "ext4";
    options = ["nofail" "x-systemd.automount" "x-systemd.device-timeout=5s" "x-gvfs-show"];
  };
}
