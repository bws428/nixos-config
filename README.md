# nixos-config

Personal NixOS flake for host `ghost`, with Home Manager wired in as a NixOS module. Tracks `nixos-unstable`.

## Day-to-day

```sh
sudo nixos-rebuild switch --flake .#ghost   # apply
sudo nixos-rebuild test   --flake .#ghost   # try without a boot entry
nix flake update                            # refresh flake.lock
```

Home Manager runs inside the NixOS rebuild — there's no separate `home-manager switch`.

## Nightly auto-upgrade

A systemd timer (`nixos-upgrade.service`) runs at 02:00 each night (with up to 45 min random delay). Before rebuilding it:

1. Resets any local `flake.lock` changes from the previous run
2. Pulls the latest commits from `origin/main`
3. Runs `nix flake update` to refresh nixpkgs and home-manager inputs
4. Rebuilds with `nixos-rebuild switch`

This means pushing config changes to `main` **and** upstream nixpkgs updates both propagate automatically overnight.

A nightly garbage collection follows at 03:00, keeping the 3 most recent generations. Nix store optimization runs automatically as well.

See `modules/upgrade.nix` for the full configuration.

## Bootstrapping `ghost` from a fresh install

Start from the standard NixOS graphical installer ISO.

### 1. Install NixOS

Run through the graphical installer with these settings:

- Hostname: `ghost`
- Primary user: `bws428` (with sudo/wheel)
- Disk partitioning and bootloader as appropriate for the machine
- Desktop environment doesn't matter — niri and the full desktop come from the flake

Reboot into the fresh install when prompted.

### 2. Clone this repo

Flakes aren't enabled yet on a stock install, so use `nix-shell` to get git:

```sh
nix-shell -p git --run 'git clone https://github.com/bws428/nixos-config ~/.nixos-config'
cd ~/.nixos-config
```

### 3. Replace the hardware config

The repo commits `ghost`'s hardware config, but the installer generated a fresh one for this disk/partition layout. Overwrite it:

```sh
sudo cp /etc/nixos/hardware-configuration.nix ./hardware-configuration.nix
```

If re-installing on the same machine with the same disk layout, you can skip this — the committed config should still be correct.

### 4. First rebuild

Flakes must be enabled explicitly for this first command. After this rebuild, `nix.settings.experimental-features` in the config takes over:

```sh
sudo nixos-rebuild switch \
  --flake ~/.nixos-config#ghost \
  --extra-experimental-features 'nix-command flakes'
```

### 5. Set passwords and reboot

The flake defines users declaratively but doesn't set passwords. Set them now:

```sh
sudo passwd bws428
sudo passwd lyndsey    # second user defined in modules/users.nix
sudo reboot
```

After reboot you'll land in the full niri desktop with all packages and configs applied. The nightly auto-upgrade timer is already active.

## New machine

Same steps as above, plus:

- Change `networking.hostName` in `modules/networking.nix` and the `nixosConfigurations.<name>` key in `flake.nix`.
- Review `modules/nvidia.nix` — drop it from `flake.nix` if the new box isn't NVIDIA.
- Adjust or remove the `lyndsey` user in `modules/users.nix`.
- Update `modules/upgrade.nix` to point at the correct local flake path if the username differs.

## Layout

- `flake.nix` — single `nixosConfigurations.ghost`; imports every file in `modules/` and mounts `home.nix` under Home Manager.
- `hardware-configuration.nix` — machine-specific; committed for `ghost`. Regenerate with `nixos-generate-config` when moving to a new box.
- `modules/` — system-level NixOS modules split by concern.
- `home.nix` + `config/` — Home Manager entry point and per-program user configs (shell, helix, alacritty, niri).
