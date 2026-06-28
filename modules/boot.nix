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
  #
  # This X870E board (ASUS ProArt X870E-CREATOR WIFI, AGESA ComboAM5)
  # has a phantom root-hub port `usb1-port6` on the 800-series chipset
  # xHCI: firmware advertises a device that isn't there, so the kernel
  # loops `device descriptor read/64, error -110` for ~64s during initrd
  # and dominates boot time (initrd 1min6s of a ~2min total).
  #
  # The storm is 5 enumeration retries, each gated by usbcore's 64-byte
  # descriptor timeout (default 5000ms). Dropping it to 100ms makes each
  # retry near-instant, collapsing the ~64s stall to ~1-2s. Global, but
  # low-risk: modern devices answer the initial descriptor in well under
  # 100ms; the 5000ms default is conservative legacy headroom. If a
  # genuinely slow USB device ever fails to enumerate at boot, raise this
  # to 250-500ms (still cuts the stall to a few seconds).
  #
  # NOTE: this is a *mitigation*, not elimination — the kernel still
  # retries, just cheaply. The canonical fix is to disable the dead port
  # in BIOS (Advanced > USB Configuration > USB Single Port Control on
  # this ASUS board); the kernel then never enumerates it at all. A udev
  # `disable`/`early_stop` rule does NOT work here — it races the kernel
  # hub thread (the udev worker stalls behind the kernel's own probe), so
  # it's structurally downstream of the storm. See the 2026-06-28 removal
  # of the old modules/usb.nix, which had zero effect for exactly this
  # reason.
  boot.kernelParams = [ "usbcore.initial_descriptor_timeout=100" ];

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
