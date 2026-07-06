{ config, pkgs, flakePath, ... }:

{
  # ── Flatpak ────────────────────────────────────────────────────────
  # Declarative Flatpak management via nix-flatpak (flake input).
  # Bambu Studio is here (not in systemPackages) because the nixpkgs
  # `bambu-studio` build currently ships a blank 3D viewport on
  # NVIDIA+Wayland — tracked by nixpkgs#498311 and PR #522161. The
  # Flathub build bundles its own GL/WebKit deps and works reliably.
  # Revisit moving to native once #522161 merges.
  services.flatpak = {
    enable = true;
    # Refresh installed flatpaks on every rebuild — keeps them in sync
    # with the weekly auto-upgrade rather than drifting out-of-band.
    update.onActivation = true;
    # Treat the `packages` list as the source of truth: any flatpak
    # installed imperatively that isn't listed here gets removed on
    # rebuild. Comment this out if you want to experiment with ad-hoc
    # `flatpak install` without losing the app on the next switch.
    uninstallUnmanaged = true;
    packages = [
      "com.bambulab.BambuStudio"
    ];
  };

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

  # Make nvim the default editor for anything that honors $EDITOR.
  environment.variables.EDITOR = "nvim";

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

    # ── Icon & GTK themes ────────────────────────────────────────────
    # GDM used to pull these in transitively. Now that the greeter is
    # Noctalia-under-greetd, no GNOME component drags them in — install
    # explicitly so the shell dock/launcher, Nautilus, and other GTK
    # apps can resolve icon names instead of falling back to hicolor
    # (which is mostly empty) and rendering broken-image placeholders.
    papirus-icon-theme  # primary: broad app + folder + MIME coverage
    adwaita-icon-theme  # fallback Papirus inherits from; Nautilus chrome
    gnome-themes-extra  # provides the Adwaita-dark GTK widget theme

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
    rsync               # File sync (used by claude-nas-sync)

    # ── Misc CLI ─────────────────────────────────────────────────────
    bat                 # Cat with syntax highlighting
    file                # File type identification
    which               # Locate commands in PATH
    gawk                # GNU awk
    jq                  # JSON processor
    zstd                # Zstandard compression
    gnupg               # GPG encryption
    openssl             # TLS/SSL toolkit and crypto CLI

    # ── Fun ──────────────────────────────────────────────────────────
    cmatrix             # Matrix rain animation
    unimatrix           # Unicode matrix rain
    fortune-kind        # Random kind/wholesome quotes

    # ── Monitoring ───────────────────────────────────────────────────
    # btop is managed via Home Manager (config/btop.nix) for theming.
    nvtopPackages.nvidia # Nvidia GPU process monitor
    ookla-speedtest     # ISP speed test (official Ookla binary)

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
    spotify             # Streaming music
    spicetify-cli       # Spotify UI customization
    ffmpeg              # Audio/video conversion and processing
    imagemagick         # Image conversion, resizing, and manipulation
    shotcut             # Video editor
    gimp3-with-plugins  # Image manipulation
    discord             # Voice and text chat
    halloy              # IRC client (Rust)
    libreoffice         # Office suite
    hunspell            # Spell checker (for LibreOffice)
    hunspellDicts.en_US # US English dictionary
    kdePackages.okular  # PDF viewer (annotations, forms, signatures)
    libgen-cli          # Library Genesis CLI

    # ── Database clients ─────────────────────────────────────────────
    postgresql          # psql, pg_dump, etc. (client only; no server)

    # ── Neovim  ──────────────────────────────────────────────────────
    # Config is managed by lazy.nvim (not Home Manager)
    # https://www.lazyvim.org/installation
    neovim
    gcc                 # C compiler for nvim-treesitter
    tree-sitter         # tree-sitter CLI (parser builds)
    fd                  # telescope file finder
    lazygit             # lazygit.nvim integration
    nodejs              # LazyVim Node provider / LSPs
    python3             # LazyVim Python provider / LSPs

    # ── AI ───────────────────────────────────────────────────────────
    claude-code

    # ── Hardware testing ─────────────────────────────────────────────
    spacenav-cube-example # 3Dconnexion SpaceMouse test app

  ];

}
