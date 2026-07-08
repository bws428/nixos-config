{pkgs, ...}: {
  # ── Internal data drives ───────────────────────────────────────────
  # Declared here (rather than udisks2 click-to-mount) so they mount at
  # boot without a polkit password prompt and are available to systemd
  # services and timers. Per the repo convention, every entry uses
  # nofail + automount + a short device timeout so a dead or missing
  # drive degrades gracefully instead of dropping an unattended
  # auto-upgrade boot into emergency mode.
  #
  # UUIDs from `lsblk -f`. If a drive is replaced, update its UUID here.
  #
  # x-gvfs-show: GIO hides fstab-declared mounts outside /media from
  # file managers by default; this opts each drive back into the
  # Nautilus sidebar.
  fileSystems."/mnt/crucial500" = {
    device = "/dev/disk/by-uuid/631819dd-b905-4090-a3b3-e6f6df04f3ac";
    fsType = "ext4";
    options = ["nofail" "x-systemd.automount" "x-systemd.device-timeout=5s" "x-gvfs-show"];
  };

  fileSystems."/mnt/seagate500" = {
    device = "/dev/disk/by-uuid/f250b534-1c8c-40c8-ac40-b83c51d2e349";
    fsType = "ext4";
    options = ["nofail" "x-systemd.automount" "x-systemd.device-timeout=5s" "x-gvfs-show"];
  };

  fileSystems."/mnt/toshiba250" = {
    device = "/dev/disk/by-uuid/da0b4442-6972-4a68-beae-b047e182e7b9";
    fsType = "ext4";
    options = ["nofail" "x-systemd.automount" "x-systemd.device-timeout=5s" "x-gvfs-show"];
  };
}
