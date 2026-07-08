# Leg 3 runbook: restic → Backblaze B2

Completes the 3-2-1 scheme. Legs 1 (Toshiba250, midnight) and 2 (DS725+
rest-server, 03:00) are live; this seeds the offsite repo declared in
`modules/backups.nix` as `services.restic.backups.cloud` (04:30 timer).

The config expects:

- bucket: `bws428-ghost-restic` (if that name is taken, pick another and
  update `repository` in `modules/backups.nix` to match)
- credentials: `/etc/restic/b2-env` (root-only, never in git)
- repo encryption password: `/etc/restic/password` (already exists;
  shared by all three repos — copy lives in the password manager)

The CLI binary is **`backblaze-b2`**, not `b2` (nixpkgs renames it).

**S3 endpoint, not native b2:** restic's native `b2:` backend uses a
retired authorization API version and fails against B2 accounts created
after early 2026 with `b2_authorize_account: 400: This request is not
currently supported on API version number 3`
([restic #5741](https://github.com/restic/restic/issues/5741)). The repo
is therefore addressed through B2's S3-compatible API
(`s3:https://s3.us-west-004.backblazeb2.com/bws428-ghost-restic/restic`),
and `b2-env` uses `AWS_ACCESS_KEY_ID`/`AWS_SECRET_ACCESS_KEY` instead of
the `B2_*` names. Same key pair, same repo format — revert to the native
backend when the upstream fix ships, if desired.

## 1. Create bucket + append-only key

In a terminal (master credentials on screen — not in a Claude transcript):

```sh
backblaze-b2 account authorize
#  → paste master key ID + application key
#    (backblaze.com → Account → Application Keys → master key)

backblaze-b2 bucket create bws428-ghost-restic allPrivate

backblaze-b2 key create --bucket bws428-ghost-restic ghost-restic \
  listBuckets,listFiles,readFiles,writeFiles
#  → prints:  <keyID> <applicationKey>
```

No `deleteFiles` capability = ghost can add snapshots but never destroy
cloud history (cloud-side equivalent of the NAS repo's --append-only).

## 2. Store credentials, clean up

```sh
sudo sh -c 'umask 077; printf "AWS_ACCESS_KEY_ID=%s\nAWS_SECRET_ACCESS_KEY=%s\n" <keyID> <applicationKey> > /etc/restic/b2-env'

backblaze-b2 account clear    # wipe master creds from ~/.config
```

## 3. Seed the repo

```sh
sudo systemctl start --no-block restic-backups-cloud
```

First run pushes ~72 GiB through home upstream: hours, not minutes
(~2 h at 100 Mbps up). Interruption is safe — restic reuses uploaded
data on retry, and the 04:30 timer finishes the job across nights.

Watch: `systemctl status restic-backups-cloud` (IP egress counter),
`journalctl -u restic-backups-cloud -f`.

## 4. Verify

```sh
sudo restic-cloud snapshots     # expect one snapshot, both paths
sudo restic-cloud stats
```

## Prune ritual (few times a year — applies to NAS and cloud repos)

Neither append-only repo accepts `forget --prune` from ghost. Retention
on both grows until manually pruned:

- **Cloud:** create a temporary B2 key WITH `deleteFiles`, export
  `AWS_ACCESS_KEY_ID`/`AWS_SECRET_ACCESS_KEY` in a shell, run
  `restic -r s3:https://s3.us-west-004.backblazeb2.com/bws428-ghost-restic/restic forget --prune --keep-daily 7 --keep-weekly 4 --keep-monthly 6`
  (password from `/etc/restic/password`), then delete the temp key.
  Note: pruning deletes specific file *versions*, which on B2's S3 API
  requires the `deleteFiles` capability — the everyday key can't do it
  even accidentally.
- **NAS:** Container Manager → stop `restic-server` → remove
  `--append-only` from `OPTIONS` → start → `sudo restic-nas forget
  --prune --keep-daily 7 --keep-weekly 4 --keep-monthly 6` → restore
  `--append-only` → restart.
