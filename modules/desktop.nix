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
  # GDM (GNOME Display Manager) handles the graphical login screen
  # and session selection. Wayland mode avoids an unnecessary X server.
  services.displayManager.gdm = {
    enable = true;
    wayland = true;
  };

  # ── Security ───────────────────────────────────────────────────────
  # Polkit handles privilege escalation prompts (e.g. "enter password
  # to install software") for desktop applications.
  security.polkit.enable = true;
  # security.pam.services.swaylock = {};

  # GNOME Keyring stores secrets (SSH keys, Wi-Fi passwords, app tokens)
  # and unlocks automatically on login.
  services.gnome.gnome-keyring.enable = true;
}
