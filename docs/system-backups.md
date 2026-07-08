# System backups — restic primer & operations

For when you need to restore *now* and don't want to depend on an LLM.
Declarative config lives in `modules/backups.nix`; this doc covers the
concepts, the everyday commands, and the rare rituals.

## The 60-second mental model

- A **repository** is an encrypted, deduplicated blob store. Ghost has
  three independent ones (3-2-1): same data, three fates.
- A **snapshot** is a point-in-time record of the backed-up paths
  (`/home/bws428` + `/mnt/seagate500`). Snapshots share unchanged data,
  so 30 snapshots ≠ 30× the size.
- Every repo is locked with the **same password**: `/etc/restic/password`
  on ghost, copy in the password manager. **No password = no data.**
  Nobody — not Backblaze, not restic — can recover it.
- Restores never touch the original files; they write to a `--target`
  directory you choose. You can't clobber your system by restoring.

## The three stores

NixOS generates a wrapper per store with repo + credentials + password
pre-wired. Always run them with `sudo`:

| Wrapper | Store | Notes |
|---|---|---|
| `restic-local` | Toshiba250 (`/mnt/toshiba250/restic-repo`) | fastest; prunes itself |
| `restic-nas`   | Synology rest-server (192.168.100.72) | append-only |
| `restic-cloud` | Backblaze B2, us-west-004 | append-only, S3 endpoint |

Everything below works with any of the three — swap the wrapper name.
Prefer `restic-local` for restores (fastest); the others exist for when
it doesn't.

## 1. Manual backup

The right way is to trigger the systemd job (it also runs the integrity
check, and prune on the local repo):

```sh
sudo systemctl start restic-backups-local    # or -nas / -cloud
journalctl -u restic-backups-local -f        # watch it
```

(The timers already run these nightly at 00:00 / 03:00 / 04:30 — manual
runs are for "I just finished something important and want it saved now.")

## 2. Query snapshots

```sh
sudo restic-local snapshots                  # list all snapshots
sudo restic-local snapshots --latest 1       # just the newest
sudo restic-local ls latest /home/bws428/Documents   # list files inside
sudo restic-local find 'flight-log*'         # which snapshots have this file?
sudo restic-local stats                      # total size, file count
```

## 3. Restore

**A few files or a directory** — restore into a scratch dir, then copy
what you need into place:

```sh
sudo restic-local restore latest --target /tmp/restore \
  --include /home/bws428/Documents/important.txt
# result lands at /tmp/restore/home/bws428/Documents/important.txt
```

**Browse before restoring** (often the nicest way — snapshots appear as
a read-only filesystem):

```sh
mkdir -p /tmp/snapshots
sudo restic-local mount /tmp/snapshots
# → browse /tmp/snapshots/snapshots/<date>/... in another terminal
# Ctrl-C in the first terminal to unmount
```

**A specific point in time** — use the snapshot ID from `snapshots`
instead of `latest`:

```sh
sudo restic-local restore 458fb70d --target /tmp/restore --include /home/bws428/Notes
```

**Everything** (post-disaster, onto a rebuilt machine):

```sh
sudo restic-local restore latest --target /
```

## Other commands worth knowing

```sh
sudo restic-local diff <snapA> <snapB>       # what changed between two snapshots
sudo restic-local check                      # verify repo integrity
sudo restic-local unlock                     # clear stale lock after an interrupted run
sudo restic-local forget --dry-run --keep-daily 7 --keep-weekly 4 --keep-monthly 6
                                             # preview retention (local only; see below)
```

Append-only reality check: `restic-nas` and `restic-cloud` will **refuse**
`forget`/`prune` by design — that's ghost being unable to destroy its own
history. See the prune ritual below.

## Prune ritual (a few times a year)

The local repo prunes itself after every run. The two append-only repos
grow until pruned manually:

**Cloud (B2):** ghost's everyday key lacks `deleteFiles`, so pruning
needs a temporary privileged key:

```sh
backblaze-b2 account authorize        # master key, from backblaze.com
backblaze-b2 key create --bucket bws428-ghost-restic prune-temp \
  listBuckets,listFiles,readFiles,writeFiles,deleteFiles
# → prints <keyID> <applicationKey>

export AWS_ACCESS_KEY_ID=<keyID>
export AWS_SECRET_ACCESS_KEY=<applicationKey>
restic -r s3:https://s3.us-west-004.backblazeb2.com/bws428-ghost-restic/restic \
  --password-file /etc/restic/password \
  forget --prune --keep-daily 7 --keep-weekly 4 --keep-monthly 6

backblaze-b2 key delete <keyID>       # destroy the temp key
backblaze-b2 account clear            # wipe master creds from ~/.config
```

(Why the temp key: pruning deletes specific file *versions*, which on
B2's S3 API requires `deleteFiles` — the everyday key can't do it even
accidentally.)

**NAS (Synology):** DSM → Container Manager → stop `restic-server` →
remove `--append-only` from the container's `OPTIONS` env var → start,
then:

```sh
sudo restic-nas forget --prune --keep-daily 7 --keep-weekly 4 --keep-monthly 6
```

then restore `--append-only` and restart the container.

## B2 administration notes

- Bucket: `bws428-ghost-restic` (private), region `us-west-004`.
- Ghost's everyday key has `listBuckets,listFiles,readFiles,writeFiles`
  — no `deleteFiles` = cloud-side append-only. (S3 deletes on a
  versioned bucket only write hide-markers, so restic can clear its own
  lock files but history stays recoverable.)
- Credentials live in `/etc/restic/b2-env` (root-only, never in git) as
  `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY`. To rotate: create a new
  key with the same capabilities, rewrite that file, delete the old key.
- **Why S3 and not restic's native `b2:` backend:** the native backend
  uses a retired authorization API and fails against B2 accounts created
  after early 2026 (`b2_authorize_account: 400: ... API version number 3`,
  [restic #5741](https://github.com/restic/restic/issues/5741)). Same
  key pair, same repo format — revert when upstream fixes it, if desired.
- The nixpkgs CLI binary is **`backblaze-b2`**, not `b2` (name clash
  with boost-build).

## Disaster drill: ghost is a smoking crater

What you need, in order:

1. **The repo password** — from the password manager. This is the single
   point of failure; everything else is replaceable.
2. **Any Linux box with restic** (`nix-shell -p restic`, `apt install restic`, whatever).
3. **Reach one repo:**
   - *Toshiba250 survived:* plug it in, mount it.
     `restic -r /mnt/<wherever>/restic-repo snapshots`
   - *NAS survived:* repo URL format is
     `rest:http://ghost:<rest-server password>@192.168.100.72:8000/ghost`
     (that password is in `/etc/restic/nas-repo` on ghost — if ghost is
     gone, reset it in the container's `.htpasswd` on the NAS).
   - *Only B2 survived:* log in to backblaze.com, create an application
     key for bucket `bws428-ghost-restic`, then:

     ```sh
     export AWS_ACCESS_KEY_ID=<keyID>
     export AWS_SECRET_ACCESS_KEY=<applicationKey>
     restic -r s3:https://s3.us-west-004.backblazeb2.com/bws428-ghost-restic/restic snapshots
     ```

4. Restore as in section 3, with `-r <repo>` in place of the wrapper.

Test this once a year: pick a random file, restore it from the cloud
repo on some other machine, diff against the original.
