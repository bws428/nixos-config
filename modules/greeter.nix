{ config, pkgs, ... }:

{
  # ── Noctalia greeter (replaces GDM) ────────────────────────────────
  # The Noctalia greeter shares the shell's visual language, so the
  # login screen matches the lock screen — same wallpaper, same kape
  # palette. Module comes from the noctalia-greeter flake input (see
  # flake.nix); it enables greetd and sets its default_session to
  # noctalia-greeter-session. Docs: https://docs.noctalia.dev/v5/greeter/
  #
  # Unlike the old DMS greeter (which ran inside niri and re-copied
  # the user's theme on every greetd start), this one runs its own
  # bundled wlroots compositor, and wallpaper/palette sync is a
  # polkit-gated push FROM the shell: Noctalia Settings → Security →
  # Noctalia Greeter → Sync Now. Every sync prompts for an admin
  # password and can't be made passwordless: upstream's .policy file
  # (checked rev 3dcf1e4) gives the exec.path annotation a bare
  # filename instead of an absolute path, so pkexec never matches the
  # custom action and falls back to the generic auth_admin one — a
  # polkit YES rule for the action ID is dead code (tried and removed
  # 2026-07-04). Auto-Sync is therefore kept OFF (GUI state); the
  # greeter keeps whatever look the last manual sync pushed. State
  # lives in /var/lib/noctalia-greeter; logs in
  # /var/log/noctalia-greeter.log.
  #
  # Test path:
  #   sudo nixos-rebuild boot --flake .#ghost
  # Adds this as the default boot entry without activating live. If
  # the greeter wedges, pick the previous generation in the systemd-
  # boot menu (hold space at boot if the menu doesn't appear).
  programs.noctalia-greeter = {
    enable = true;

    # Preselect this user and the niri session (from the wayland-
    # sessions .desktop files installed by programs.niri) so login is
    # just typing the password.
    greeter-args = "--session niri --user bws428";

    # Written to /var/lib/noctalia-greeter/greeter.toml. Match the
    # session's cursor (home.pointerCursor in home.nix).
    settings = {
      cursor = {
        theme = "Adwaita";
        size = 24;
      };
    };
  };

  # ── Keyring auto-unlock under greetd ───────────────────────────────
  # GDM's PAM stack ran pam_gnome_keyring.so so the login password
  # unlocked the user's default keyring as a side effect. greetd's
  # PAM stack does not by default — without this line, Signal,
  # Chromium, Element, and anything else that talks to libsecret
  # would prompt for the keyring password on every launch.
  security.pam.services.greetd.enableGnomeKeyring = true;

  # ── Fallback: tuigreet ─────────────────────────────────────────────
  # If the Noctalia greeter wedges and bootloader rollback isn't the
  # right tool (e.g. you want to keep other config from this generation
  # active), swap to tuigreet — a minimal terminal greeter that runs
  # the same niri session command. To activate:
  #
  #   1. Comment out programs.noctalia-greeter above (the whole block
  #      — it sets greetd's default_session and will conflict with
  #      the block below).
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
