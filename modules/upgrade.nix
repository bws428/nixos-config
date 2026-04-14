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

    # Run nightly at 02:00, with up to 45 minutes of random delay
    # to avoid thundering-herd issues if multiple machines upgrade.
    dates = "02:00";
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
    path = [ pkgs.git ];

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
    # The git operations run as the repo-owning user (not root) to
    # avoid creating root-owned objects in .git/, which would break
    # normal user git operations.
    #
    # Authentication uses a GitHub Personal Access Token (PAT) stored
    # in /root/.github-token (chmod 600). The token is read at runtime
    # and embedded in the push URL, avoiding any persistent credential
    # storage in git config. The ''${TOKEN} syntax is Nix's escape for
    # a literal ${...} inside a multi-line string — it ensures the
    # shell (not Nix) expands the variable.
    #
    # The `git diff --cached --quiet` check ensures we only commit
    # when flake.lock actually changed, keeping the git history clean.
    postStart = ''
      TOKEN=$(cat /root/.github-token)
      sudo -u bws428 bash -c '
        cd ${flakePath}
        git add flake.lock
        if ! git diff --cached --quiet; then
          git commit -m "flake.lock: update inputs"
          git push "https://'"$TOKEN"'@github.com/bws428/nixos-config.git" main
        fi
      '
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
