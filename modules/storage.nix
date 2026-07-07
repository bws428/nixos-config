{ pkgs, ... }:

{
  # ── Internal data drives ───────────────────────────────────────────
  # Declared here (rather than udisks2 click-to-mount) so they mount at
  # boot without a polkit password prompt and are available to systemd
  # services and timers. Per the repo convention, every entry uses
  # nofail + automount + a short device timeout so a dead or missing
  # drive degrades gracefully instead of dropping an unattended
  # auto-upgrade boot into emergency mode.
  #
  # UUIDs from `lsblk -f` (2026-07-07). If a drive is replaced, update
  # its UUID here.
  #
  # x-gvfs-show: GIO hides fstab-declared mounts outside /media from
  # file managers by default; this opts each drive back into the
  # Nautilus sidebar.
  fileSystems."/mnt/crucial500" = {
    device = "/dev/disk/by-uuid/631819dd-b905-4090-a3b3-e6f6df04f3ac";
    fsType = "ext4";
    options = [ "nofail" "x-systemd.automount" "x-systemd.device-timeout=5s" "x-gvfs-show" ];
  };

  fileSystems."/mnt/seagate500" = {
    device = "/dev/disk/by-uuid/f250b534-1c8c-40c8-ac40-b83c51d2e349";
    fsType = "ext4";
    options = [ "nofail" "x-systemd.automount" "x-systemd.device-timeout=5s" "x-gvfs-show" ];
  };

  fileSystems."/mnt/toshiba250" = {
    device = "/dev/disk/by-uuid/da0b4442-6972-4a68-beae-b047e182e7b9";
    fsType = "ext4";
    options = [ "nofail" "x-systemd.automount" "x-systemd.device-timeout=5s" "x-gvfs-show" ];
  };

  # ── Music library mirror ───────────────────────────────────────────
  # Daily one-way mirror of ~/Music (the beets-managed library) to the
  # Crucial500 as a hard backup. --delete keeps the mirror an exact
  # copy, so library culls propagate. Runs as bws428 (the drive's
  # filesystem root is owned by that user; no root needed).
  #
  # System-level (not Home Manager) service so Persistent=true can fire
  # a missed run at boot, before any user session exists.
  systemd.services.music-mirror = {
    description = "Mirror ~/Music to Crucial500";
    unitConfig.RequiresMountsFor = "/mnt/crucial500";
    serviceConfig = {
      Type = "oneshot";
      User = "bws428";
      Group = "users";
      ExecStart = "${pkgs.rsync}/bin/rsync -a --delete /home/bws428/Music/ /mnt/crucial500/Music/";
    };
  };

  systemd.timers.music-mirror = {
    description = "Daily music library mirror";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "daily";
      # Fire a missed run at next boot instead of skipping the day.
      Persistent = true;
      RandomizedDelaySec = "15m";
    };
  };
}
