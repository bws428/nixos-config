{ config, pkgs, ... }:

{
  # ── Bootloader (systemd-boot) ───────────────────────────────────────
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Time in seconds to show the boot menu before auto-selecting the default.
  boot.loader.timeout = 5;

  # Limit the number of NixOS generations listed in the boot menu.
  # Each `nixos-rebuild switch` adds a new entry; without a limit, old
  # entries accumulate and can fill the (often small) EFI System Partition.
  # This should be kept in sync with nix.gc.options "--keep N" in
  # upgrade.nix so that boot entries match the retained generations.
  boot.loader.systemd-boot.configurationLimit = 5;

  # Linux LTS kernel (best stability with Nvidia drivers)
  boot.kernelPackages = pkgs.linuxPackages;

  # ── Nix settings ───────────────────────────────────────────────────
  # Enable the `nix` CLI and flakes (still marked experimental).
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Deduplicate identical files in the Nix store by hard-linking them
  # at write time. This prevents store bloat between periodic GC runs,
  # unlike nix.optimise.automatic which only deduplicates on a schedule.
  nix.settings.auto-optimise-store = true;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # System state version
  system.stateVersion = "25.05";
}
