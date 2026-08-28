{
  config,
  pkgs,
  flakePath,
  ...
}: {
  # ── Flatpak ──
  services.flatpak = {
    enable = true;
    # Refresh flatpaks on each rebuild.
    update.onActivation = true;
    # Remove unlisted (imperative) flatpaks on rebuild.
    uninstallUnmanaged = true;
    packages = [];
  };

  # ── SpaceMouse ──
  # Start at boot even with no device plugged in.
  hardware.spacenavd.enable = true;
  systemd.services.spacenavd.wantedBy = ["multi-user.target"];

  # ── Gaming ──
  # Firewall rules for Remote Play / LAN play.
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
    localNetworkGameTransfers.openFirewall = true;
  };

  # Optimize CPU governor / GPU clocks while gaming.
  programs.gamemode.enable = true;

  # ── Shell & browser ──
  # Register Zsh as a valid login shell (config in config/shell.nix).
  programs.zsh.enable = true;

  # Firefox as the default browser.
  programs.firefox.enable = true;

  # ── Networking programs ──
  programs.localsend.enable = true;

  # ── Nix helper (nh) ──
  programs.nh = {
    enable = true;
    flake = flakePath;
  };

  # Default editor for $EDITOR.
  environment.variables.EDITOR = "nvim";

  # ── System packages ───────────────────────────────────────────────
  environment.systemPackages = with pkgs; [
    # ── Core utilities ───────────────────────────────────────────────
    git
    wget
    curl

    # ── Desktop utilities ────────────────────────────────────────────
    gthumb # GNOME image browser
    wl-clipboard # Wayland clipboard (wl-copy / wl-paste)
    wiremix # PipeWire audio mixer
    libnotify # Desktop notification CLI (notify-send)
    playerctl # MPRIS media player control (play/pause/next)
    chafa # Terminal image viewer (wallpaper preview, etc.)

    # ── Icon & GTK themes ──
    # Explicit now that no GNOME component drags them in.
    papirus-icon-theme # broad app + folder + MIME coverage
    adwaita-icon-theme # fallback Papirus inherits from
    gnome-themes-extra # Adwaita-dark GTK widget theme

    # ── File managers ────────────────────────────────────────────────
    nautilus # GNOME graphical file manager

    # ── Archive tools ────────────────────────────────────────────────
    zip
    xz
    unzip
    p7zip

    # ── CLI productivity ─────────────────────────────────────────────
    ripgrep # Fast recursive search (rg)
    fzf # Fuzzy finder for files, history, etc.
    tree # Recursive directory listing
    eza # Modern ls replacement with icons
    zoxide # Smart cd that learns your directories
    alejandra # Nix code formatter
    taplo # TOML formatter/linter (Cargo.toml, etc.)
    prettier # Formatter for Markdown/YAML/JSON/HTML/CSS (runs without package.json)
    tldr # Community-maintained command cheatsheets

    # ── Networking tools ─────────────────────────────────────────────
    mtr # Traceroute + ping combined
    iperf3 # Network bandwidth measurement
    dnsutils # dig, nslookup, host
    ldns # drill (DNS debugging)
    aria2 # Multi-protocol download accelerator
    socat # Multipurpose network relay
    nmap # Network scanner
    ipcalc # IP subnet calculator
    rsync # File sync (used by claude-nas-sync)

    # ── Backup tooling ──
    # B2 bucket/key CLI; binary is `backblaze-b2`, not `b2`.
    backblaze-b2

    # ── Misc CLI ─────────────────────────────────────────────────────
    bat # Cat with syntax highlighting
    file # File type identification
    which # Locate commands in PATH
    gawk # GNU awk
    jq # JSON processor
    zstd # Zstandard compression
    gnupg # GPG encryption
    openssl # TLS/SSL toolkit and crypto CLI

    # ── Fun ──────────────────────────────────────────────────────────
    cmatrix # Matrix rain animation
    unimatrix # Unicode matrix rain
    fortune-kind # Random quotes, less dumb
    neo-cowsay # cowsay reborn, in Go
    dotacat # like lolcat, but fast, in Rust
    figlet # make ascii block letters from text
    feedr # TUI RSS reader, in Rust

    # ── Monitoring ──
    # btop is in Home Manager (config/btop.nix).
    nvtopPackages.nvidia # Nvidia GPU process monitor
    ookla-speedtest # ISP speed test (official Ookla binary)

    # ── System debugging ─────────────────────────────────────────────
    strace # Trace system calls
    ltrace # Trace library calls
    lsof # List open files / sockets

    # ── System information ───────────────────────────────────────────
    sysstat # sar, iostat, mpstat
    lm_sensors # CPU/GPU temperature readings
    ethtool # Ethernet adapter diagnostics
    pciutils # lspci
    usbutils # lsusb
    microfetch # Minimal system info (shown on shell startup)
    fastfetch # Detailed system info
    vulkan-tools # vulkaninfo, etc.

    # ── Web browsers ─────────────────────────────────────────────────
    ungoogled-chromium # Chromium without Google services

    # ── Applications ─────────────────────────────────────────────────
    gh # GitHub CLI
    zed-editor # GPU-accelerated code editor
    obsidian # Markdown knowledge base
    signal-desktop # Encrypted messaging
    proton-pass # Password manager
    proton-vpn # VPN client
    proton-authenticator # TOTP 2FA manager
    rawtherapee # RAW photo editor
    obs-studio # Screen recording / streaming
    vlc # Media player
    spotify # Streaming music
    tauon # Local music player / library manager
    spicetify-cli # Spotify UI customization
    ffmpeg # Audio/video conversion and processing
    imagemagick # Image conversion, resizing, and manipulation
    shotcut # Video editor
    gimp3-with-plugins # Image manipulation
    discord # Voice and text chat
    halloy # IRC client (Rust)
    libreoffice # Office suite
    hunspell # Spell checker (for LibreOffice)
    hunspellDicts.en_US # US English dictionary
    kdePackages.okular # PDF viewer (annotations, forms, signatures)
    libgen-cli # Library Genesis CLI
    frogmouth # TUI Markdown reader
    asciinema # screen recorder for terminal sessions
    asciinema-agg # generate animated GIF files from asciicast files

    # ── 3D printing ──
    orca-slicer # 3D printer slicer (Bambu Studio fork)

    # ── Database clients ─────────────────────────────────────────────
    postgresql # psql, pg_dump, etc. (client only; no server)
    sqlite-interactive # sqlite3 CLI with readline (plain `sqlite` lacks line editing)
    sqlite-rsync # sqlite3_rsync — live-DB replication over ssh

    # ── Neovim ──
    # Config via lazy.nvim (not Home Manager).
    neovim
    gcc # C compiler for nvim-treesitter
    tree-sitter # tree-sitter CLI (parser builds)
    fd # telescope file finder
    lazygit # lazygit.nvim integration
    python3 # LazyVim Python provider / LSPs
     
    # ── Hardware testing ─────────────────────────────────────────────
    spacenav-cube-example # 3Dconnexion SpaceMouse test app
  ];
}
