{ ... }:

{
  # ── USB quirks ───────────────────────────────────────────────────────
  #
  # Disable the phantom root-hub port `usb1-port6` on the AMD 800-series
  # chipset xHCI controller (PCI 1022:43fd at 0000:0d:00.0).
  #
  # Why: on this X870E board (AGESA ComboAM5 PI 1.2.7.0, BIOS 1804) the
  # kernel keeps trying to enumerate a device that isn't there on that
  # port, looping through `device descriptor read/64, error -110` retries
  # for ~60s. Because this happens while the root device is being waited
  # on, it shows up as a ~66s *initrd* stall and dominates boot time
  # (systemd-analyze: initrd 1min6s out of a ~2min total).
  #
  # This is a known, widespread AGESA/firmware bug across X870E boards
  # (ASUS/MSI/Gigabyte), not failing hardware — the port reports
  # `connect_type = "not used"`, i.e. nothing is meant to be connected.
  # AMD has not shipped a documented firmware fix, so we disable the dead
  # port at the OS level via the USB-core `disable` sysfs attribute.
  # `disable`/`early_stop` are first-class kernel interfaces for exactly
  # this; see Documentation/ABI/testing/sysfs-bus-usb.
  #
  # IMPORTANT — this must run in the *initrd*, not the main system, because
  # the stall happens during initrd before the root is mounted. We use
  # `boot.initrd.services.udev.rules` (the canonical option for initrd-time
  # udev rules; `services.udev.extraRules` would apply too late). It works
  # for both systemd and script initrd; this host runs systemd-in-initrd
  # because `boot.plymouth.enable` pulls it in.
  #
  # Safety: the keyboard (HHKB) lives on a *different* controller (bus 9),
  # so disabling this port cannot drop us into a keyboardless emergency
  # mode the way stripping initrd USB modules did (2026-06-23). The match
  # is anchored on BOTH the controller's PCI address (KERNELS) and the
  # port name (KERNEL), so it can only ever disable this one physical
  # port — never collateral. If a BIOS/kernel update renumbers the bus or
  # PCI path, the rule simply stops matching and the slow boot returns
  # (loud, obvious) rather than disabling the wrong port. Re-derive with:
  #   udevadm info -a -p $(find /sys/devices -name 'usb*-port*') | grep -B2 'not used'
  #
  # Revert: delete this module from flake.nix and rebuild. Nothing is
  # written to firmware.
  #
  # Validate after a reboot:
  #   systemd-analyze            # initrd should drop to a few seconds
  #   journalctl -b -k | grep '1-6'   # the error spam should be gone
  boot.initrd.services.udev.rules = ''
    ACTION=="add", KERNELS=="0000:0d:00.0", KERNEL=="usb1-port6", ATTR{disable}="1"
  '';
}
