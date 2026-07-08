{ ... }:

let
  # Shared between the local and NAS jobs so the two repos always
  # cover the same data.
  backupPaths = [
    "/home/bws428"
    "/mnt/seagate500"
  ];
  backupExclude = [
    "/home/bws428/.cache"
    "/home/bws428/.local/share/Trash"
    # Rebuildable package/build trees anywhere in the home dir.
    "node_modules"
    "/mnt/seagate500/lost+found"
  ];
in
{
  # ── Restic backups ─────────────────────────────────────────────────
  # Snapshot-based, encrypted, deduplicated backups. Restic keeps
  # history: any file can be restored as it was at any retained
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

    paths = backupPaths;
    exclude = backupExclude;

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

  # ── Leg 2: NAS repo (Synology DS725+, rest-server) ─────────────────
  # Same data, second medium. Talks to a restic rest-server container
  # on the NAS (Container Manager, restic/rest-server image) running
  # with --append-only: ghost's credentials can add snapshots but can
  # NOT delete or rewrite history, so a compromised or misbehaving
  # client can't destroy the NAS copy.
  #
  # Consequences of append-only:
  #   * No pruneOpts here — `forget --prune` would be rejected by the
  #     server. The repo grows until pruned manually. Ritual (a few
  #     times a year): in Container Manager stop the container, remove
  #     --append-only from OPTIONS, start, run
  #     `sudo restic-nas forget --prune --keep-daily 7 --keep-weekly 4 --keep-monthly 6`,
  #     then restore --append-only and restart.
  #   * `check` is read-only and still allowed (runs after each backup).
  #
  # /etc/restic/nas-repo (root-only, NOT in git) holds the repo URL
  # including the rest-server HTTP basic-auth credentials:
  #   rest:http://ghost:<password>@192.168.100.72:8000/ghost
  # Repo *encryption* uses the same password file as the local repo,
  # so one password in the password manager unlocks both.
  services.restic.backups.nas = {
    repositoryFile = "/etc/restic/nas-repo";
    passwordFile = "/etc/restic/password";
    initialize = true;

    paths = backupPaths;
    exclude = backupExclude;

    # 03:00, offset from the local job (midnight) so the two runs
    # don't read the same 100G concurrently.
    timerConfig = {
      OnCalendar = "03:00";
      Persistent = true;
      RandomizedDelaySec = "15m";
    };

    checkOpts = [ "--with-cache" ];
  };

  # ── Leg 3: offsite repo (Backblaze B2) ─────────────────────────────
  # Third independent repo, built from the live data like the other
  # two (not a copy of a copy — corruption in one repo can't reach
  # the others). Talks to B2 through its S3-compatible API: restic's
  # native b2: backend uses a retired authorization API version and
  # fails against accounts created after early 2026 (restic #5741).
  # Once that's fixed upstream, this can revert to
  # "b2:bws428-ghost-restic:restic" — the repo format is identical.
  #
  # /etc/restic/b2-env (root-only, NOT in git) holds the B2 key pair
  # under the names restic's S3 backend expects:
  #   AWS_ACCESS_KEY_ID=<application key ID>
  #   AWS_SECRET_ACCESS_KEY=<application key>
  # The key is deliberately created WITHOUT the deleteFiles capability
  # (listBuckets,listFiles,readFiles,writeFiles only), so ghost can add
  # snapshots but cannot destroy cloud history — the B2 equivalent of
  # the NAS repo's --append-only. (S3 deletes on a versioned B2 bucket
  # only write hide-markers, so restic can clear its own lock files but
  # past versions remain recoverable.)
  #
  # Consequence, same as the NAS leg: no pruneOpts (forget --prune
  # would be rejected). Ritual a few times a year: create a temporary
  # B2 key WITH deleteFiles, export it in a shell, run
  # `restic-cloud forget --prune --keep-daily 7 --keep-weekly 4 --keep-monthly 6`,
  # then delete the temporary key.
  services.restic.backups.cloud = {
    repository = "s3:https://s3.us-west-004.backblazeb2.com/bws428-ghost-restic/restic";
    environmentFile = "/etc/restic/b2-env";
    passwordFile = "/etc/restic/password";
    initialize = true;

    paths = backupPaths;
    exclude = backupExclude;

    # 04:30 — after the local (midnight) and NAS (03:00) jobs.
    timerConfig = {
      OnCalendar = "04:30";
      Persistent = true;
      RandomizedDelaySec = "15m";
    };

    checkOpts = [ "--with-cache" ];
  };

  # Tie the services to the automounted drives: starting one triggers
  # the automounts and fails cleanly if a drive is missing, rather
  # than backing up into an empty mountpoint directory.
  systemd.services.restic-backups-local.unitConfig.RequiresMountsFor = [
    "/mnt/toshiba250"
    "/mnt/seagate500"
  ];
  systemd.services.restic-backups-nas.unitConfig.RequiresMountsFor = [
    "/mnt/seagate500"
  ];
  systemd.services.restic-backups-cloud.unitConfig.RequiresMountsFor = [
    "/mnt/seagate500"
  ];
}
