{
  config,
  pkgs,
  ...
}: {
  # ── Time zone ──
  time.timeZone = "America/New_York";

  # ── Locale ──
  # System locale and all LC_* categories to US English.
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  # ── Keyboard ──
  # X11/XWayland layout; Wayland clients use niri's config.kdl.
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };
}
