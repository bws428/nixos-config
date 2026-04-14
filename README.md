# nixos-config

Personal NixOS flake for host `ghost`, with Home Manager wired in as a NixOS module. Tracks `nixos-unstable`.

## Day-to-day

Two shell aliases cover almost everything (defined in `config/shell.nix`):

```sh
rebuild   # cd to the flake, commit, push, then `nh os switch`
clean     # `nh clean all --keep 5`
```

`rebuild` commits any local changes with a stock message and pushes before switching, so the live machine and `origin/main` stay in sync. Home Manager runs inside the rebuild — there's no separate `home-manager switch`.

Raw equivalents, if needed:

```sh
sudo nixos-rebuild switch --flake .#ghost   # apply
sudo nixos-rebuild test   --flake .#ghost   # try without a boot entry
nix flake update                            # refresh flake.lock
```

## Nightly auto-upgrade

A systemd timer runs at 02:00 (±45 min). It resets `flake.lock`, pulls `origin/main`, runs `nix flake update`, and rebuilds. So pushed config changes **and** upstream nixpkgs updates both propagate overnight.

Nightly GC at 03:00 keeps the 5 most recent generations; store optimization runs automatically. See `modules/upgrade.nix`.

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

The hardware copy in step 2 can be skipped when reinstalling on the same disk layout. Flakes only need the `--extra-experimental-features` flag on this first rebuild; afterwards `nix.settings` takes over.

## New machine

- Change `networking.hostName` in `modules/networking.nix` and the `nixosConfigurations.<name>` key in `flake.nix`.
- Review `modules/nvidia.nix` — drop it from `flake.nix` if the box isn't NVIDIA.
- Update `flakePath` in `flake.nix` if the username differs.

## Layout

- `flake.nix` — single `nixosConfigurations.ghost`; imports every file in `modules/` and mounts `home.nix` under Home Manager.
- `hardware-configuration.nix` — machine-specific; regenerate with `nixos-generate-config` on a new box.
- `modules/` — system-level NixOS modules split by concern.
- `home.nix` + `config/` — Home Manager entry point and per-program user configs (shell, helix, alacritty, niri).
