{
  config,
  pkgs,
  ...
}: {
  # ── Bootloader (systemd-boot) ───────────────────────────────────────
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Time in seconds to show the boot menu before auto-selecting the default.
  boot.loader.timeout = 5;

  # Limit the number of NixOS generations listed in the boot menu.
  # Each `nixos-rebuild switch` adds a new entry; without a limit, old
  # entries accumulate and can fill the (often small) EFI System Partition.
  # This should be kept in sync with programs.nh.clean.extraArgs "--keep N"
  # in upgrade.nix so that boot entries match the retained generations.
  boot.loader.systemd-boot.configurationLimit = 5;

  # ── Plymouth boot splash ────────────────────────────────────────────
  # Show a graphical splash screen instead of text scroll during boot.
  # The default "bgrt" theme displays the motherboard vendor logo with
  # a NixOS-branded spinner. Press Escape to toggle back to text mode.
  boot.plymouth.enable = true;
  boot.consoleLogLevel = 3;
  boot.initrd.verbose = false;

  # Linux LTS kernel (best stability with Nvidia drivers)
  boot.kernelPackages = pkgs.linuxPackages;

  # ── USB phantom-port boot stall mitigation ──────────────────────────
  # This X870E board's firmware (AGESA bug) advertises a phantom device
  # on an unrouted internal root-hub port (usb1-port6); the kernel's
  # retry storm (`device descriptor read/64, error -110`) used to
  # dominate initrd. Cutting usbcore's 64-byte descriptor timeout from
  # 5000ms to 100ms makes those retries near-instant (initrd ~64s →
  # ~25s). Low risk: modern devices answer in well under 100ms. If a
  # slow USB device ever fails to enumerate at boot, raise to 250-500ms.
  #
  # PARTIAL fix by design: the remaining ~20s is xHCI address-setup
  # timeouts that no parameter touches. The port is absent from BIOS's
  # Single Port Control list, so it can't be disabled there; the only
  # real cure is a BIOS/AGESA update. Don't add udev rules (they race
  # the kernel hub thread) and don't strip initrd USB modules (caused
  # a keyboardless emergency-mode boot once).
  boot.kernelParams = ["usbcore.initial_descriptor_timeout=100"];

  # ── Nix settings ───────────────────────────────────────────────────
  # Enable the `nix` CLI and flakes (still marked experimental).
  nix.settings.experimental-features = ["nix-command" "flakes"];

  # Deduplicate identical files in the Nix store by hard-linking them
  # at write time. This prevents store bloat between periodic GC runs,
  # unlike nix.optimise.automatic which only deduplicates on a schedule.
  nix.settings.auto-optimise-store = true;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # System state version
  system.stateVersion = "25.05";
}
