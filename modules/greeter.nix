{ config, pkgs, ... }:

{
  # ── DMS greeter (replaces GDM) ─────────────────────────────────────
  # The DankMaterialShell greeter runs the same UI as the DMS lock
  # screen under greetd, so the login screen ends up visually
  # identical to the lock screen — same wallpaper, same kape theme,
  # same colours. Module reference:
  # https://search.nixos.org/options?query=services.displayManager.dms-greeter
  #
  # Test path:
  #   sudo nixos-rebuild boot --flake .#ghost
  # Adds this as the default boot entry without activating live. If
  # the greeter wedges, pick the previous generation in the systemd-
  # boot menu (hold space at boot if the menu doesn't appear).
  services.displayManager.dms-greeter = {
    enable = true;

    # Run the greeter inside niri (same compositor as the user
    # session) so input handling, scaling, and HiDPI behave the same
    # at the greeter as post-login.
    compositor.name = "niri";

    # Source wallpaper, settings, and colours from this user's XDG
    # dirs. The systemd preStart in the upstream module copies them
    # into /var/lib/dms-greeter on each greetd start, so the greeter
    # stays in sync with whatever DMS Settings has set.
    configHome = "/home/bws428";

    # Save greeter + compositor output to /tmp/dms-greeter.log so the
    # first-boot failure mode is debuggable from TTY rather than a
    # blank screen with no breadcrumbs.
    logs.save = true;
  };

  # ── Keyring auto-unlock under greetd ───────────────────────────────
  # GDM's PAM stack ran pam_gnome_keyring.so so the login password
  # unlocked the user's default keyring as a side effect. greetd's
  # PAM stack does not by default — without this line, Signal,
  # Chromium, Element, and anything else that talks to libsecret
  # would prompt for the keyring password on every launch.
  security.pam.services.greetd.enableGnomeKeyring = true;

  # ── Fallback: tuigreet ─────────────────────────────────────────────
  # If the DMS greeter wedges and bootloader rollback isn't the right
  # tool (e.g. you want to keep other config from this generation
  # active), swap to tuigreet — a minimal terminal greeter that runs
  # the same niri session command. To activate:
  #
  #   1. Comment out services.displayManager.dms-greeter above (the
  #      whole block — it sets greetd's default_session and will
  #      conflict with the block below).
  #   2. Uncomment the block below.
  #   3. From TTY (Ctrl+Alt+F2): sudo nixos-rebuild switch --flake .#ghost
  #
  # services.greetd = {
  #   enable = true;
  #   settings.default_session = {
  #     command = "${pkgs.greetd.tuigreet}/bin/tuigreet --time --cmd niri-session";
  #     user = "greeter";
  #   };
  # };
}
