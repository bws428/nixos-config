{ pkgs, ... }:

{
  # ── nix-ld: run unpatched dynamic binaries ─────────────────────────
  # https://wiki.nixos.org/wiki/Nix-ld
  #
  # Most Linux distros ship a standard dynamic linker at
  # /lib64/ld-linux-x86-64.so.2. NixOS doesn't — every binary is
  # patched to reference its linker inside /nix/store. That breaks
  # any prebuilt binary that isn't part of nixpkgs: rustup-downloaded
  # toolchains, the official bun installer, Playwright browsers,
  # uv-installed CPython interpreters, npm modules with prebuilt
  # native bits (sharp, better-sqlite3), etc.
  #
  # nix-ld installs a shim at the standard path that reads NIX_LD
  # and NIX_LD_LIBRARY_PATH and redirects to a nixpkgs glibc and the
  # libraries listed below. Prebuilt binaries then "just work".
  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      # C/C++ runtime — needed by essentially every prebuilt binary.
      stdenv.cc.cc.lib   # libstdc++
      zlib

      # TLS / networking — rustup downloads, cargo fetch, npm registry,
      # bun install, uv python downloads, etc.
      openssl
      curl

      # Common native-dep crates, node-gyp targets, Python C exts.
      icu
      libxml2
      glib

      # GUI / Electron / Playwright / Cypress prebuilt binaries.
      libGL
      libxkbcommon
      fontconfig
      freetype
      libx11
      libxcomposite
      libxdamage
      libxext
      libxfixes
      libxrandr
      libxcb

      # Pulled in by miscellaneous prebuilt binaries (Chromium, etc.).
      nspr
      nss
      dbus
      alsa-lib
    ];
  };

  # ── envfs: virtual /bin and /usr/bin ───────────────────────────────
  # https://github.com/Mic92/envfs
  #
  # Complements nix-ld. Many scripts and binaries hardcode shebangs
  # like `#!/bin/bash` or `#!/usr/bin/env python`. On NixOS those
  # paths don't exist. envfs mounts a FUSE overlay at /bin and
  # /usr/bin that dynamically maps to whatever's in the current
  # $PATH, so random `./install.sh` scripts from GitHub run without
  # editing.
  services.envfs.enable = true;

  # ── Language toolchains ────────────────────────────────────────────
  # Managed natively (rustup, corepack, bun, uv) rather than via
  # per-project `nix develop` shells — day-to-day workflow matches
  # a standard Linux box. See CLAUDE.md "Native dev toolchains via
  # nix-ld" for the full rationale.
  environment.systemPackages = with pkgs; [
    # Rust — rustup manages channels and honors rust-toolchain.toml.
    # Don't install `cargo`/`rustc` directly; rustup overlays them.
    rustup

    # Node.js — pinned to current LTS. Ships corepack, which provides
    # pnpm and yarn without separate installs (`corepack enable`).
    nodejs_22

    # Bun — nixpkgs ships a patched bun; use this instead of the
    # official `curl | bash` installer, which downloads an FHS-linked
    # binary that would need nix-ld to run anyway.
    bun

    # Python package manager. Downloaded interpreters
    # (`uv python install`) and wheels with C extensions rely on
    # nix-ld above to resolve their dynamic linker and libs.
    uv

    # pkg-config — `cargo build` of native-dep crates (openssl-sys,
    # libz-sys, etc.) invokes it during build scripts.
    pkg-config
  ];
}
