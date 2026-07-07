{ ... }:

{
  # ── Restic backups ─────────────────────────────────────────────────
  # Snapshot-based, encrypted, deduplicated backups. Unlike the rsync
  # music mirror (an exact copy where deletions propagate), restic
  # keeps history: any file can be restored as it was at any retained
  # snapshot. Repo password lives in /etc/restic/password (root-only,
  # NOT in git — this repo is public). Losing that password means
  # losing the backups; a copy belongs in a password manager.
  #
  # The module generates a `restic-local` wrapper command with the
  # repository and password pre-configured, so ad-hoc inspection is:
  #   sudo restic-local snapshots
  #   sudo restic-local mount /mnt/restore   (browse snapshots as files)
  #   sudo restic-local restore latest --target /tmp/restore --include <path>
  #
  # This is leg 1 of a 3-2-1 scheme: local repo on the Toshiba250.
  # Leg 2 (repo on the Synology over SFTP) and leg 3 (NAS → cloud via
  # Hyper Backup) come later.
  services.restic.backups.local = {
    repository = "/mnt/toshiba250/restic-repo";
    passwordFile = "/etc/restic/password";
    # Create the repo on first run if it doesn't exist.
    initialize = true;

    paths = [
      "/home/bws428"
      "/mnt/seagate500"
    ];
    exclude = [
      "/home/bws428/.cache"
      "/home/bws428/.local/share/Trash"
      # Rebuildable package/build trees anywhere in the home dir.
      "node_modules"
      "/mnt/seagate500/lost+found"
    ];

    # Runs as root (module default) so it can read everything under
    # both paths regardless of ownership.
    timerConfig = {
      OnCalendar = "daily";
      # Fire a missed run at next boot instead of skipping the day.
      Persistent = true;
      RandomizedDelaySec = "15m";
    };

    # `forget --prune` runs after each backup: keep every snapshot
    # from the last 7 days, then one per week for 4 weeks, one per
    # month for 6 months.
    pruneOpts = [
      "--keep-daily 7"
      "--keep-weekly 4"
      "--keep-monthly 6"
    ];

    # Verify repo integrity after each run (metadata check; cheap).
    checkOpts = [ "--with-cache" ];
  };

  # Tie the service to the automounted drives: starting it triggers
  # the automounts and fails cleanly if a drive is missing, rather
  # than backing up into an empty mountpoint directory.
  systemd.services.restic-backups-local.unitConfig.RequiresMountsFor = [
    "/mnt/toshiba250"
    "/mnt/seagate500"
  ];
}
