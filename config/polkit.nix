{ pkgs, ... }:

{
  # ── Polkit authentication agent ────────────────────────────────────
  # Polkit itself is a system daemon (enabled in modules/desktop.nix
  # via security.polkit.enable), but it needs a per-session GUI agent
  # to actually prompt the user for passwords. GNOME and KDE start
  # one automatically; niri doesn't, so without this Nautilus (and
  # anything else requiring auth_admin — mounting internal drives,
  # editing system network settings, etc.) silently fails with
  # "not authorized" because polkit has no way to ask for a password.
  #
  # polkit_gnome is the GTK-flavoured agent; it matches the rest of
  # the stack here (Nautilus, GDM, GNOME Keyring).
  home.packages = [ pkgs.polkit_gnome ];

  # Systemd user service that launches the agent when the graphical
  # session comes up and tears it down at logout. `journalctl --user
  # -u polkit-gnome-authentication-agent-1` for logs.
  systemd.user.services.polkit-gnome-authentication-agent-1 = {
    Unit = {
      Description = "polkit-gnome-authentication-agent-1";
      After = [ "graphical-session.target" ];
    };
    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
    Service = {
      Type = "simple";
      ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
      Restart = "on-failure";
      RestartSec = 1;
      TimeoutStopSec = 10;
    };
  };
}
