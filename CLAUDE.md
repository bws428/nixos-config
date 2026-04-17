# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Personal NixOS flake for host `ghost`, with Home Manager integrated as a NixOS module. Tracks `nixos-unstable`. The system auto-upgrades weekly from the local clone (see `modules/upgrade.nix`), pulling latest commits and updating flake inputs before rebuilding — so changes pushed to `main` propagate to the live machine. Test before pushing.

## Common Commands

Two shell aliases (defined in `config/shell.nix`) cover day-to-day use:

```sh
rebuild   # commit, push, then `nh os switch`
clean     # `nh clean all --keep 5`
```

Raw equivalents:

```sh
sudo nixos-rebuild switch --flake .#ghost        # apply
sudo nixos-rebuild test   --flake .#ghost        # try without adding a boot entry
sudo nixos-rebuild build  --flake .#ghost        # build only
nix flake check                                  # evaluate flake
nix flake update                                 # refresh flake.lock
```

Home Manager is wired into the NixOS config (not a standalone `home-manager switch`); rebuilding the system applies home changes too.

## Architecture

- `flake.nix` — single `nixosConfigurations.ghost`. Imports each file in `modules/` explicitly and mounts `home.nix` under `home-manager.users.bws428`.
- `hardware-configuration.nix` — machine-specific; regenerate with `nixos-generate-config` if hardware changes.
- `modules/` — system-level NixOS modules split by concern (boot, users, locale, nvidia, networking, bluetooth, services, desktop, fonts, packages, upgrade). Add a new module by creating the file and adding it to the `modules = [ … ]` list in `flake.nix`.
- `home.nix` — Home Manager entry point. Imports per-program configs from `config/` (shell, helix, alacritty, niri) and places `config/niri/config.kdl` via `xdg.configFile`.
- `config/` — user-space program configs. `.nix` files are Home Manager modules; `config/niri/config.kdl` is a raw dotfile symlinked through XDG.

When adding user-facing programs, prefer a new `config/<name>.nix` imported from `home.nix`. System-wide packages/services go in the appropriate `modules/*.nix`.

## Design Conventions

### Native dev toolchains via nix-ld

Rust, Node, pnpm, and Bun are managed by their native tools (`rustup`, `corepack`, `bun`) — NOT via per-project `nix develop` / flake dev shells. Day-to-day workflow is identical to a standard Linux box.

The enabler is `programs.nix-ld.enable = true` with `programs.nix-ld.libraries` populated with common runtime dependencies (`stdenv.cc.cc.lib`, `zlib`, `openssl`, `glib`, `icu`, `libGL`, etc.) so FHS-linked binaries — rustup-managed toolchains, bun's official binary, prebuilt Node native modules — can resolve their dynamic-linker lookups into the Nix store.

Conventions when adding a new language toolchain:

- Default to the native manager through nixpkgs (`rustup`, `corepack`, `bun`, `uv`). Do NOT `curl | sh` any toolchain installer — nixpkgs ships patched wrappers.
- Only reach for `nix develop` / `direnv` + `nix-direnv` when a specific project needs pinned, reproducible toolchain versions (e.g. for a deploy). The default workflow is native.
- If a new kind of binary fails at runtime with `cannot open shared object file` or a linker error, the fix is almost always adding the missing library to `programs.nix-ld.libraries`, not wrapping the binary.

### Niri-specific plumbing

Because this system uses niri (not GNOME/KDE) as the desktop, services that GNOME would normally pull in transitively must be enabled explicitly:

- `services.avahi` (with `nssmdns4 = true`, `openFirewall = true`) — mDNS-based device discovery. Required for Brother network printers to appear in CUPS auto-discovery, for Chromecast/AirPlay targets, and for `.local` hostname resolution.
- `services.gvfs` — Nautilus (and any GIO-based file manager) depends on gvfs to see mountable volumes, network shares, MTP devices, and Trash.
- `services.udisks2` — powers click-to-mount for removable and non-boot drives in Nautilus.

When a GUI program that "just works" on GNOME misbehaves here, check whether it depends on one of these before declaring it broken.

### Declarative disk mounts

Non-boot disks declared in `hardware-configuration.nix` (or a dedicated `modules/storage.nix`) should use `nofail` + `x-systemd.automount` + `x-systemd.device-timeout=5s` so a missing or failed drive doesn't drop the system into emergency mode at boot. This matters given the weekly auto-upgrade: an unattended rebuild must not be wedged by a disconnected disk.

Example:

```nix
fileSystems."/mnt/scratch" = {
  device = "/dev/disk/by-uuid/<uuid>";
  fsType = "ext4";
  options = [ "nofail" "x-systemd.automount" "x-systemd.device-timeout=5s" ];
};
```

Get UUIDs with `blkid` or `lsblk -f`.

## Before Making Config Changes

Before writing or modifying any Nix configuration, consult the relevant documentation to ensure you are using canonical NixOS/Home Manager patterns:

- **NixOS options**: search https://search.nixos.org/options for the correct option names, types, and defaults.
- **Home Manager options**: search https://home-manager-options.extranix.com for Home Manager module options.
- **Nixpkgs packages**: search https://search.nixos.org/packages to verify package attribute names.
- **NixOS Wiki**: check https://wiki.nixos.org for recommended patterns and common pitfalls.

Prefer declarative NixOS/Home Manager module options over raw file writes or imperative workarounds. If a program has a dedicated `programs.<name>` or `services.<name>` module, use it rather than adding the package manually and writing config files by hand.
