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

    # Show full build output in the journal for easier debugging.
    flags = [
      "--print-build-logs"
    ];

    # Run weekly on Sunday at 02:00, with up to 45 minutes of random
    # delay. Weekly (vs. nightly) reduces exposure to unstable-channel
    # regressions and avoids GC evicting the last-known-good generation
    # during long idle periods.
    dates = "Sun 02:00";
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
    # user. Git's "safe.directory" check (introduced in Git 2.35.2)
    # blocks root from operating on user-owned repos by default.
    # We mark flakePath as safe in root's global gitconfig so that
    # both the git CLI and Nix's internal libgit2 (which reads
    # gitconfig but ignores GIT_CONFIG_* env vars) can access it.
    #
    # Then we discard any local flake.lock changes (left over from a
    # previous run), pull the latest commits from the remote, and
    # run `nix flake update` to refresh all flake inputs. The rebuilt
    # system will use whatever nixpkgs (and other inputs) are current
    # at the time of the upgrade.
    preStart = ''
      git config --global safe.directory ${flakePath}
      cd ${flakePath}
      git checkout -- flake.lock
      git pull
      nix flake update
    '';

    # ── postStart: runs after a successful nixos-rebuild ────────────
    #
    # If `nix flake update` changed flake.lock, we commit and push it
    # so the repo stays in sync with the running system. This means
    # the lock file on GitHub always reflects what was actually built.
    #
    # Since this service runs as root but the repo is owned by bws428,
    # git operations must run as the repo-owning user — otherwise root
    # creates root-owned files in .git/objects/, which breaks normal
    # user git operations (git add, git commit, etc.).
    #
    # We use `runuser -u bws428 --` (from util-linux) to execute each
    # git command as the correct user. runuser is designed for exactly
    # this use case in system services: it switches the effective UID
    # without spawning a subshell or altering PATH, unlike sudo which
    # drops PATH and requires bash to be explicitly available.
    #
    # Authentication uses a GitHub Personal Access Token (PAT) stored
    # in /root/.github-token (chmod 600). The token is read as root
    # (only root can access the file) then passed into the push URL.
    # The ''${TOKEN} syntax is Nix's escape for a literal ${...}
    # inside a multi-line string — it ensures the shell (not Nix)
    # expands the variable.
    #
    # The `git diff --cached --quiet` check ensures we only commit
    # when flake.lock actually changed, keeping the git history clean.
    postStart = ''
      TOKEN=$(cat /root/.github-token)
      cd ${flakePath}
      runuser -u bws428 -- git add flake.lock
      if runuser -u bws428 -- git diff --cached --quiet; then
        echo "flake.lock unchanged, nothing to push"
      else
        runuser -u bws428 -- git commit -m "flake.lock: update inputs"
        runuser -u bws428 -- git push "https://''${TOKEN}@github.com/bws428/nixos-config.git" main
      fi
    '';
  };

  # ── Automatic garbage collection ──────────────────────────────────
  # https://wiki.nixos.org/wiki/Storage_optimization
  #
  # Removes old system generations and their unreachable store paths
  # nightly, keeping the 5 most recent generations as rollback targets.
  # This should be kept in sync with boot.loader.systemd-boot.configurationLimit
  # in boot.nix so that boot entries and retained generations match.
  nix.gc = {
    automatic = true;
    dates = "03:00";
    options = "--keep 5";
  };
}
