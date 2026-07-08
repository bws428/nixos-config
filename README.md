# nixos-config

Personal NixOS flake for host `ghost`, with Home Manager wired in as a NixOS module. Tracks `nixos-unstable`.

## Day-to-day

One shell alias covers almost everything (defined in `config/shell.nix`):

```sh
rebuild   # cd to the flake, commit, push, then `nh os switch`
```

`rebuild` commits any local changes with a stock message and pushes before switching, so the live machine and `origin/main` stay in sync. Home Manager runs inside the rebuild — there's no separate `home-manager switch`.

Raw equivalents, if needed:

```sh
sudo nixos-rebuild switch --flake .#ghost   # apply
sudo nixos-rebuild test   --flake .#ghost   # try without a boot entry
nix flake update                            # refresh flake.lock
```

## Weekly auto-upgrade

A systemd timer runs Tuesday at 02:00 (±45 min). It resets `flake.lock`, pulls `origin/main`, runs `nix flake update nixpkgs home-manager nix-flatpak`, and rebuilds. So pushed config changes **and** upstream nixpkgs updates both propagate weekly.

The remaining inputs (`mt7927`, `noctalia`, `noctalia-greeter`) are third-party code that runs in kernel space or arrives via an external binary cache, so they stay pinned until a deliberate `nix flake update <input>` + `rebuild`.

Nightly GC at 03:00 (`nh clean all --keep 5`) keeps the 5 most recent generations; store optimization runs automatically. See `programs.nh.clean` in `modules/upgrade.nix`.

Check on the last run:

```sh
systemctl status nixos-upgrade.service     # exit code + recent log tail
systemctl list-timers nixos-upgrade.timer  # last and next fire times
```

Manually trigger an upgrade to verify everything works:

```sh
sudo systemctl start nixos-upgrade.service
journalctl -u nixos-upgrade.service -f     # follow the live output
```

## Backups

3-2-1 scheme via restic (`modules/backups.nix`): nightly snapshots of `/home/bws428` and `/mnt/seagate500` to three independent repos — Toshiba250 (00:00, self-pruning), Synology rest-server (03:00, append-only), Backblaze B2 (04:30, append-only). Quick look:

```sh
sudo restic-local snapshots        # also: restic-nas, restic-cloud
systemctl list-timers 'restic-*'   # last and next fire times
```

Primer, restore procedures, the append-only prune ritual, and the bare-metal disaster drill all live in [`docs/system-backups.md`](docs/system-backups.md).

## Bootstrapping a fresh install

1. Install NixOS from the graphical ISO. Hostname `ghost`, primary user `bws428` with wheel. Desktop choice doesn't matter — niri comes from the flake.
2. Clone and rebuild:

   ```sh
   nix-shell -p git --run 'git clone https://github.com/bws428/nixos-config ~/.nixos-config'
   sudo cp /etc/nixos/hardware-configuration.nix ~/.nixos-config/hardware-configuration.nix
   sudo nixos-rebuild switch --flake ~/.nixos-config#ghost \
     --extra-experimental-features 'nix-command flakes'
   ```

3. `sudo passwd bws428` and reboot.
4. Recreate the backup secrets — root-only files deliberately absent from this (public) repo: `/etc/restic/password` (repo encryption password, copy in the password manager), `/etc/restic/nas-repo` (rest-server URL with credentials), `/etc/restic/b2-env` (B2 key pair). Formats and recovery details: [`docs/system-backups.md`](docs/system-backups.md). Until these exist the restic timers fail harmlessly.

The hardware copy in step 2 can be skipped when reinstalling on the same disk layout. Flakes only need the `--extra-experimental-features` flag on this first rebuild; afterwards `nix.settings` takes over.

## New machine

- Change `networking.hostName` in `modules/networking.nix` and the `nixosConfigurations.<name>` key in `flake.nix`.
- Review `modules/nvidia.nix` — drop it from `flake.nix` if the box isn't NVIDIA.
- Update `flakePath` in `flake.nix` if the username differs.

## Layout

- `flake.nix` — single `nixosConfigurations.ghost`; imports every file in `modules/` and mounts `home.nix` under Home Manager.
- `hardware-configuration.nix` — machine-specific; regenerate with `nixos-generate-config` on a new box.
- `modules/` — system-level NixOS modules split by concern.
- `home.nix` + `config/` — Home Manager entry point and per-program user configs (shell, tmux, helix, ghostty, alacritty, btop, rofi, beets, mpd, niri, noctalia).
- `docs/` — operational runbooks (currently: backups & restore).
