# AGENTS.md

Guidance for AI coding agents working in this repository.

## Overview

Personal NixOS flake for host `ghost`, with Home Manager integrated as a NixOS module. Tracks `nixos-unstable`. The system auto-upgrades weekly from the local clone (see `modules/upgrade.nix`), pulling latest commits and updating the well-governed flake inputs (nixpkgs, home-manager, nix-flatpak) before rebuilding — so changes pushed to `main` propagate to the live machine. Test before pushing. The third-party inputs (mt7927, noctalia-greeter) are deliberately excluded from auto-update; bump them only when asked, via `nix flake update <input>`.

## Common Commands

One shell alias (defined in `config/shell.nix`) covers day-to-day use:

```sh
rebuild [commit-msg]   # commit, `nh os switch`, then push on success
```

Garbage collection is automatic — nightly `nh clean all --keep 5` via `programs.nh.clean` in `modules/upgrade.nix`. Run the same command manually for an immediate sweep.

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

- `flake.nix` — single `nixosConfigurations.ghost`. Imports each file in `modules/` explicitly (grouped: hardware, system, desktop, fonts & packages, development, Home Manager) and mounts `home.nix` under `home-manager.users.bws428`.
- `hardware-configuration.nix` — machine-specific boot disk, `/boot`, and swap; regenerate with `nixos-generate-config` if hardware changes. Data drives live in `modules/storage.nix`, not here.
- `modules/` — system-level NixOS modules split by concern:
  - System basics: `boot`, `users`, `locale`, `bluetooth`, `networking`, `services`, `fonts`, `packages`, `upgrade` (weekly auto-upgrade + nightly GC).
  - `mt7927-wifi.nix` — out-of-tree MediaTek Wi-Fi/BT modules (via the `mt7927` flake input).
  - `storage.nix` — data drives under `/mnt/*`, all `nofail` + automounted.
  - `backups.nix` — 3-2-1 restic: local disk, Synology NAS, Backblaze B2. Runbook: `docs/system-backups.md`.
  - `nvidia.nix` — dual-GPU: RTX 5080 16 GB (displays) + RTX 3090 24 GB (power-capped, for LLMs); open driver.
  - `llms.nix` — llama-swap local-LLM proxy (OpenAI-compatible, 127.0.0.1:8080); model files in `/var/lib/llms`, idle-unloaded to free VRAM.
  - `desktop.nix` — niri compositor + system-side prerequisites for the Noctalia shell.
  - `greeter.nix` — Noctalia greeter on greetd (replaces GDM).
  - `dev.nix` — nix-ld + envfs + native language toolchains (see Design Conventions).
  Add a new module by creating the file and adding it to the `modules = [ … ]` list in `flake.nix`.
- `home.nix` — Home Manager entry point. Imports per-program modules from `config/` and places `config/niri/config.kdl` via `xdg.configFile`.
- `config/` — user-space program configs. Each `.nix` is a Home Manager module managing one program (niri, noctalia, shell, helix, alacritty, ghostty, tmux, btop, mpd, beets, herdr); a subdirectory may carry raw assets the module deploys itself (e.g. `config/noctalia/` ships theme templates via its own `xdg.configFile`).
- `docs/` — ops runbooks that don't depend on rebuilding: `system-backups.md` covers restic restores, the append-only prune ritual, and the bare-metal disaster drill.

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

### Desktop shell: Noctalia v5

- Noctalia is the whole desktop shell (bar, launcher, lock screen, notifications, OSD) and also the greeter. The shell follows nixpkgs: the `programs.noctalia` home module is bundled with Home Manager (upstreamed from the Noctalia repo — do NOT also import a third-party copy, it double-declares the option), and the package is `pkgs.noctalia` (the module's default), so the shell moves with the weekly auto-upgrade. The greeter stays on the pinned `noctalia-greeter` flake input, with prebuilt binaries substituted from upstream's cachix (substituter in `modules/desktop.nix`).
- The shell runs as a systemd user service tied to `graphical-session.target` (config: `config/noctalia/noctalia.nix`). System-side prerequisites (UPower, power-profiles-daemon, NetworkManager, Bluetooth, dconf, gnome-keyring, polkit) live in `modules/desktop.nix`.
- The greeter's wallpaper/palette syncs only on manual "Sync Now" — a polkit quirk upstream, documented in `modules/greeter.nix`. Don't "fix" the missing auto-sync.

### Declarative disk mounts

Non-boot disks (declared in `modules/storage.nix`) should use `nofail` + `x-systemd.automount` + `x-systemd.device-timeout=5s` so a missing or failed drive doesn't drop the system into emergency mode at boot. This matters given the weekly auto-upgrade: an unattended rebuild must not be wedged by a disconnected disk.

Example:

```nix
fileSystems."/mnt/scratch" = {
  device = "/dev/disk/by-uuid/<uuid>";
  fsType = "ext4";
  options = [ "nofail" "x-systemd.automount" "x-systemd.device-timeout=5s" ];
};
```

Get UUIDs with `blkid` or `lsblk -f`.

## Working Constraints

Exactly one build command is sanctioned. Run it to prove a change is sound before handing work back:

```sh
nix build --no-link .#nixosConfigurations.ghost.config.system.build.toplevel
```

It builds everything `nixos-rebuild switch` would build, stops short of activating, and leaves no `./result` behind. It evaluates the whole config, so it subsumes `nix flake check`.

Everything else is blocked:

- **Never activate.** No `rebuild`, `nh os switch`, `nixos-rebuild`, or `sudo nixos-rebuild` — in any form, `switch` / `test` / `boot` / `build` / `dry-activate` alike. Activation is the user's call, always.
- **Never a bare `nix build`.** Without `--no-link` it drops a `./result` symlink into the repo, which then shows up in `git status`.
- **No partial-attribute builds.** Building one attribute proves that attribute compiles and hides breakage everywhere else. Build the toplevel.

A clean build proves derivations compile — not that activation scripts, systemd units, or kernel modules work at runtime. Report it as "builds", never as "works".

## Before Making Config Changes

Before writing or modifying any Nix configuration, consult the relevant documentation to ensure you are using canonical NixOS/Home Manager patterns:

- **NixOS options**: search https://search.nixos.org/options for the correct option names, types, and defaults.
- **Home Manager options**: search https://home-manager-options.extranix.com for Home Manager module options.
- **Nixpkgs packages**: search https://search.nixos.org/packages to verify package attribute names.
- **NixOS Wiki**: check https://wiki.nixos.org for recommended patterns and common pitfalls.

Prefer declarative NixOS/Home Manager module options over raw file writes or imperative workarounds. If a program has a dedicated `programs.<name>` or `services.<name>` module, use it rather than adding the package manually and writing config files by hand.
