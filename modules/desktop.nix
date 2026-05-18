{ config, pkgs, quickshell, ... }:

{
  # ── Wayland compositors ────────────────────────────────────────────

  # Niri — a scrollable-tiling Wayland compositor.
  # https://wiki.nixos.org/wiki/Niri
  programs.niri.enable = true;

  # Dank Material Shell — a desktop shell environment.
  # https://danklinux.com
  programs.dms-shell.enable = true;

  # Use quickshell from master for idle monitoring (IdleMonitor API).
  programs.dms-shell.quickshell.package = quickshell.packages.x86_64-linux.default;

  # Enable XWayland for X11 compatibility (needed by Steam, Electron
  # apps, and other programs that don't support Wayland natively).
  programs.xwayland.enable = true;

  # ── Display manager ────────────────────────────────────────────────
  # Login screen is handled by the DMS greeter under greetd; see
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
