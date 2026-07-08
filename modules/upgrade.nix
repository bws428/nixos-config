{ config, pkgs, flakePath, ... }:

{
  # ── Automatic system upgrades (with flakes) ────────────────────────
  # https://wiki.nixos.org/wiki/Automatic_system_upgrades
  #
  # The system.autoUpgrade module creates a systemd service
  # (nixos-upgrade.service) and timer that periodically runs
  # `nixos-rebuild switch --flake <flake>#ghost` to rebuild the system
  # from the latest flake configuration.
  system.autoUpgrade = {
    enable = true;

    # Path to the local flake and the NixOS configuration to build.
    # flakePath is passed in from flake.nix and points to this repo.
    flake = "${flakePath}#ghost";

    # Build and stage the new generation as the default boot entry,
    # but do NOT activate it on the running system. This avoids
    # `switch-to-configuration` failing its pre-switch checks when
    # nixpkgs flips a critical component (e.g. dbus -> dbus-broker),
    # which would block live activation but is safe across a reboot.
    # The user is reminded to reboot via a login-time check in
    # config/shell.nix.
    operation = "boot";

    # Show full build output in the journal for easier debugging.
    flags = [
      "--print-build-logs"
      "--no-link"
    ];

    # Run weekly at 02:00, with up to 45 minutes of random delay.
    # Weekly (vs. nightly) reduces exposure to unstable-channel
    # regressions and avoids GC evicting the last-known-good generation
    # during long idle periods.
    dates = "Tue 02:00";
    randomizedDelaySec = "45min";
  };

  # ── Customizations to the upgrade service ──────────────────────────
  #
  # The systemd service created by system.autoUpgrade can be extended
  # with additional attributes. Here we add preStart and postStart
  # hooks to (1) pull the latest commits and update flake inputs
  # before rebuilding, and (2) commit and push the updated flake.lock
  # back to GitHub after a successful rebuild.
  systemd.services.nixos-upgrade = {
    # Make git available to the pre/post scripts.
    path = [ pkgs.git pkgs.util-linux ];

    # ── preStart: runs before nixos-rebuild ─────────────────────────
    #
    # This service runs as root, but the flake repo is owned by the
    # user, so every command that WRITES to the repo (git and
    # `nix flake update`, which rewrites flake.lock) runs as the owner
    # via runuser — root-created files in .git/ break later user git
    # operations. The safe.directory entry in root's gitconfig is
    # still required for READING: nixos-rebuild evaluates the flake as
    # root, and Nix's internal libgit2 (which reads gitconfig but
    # ignores GIT_CONFIG_* env vars) refuses user-owned repos without it.
    #
    # We discard any local flake.lock changes (left over from a
    # previous run), pull the latest commits from the remote, and
    # update the flake inputs that are safe to take unattended.
    #
    # Only well-governed inputs auto-update (nixpkgs, home-manager,
    # nix-flatpak). Inputs that ship kernel-space code from a personal
    # repo (mt7927) or binaries signed by a third-party cache key
    # (noctalia, noctalia-greeter) stay pinned to flake.lock until a
    # deliberate manual bump:
    #
    #   nix flake update mt7927 noctalia noctalia-greeter   # any subset
    #   rebuild
    preStart = ''
      git config --global safe.directory ${flakePath}
      cd ${flakePath}
      runuser -u bws428 -- git checkout -- flake.lock
      runuser -u bws428 -- git pull
      runuser -u bws428 -- nix flake update nixpkgs home-manager nix-flatpak
    '';

    # ── postStart: runs after a successful nixos-rebuild ────────────
    #
    # If `nix flake update` changed flake.lock, commit and push it so
    # the lock file on GitHub always reflects what was actually built.
    # The `git diff --cached --quiet` check skips the commit when
    # nothing changed, keeping history clean.
    #
    # Git runs as the repo-owning user via `runuser -u bws428 --`
    # (from util-linux): root-created files in .git/ would break
    # normal user git operations.
    #
    # The push authenticates over SSH with a deploy key that has
    # write access to this one repo only (~/.ssh/nixos-config-deploy;
    # public half registered under repo Settings → Deploy keys). No
    # secret ever appears on a command line or in error output.
    postStart = ''
      cd ${flakePath}
      runuser -u bws428 -- git add flake.lock
      if runuser -u bws428 -- git diff --cached --quiet; then
        echo "flake.lock unchanged, nothing to push"
      else
        runuser -u bws428 -- git commit -m "flake.lock: update inputs"
        runuser -u bws428 -- git \
          -c core.sshCommand="ssh -i /home/bws428/.ssh/nixos-config-deploy -o IdentitiesOnly=yes" \
          push git@github.com:bws428/nixos-config.git main
      fi
    '';
  };

  # ── Automatic garbage collection ──────────────────────────────────
  # Nightly `nh clean all --keep 5`: removes old system and user
  # generations and their unreachable store paths, keeping the 5 most
  # recent as rollback targets. Keep in sync with
  # boot.loader.systemd-boot.configurationLimit in boot.nix.
  # (nh asserts mutual exclusion with nix.gc.automatic — don't re-add
  # a nix.gc block.)
  programs.nh.clean = {
    enable = true;
    dates = "03:00";
    extraArgs = "--keep 5";
  };
}
