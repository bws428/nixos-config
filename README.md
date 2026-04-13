# nixos-config

Personal NixOS flake for host `ghost`, with Home Manager wired in as a NixOS module. Tracks `nixos-unstable`. The live system auto-upgrades nightly from this repo (see `modules/upgrade.nix`), so pushes to `main` deploy themselves.

## Day-to-day

```sh
sudo nixos-rebuild switch --flake .#ghost   # apply
sudo nixos-rebuild test   --flake .#ghost   # try without a boot entry
nix flake update                            # refresh flake.lock
```

Home Manager runs inside the NixOS rebuild — there's no separate `home-manager switch`.

## Bootstrapping from a fresh NixOS install

Assumes the same machine (`ghost`). For a different box, see [New machine](#new-machine) below.

1. **Install NixOS** from the official ISO (minimal is fine — niri/desktop come from the flake). During install, set:
   - hostname: `ghost`
   - primary user: `bws428`
   - bootloader matching `modules/boot.nix`

2. **Boot into the new system and clone the repo** (flakes aren't enabled yet, so pass the flag):

   ```sh
   nix-shell -p git --run 'git clone https://github.com/bws428/nixos-config ~/.nixos-config'
   cd ~/.nixos-config
   ```

3. **Overwrite the committed hardware config** with the one the installer generated for this box (the repo commits `ghost`'s hardware config; on any other machine you must replace it before rebuilding):

   ```sh
   sudo cp /etc/nixos/hardware-configuration.nix ./hardware-configuration.nix
   ```

4. **First rebuild** — flakes need to be enabled explicitly for this one command, after which `nix.settings.experimental-features` in the config takes over:

   ```sh
   sudo nixos-rebuild switch \
     --flake ~/.nixos-config#ghost \
     --extra-experimental-features 'nix-command flakes'
   ```

5. **Set passwords and reboot:**

   ```sh
   sudo passwd bws428
   sudo passwd lyndsey    # second user defined in modules/users.nix
   sudo reboot
   ```

After this, auto-upgrade pulls from `github:bws428/nixos-config` nightly; changes just need `git push`.

### New machine

Same as above, plus:

- Change `networking.hostName` in `modules/networking.nix` and the `nixosConfigurations.<name>` key in `flake.nix`.
- Review `modules/nvidia.nix` — drop it from `flake.nix` if the new box isn't NVIDIA.
- Adjust or remove the `lyndsey` user in `modules/users.nix`.

## Layout

- `flake.nix` — single `nixosConfigurations.ghost`; imports every file in `modules/` and mounts `home.nix` under Home Manager.
- `hardware-configuration.nix` — machine-specific; committed for `ghost`. Regenerate with `nixos-generate-config` when moving to a new box.
- `modules/` — system-level NixOS modules split by concern.
- `home.nix` + `config/` — Home Manager entry point and per-program user configs (shell, helix, alacritty, niri).
