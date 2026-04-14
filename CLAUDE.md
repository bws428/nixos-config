# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Personal NixOS flake for host `ghost`, with Home Manager integrated as a NixOS module. Tracks `nixos-unstable`. The system auto-upgrades nightly from the local clone (see `modules/upgrade.nix`), pulling latest commits and updating flake inputs before rebuilding — so changes pushed to `main` propagate to the live machine. Test before pushing.

## Common Commands

Rebuild from the flake in this directory:

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

## Before Making Config Changes

Before writing or modifying any Nix configuration, consult the relevant documentation to ensure you are using canonical NixOS/Home Manager patterns:

- **NixOS options**: search https://search.nixos.org/options for the correct option names, types, and defaults.
- **Home Manager options**: search https://home-manager-options.extranix.com for Home Manager module options.
- **Nixpkgs packages**: search https://search.nixos.org/packages to verify package attribute names.
- **NixOS Wiki**: check https://wiki.nixos.org for recommended patterns and common pitfalls.

Prefer declarative NixOS/Home Manager module options over raw file writes or imperative workarounds. If a program has a dedicated `programs.<name>` or `services.<name>` module, use it rather than adding the package manually and writing config files by hand.
