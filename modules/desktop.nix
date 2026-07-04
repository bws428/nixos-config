{ config, pkgs, ... }:

{
  # ── Wayland compositors ────────────────────────────────────────────

  # Niri — a scrollable-tiling Wayland compositor.
  # https://wiki.nixos.org/wiki/Niri
  programs.niri.enable = true;

  # ── Desktop shell: Noctalia v5 ─────────────────────────────────────
  # Noctalia (bar, launcher, lock screen, notifications, OSD) is a
  # Home Manager program — see config/noctalia.nix for the shell config
  # and flake.nix for the module wiring. It runs as a systemd user
  # service tied to graphical-session.target, so it starts with niri
  # and restarts on failure; no spawn-at-startup in niri's config.
  #
  # System-side prerequisites (per https://docs.noctalia.dev/v5/
  # getting-started/nixos/): NetworkManager and Bluetooth are enabled
  # in their own modules; the power daemons live here.

  # UPower — battery/energy reporting over D-Bus. No battery in this
  # desktop, but Noctalia's battery service expects it to answer.
  services.upower.enable = true;

  # power-profiles-daemon — backs Noctalia's power-profile switcher
  # (`noctalia msg power-cycle` and the Control Center toggle).
  services.power-profiles-daemon.enable = true;

  # Noctalia is not in nixpkgs yet; it builds from the upstream flake.
  # Pull pre-built binaries from upstream's cachix instead of
  # compiling the C++ shell locally. (This is why the noctalia input
  # does NOT follow our nixpkgs — see flake.nix.)
  nix.settings = {
    extra-substituters = [ "https://noctalia.cachix.org" ];
    extra-trusted-public-keys = [
      "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
    ];
  };

  # Enable XWayland for X11 compatibility (needed by Steam, Electron
  # apps, and other programs that don't support Wayland natively).
  programs.xwayland.enable = true;

  # ── Display manager ────────────────────────────────────────────────
  # Login screen is handled by the Noctalia greeter under greetd; see
  # modules/greeter.nix. GDM is kept here, commented, as a one-edit
  # fallback if the greeter/greetd path needs to be reverted without
  # rolling back the whole generation.
  #
  # services.displayManager.gdm = {
  #   enable = true;
  #   wayland = true;
  # };

  # ── Security ───────────────────────────────────────────────────────
  # Polkit handles privilege escalation prompts (e.g. "enter password
  # to install software") for desktop applications.
  security.polkit.enable = true;
  # security.pam.services.swaylock = {};

  # GNOME Keyring stores secrets (SSH keys, Wi-Fi passwords, app tokens)
  # and unlocks automatically on login.
  services.gnome.gnome-keyring.enable = true;

  # ── GTK / icon theme plumbing ──────────────────────────────────────
  # dconf is the settings backend GNOME apps (Nautilus, Loupe, etc.)
  # read their prefs from. GDM pulled this in transitively; without
  # it Nautilus can't persist sort order, sidebar pins, view mode, etc.
  programs.dconf.enable = true;

  # Rebuild the system-wide hicolor icon cache on activation so newly
  # added icon themes are discoverable to GTK apps. Auto-enabled when
  # GNOME is the DE; needs to be explicit now that it isn't.
  gtk.iconCache.enable = true;
}
