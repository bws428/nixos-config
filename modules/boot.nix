{
  config,
  pkgs,
  ...
}: {
  # ── Bootloader ──
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Boot menu timeout before auto-selecting the default.
  boot.loader.timeout = 5;

  # Keep N boot entries (sync with nh clean --keep in upgrade.nix).
  boot.loader.systemd-boot.configurationLimit = 5;

  # ── Plymouth ──
  boot.plymouth.enable = true;
  boot.consoleLogLevel = 3;
  boot.initrd.verbose = false;

  # Latest mainline kernel (Granite Ridge iGPU amdgpu fixes).
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # ── USB ──
  # Cut USB descriptor timeout to dodge phantom-port retry storm.
  boot.kernelParams = ["usbcore.initial_descriptor_timeout=100"];

  # ── Nix ──
  # Enable flakes and the nix command.
  nix.settings.experimental-features = ["nix-command" "flakes"];

  # Hard-link dedup in the Nix store.
  nix.settings.auto-optimise-store = true;

  # Allow unfree packages.
  nixpkgs.config.allowUnfree = true;

  # System state version.
  system.stateVersion = "25.05";
}
