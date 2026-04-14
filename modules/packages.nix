{ config, pkgs, flakePath, ... }:

{
  # ── Flatpak ────────────────────────────────────────────────────────
  # Some apps (Bambu Studio, etc.) are easiest to run as Flatpaks.
  # https://flathub.org/en/setup/NixOS
  services.flatpak.enable = true;

  # ── SpaceMouse ─────────────────────────────────────────────────────
  # 3Dconnexion SpaceMouse driver. The wantedBy override ensures the
  # daemon starts at boot even if no device is plugged in yet.
  hardware.spacenavd.enable = true;
  systemd.services.spacenavd.wantedBy = [ "multi-user.target" ];

  # ── Gaming ─────────────────────────────────────────────────────────
  # Steam with firewall rules for Remote Play, dedicated servers,
  # and local network game transfers (LAN play).
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
    localNetworkGameTransfers.openFirewall = true;
  };

  # Feral GameMode — optimizes CPU governor, I/O priority, and GPU
  # clocks while a game is running.
  programs.gamemode.enable = true;

  # ── Shell & browser ────────────────────────────────────────────────
  # System-level Zsh enablement (the actual config lives in config/shell.nix
  # via Home Manager). Must be enabled here so NixOS registers it as a
  # valid login shell.
  programs.zsh.enable = true;

  # Firefox as the default browser.
  programs.firefox.enable = true;

  # ── Networking programs ────────────────────────────────────────────
  # LocalSend — local network file transfer (AirDrop alternative).
  # Automatically opens the required firewall port.
  programs.localsend.enable = true;

  # ── Nix helper (nh) ───────────────────────────────────────────────
  # https://github.com/nix-community/nh
  # A friendlier wrapper around nixos-rebuild and nix-collect-garbage.
  # `flake` tells it where to find the system flake by default.
  programs.nh = {
    enable = true;
    flake = flakePath;
  };

  # ── System packages ───────────────────────────────────────────────
  environment.systemPackages = with pkgs; [

    # ── Core utilities ───────────────────────────────────────────────
    git
    wget
    curl

    # ── Desktop utilities ────────────────────────────────────────────
    loupe               # GNOME image viewer
    wl-clipboard        # Wayland clipboard (wl-copy / wl-paste)
    wiremix             # PipeWire audio mixer
    wireplumber         # PipeWire session manager
    libnotify           # Desktop notification CLI (notify-send)
    playerctl           # MPRIS media player control (play/pause/next)
    chafa               # Terminal image viewer (wallpaper preview, etc.)

    # ── File managers ────────────────────────────────────────────────
    yazi                # Terminal file manager
    nautilus            # GNOME graphical file manager

    # ── Archive tools ────────────────────────────────────────────────
    zip
    xz
    unzip
    p7zip

    # ── CLI productivity ─────────────────────────────────────────────
    ripgrep             # Fast recursive search (rg)
    fzf                 # Fuzzy finder for files, history, etc.
    tree                # Recursive directory listing
    eza                 # Modern ls replacement with icons
    zoxide              # Smart cd that learns your directories
    alejandra           # Nix code formatter
    tldr                # Community-maintained command cheatsheets

    # ── Networking tools ─────────────────────────────────────────────
    mtr                 # Traceroute + ping combined
    iperf3              # Network bandwidth measurement
    dnsutils            # dig, nslookup, host
    ldns                # drill (DNS debugging)
    aria2               # Multi-protocol download accelerator
    socat               # Multipurpose network relay
    nmap                # Network scanner
    ipcalc              # IP subnet calculator

    # ── Misc CLI ─────────────────────────────────────────────────────
    uv                  # Fast Python package manager
    bat                 # Cat with syntax highlighting
    file                # File type identification
    which               # Locate commands in PATH
    gawk                # GNU awk
    zstd                # Zstandard compression
    gnupg               # GPG encryption

    # ── Fun ──────────────────────────────────────────────────────────
    cmatrix             # Matrix rain animation
    unimatrix           # Unicode matrix rain
    fortune-kind        # Random kind/wholesome quotes

    # ── Monitoring ───────────────────────────────────────────────────
    btop                # Interactive resource monitor
    nvtopPackages.nvidia # Nvidia GPU process monitor
    speedtest-cli       # ISP speed test

    # ── System debugging ─────────────────────────────────────────────
    strace              # Trace system calls
    ltrace              # Trace library calls
    lsof                # List open files / sockets

    # ── System information ───────────────────────────────────────────
    sysstat             # sar, iostat, mpstat
    lm_sensors          # CPU/GPU temperature readings
    ethtool             # Ethernet adapter diagnostics
    pciutils            # lspci
    usbutils            # lsusb
    microfetch          # Minimal system info (shown on shell startup)
    fastfetch           # Detailed system info
    vulkan-tools        # vulkaninfo, etc.

    # ── Web browsers ─────────────────────────────────────────────────
    ungoogled-chromium  # Chromium without Google services

    # ── Applications ─────────────────────────────────────────────────
    gh                  # GitHub CLI
    zed-editor          # GPU-accelerated code editor
    obsidian            # Markdown knowledge base
    signal-desktop      # Encrypted messaging
    proton-pass         # Password manager
    proton-vpn          # VPN client
    proton-authenticator # TOTP 2FA manager
    rawtherapee         # RAW photo editor
    obs-studio          # Screen recording / streaming
    vlc                 # Media player
    mpd                 # Music Player Daemon
    rmpc                # Rusty MPD client
    spotify             # Streaming music
    spicetify-cli       # Spotify UI customization
    shotcut             # Video editor
    gimp3-with-plugins  # Image manipulation
    discord             # Voice and text chat
    halloy              # IRC client (Rust)
    libreoffice         # Office suite
    hunspell            # Spell checker (for LibreOffice)
    hunspellDicts.en_US # US English dictionary
    libgen-cli          # Library Genesis CLI

    # ── AI ───────────────────────────────────────────────────────────
    claude-code

    # ── Hardware testing ─────────────────────────────────────────────
    spacenav-cube-example # 3Dconnexion SpaceMouse test app

  ];

}
