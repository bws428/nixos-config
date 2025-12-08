{ config, pkgs, ... }:

{
  # Steam and firewall configs
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
    localNetworkGameTransfers.openFirewall = true;
  };

  # Enable gamemode for better gaming performance
  programs.gamemode.enable = true;

  # Zsh shell
  programs.zsh.enable = true;

  # Firefox bloat browser
  programs.firefox.enable = true;

  # LocalSend and firewall configs
  programs.localsend.enable = true;

  # Enable nh
  # https://github.com/nix-community/nh
  programs.nh = {
    enable = true;
    flake = "/home/bws428/.nixos-config";
  };

  # List of installed packages
  environment.systemPackages = with pkgs; [

    # Required system utilities
    git
    wget
    curl
    alacritty
    zsh-autosuggestions
    zsh-syntax-highlighting

    # Desktop utilities
    loupe # image viewer
    wl-clipboard # wayland clipboard
    ghostty  # Modern GPU-accelerated terminal (supports Kitty graphics protocol)
    swaybg
    swayidle
    swaylock
    mako
    wiremix
    wireplumber
    libnotify
    walker
    playerctl  # Media player control for waybar mpris module
    chafa  # Terminal image viewer for wallpaper preview

    # File managers
    yazi
    nautilus

    # Archive tools
    zip
    xz
    unzip
    p7zip

    # Utils
    ripgrep # search tool
    fzf # fuzzy finder
    tree # recursive directory listing
    eza # a better `ls`
    zoxide # a better `cd`
    alejandra # nix code formatter
    tldr # abbreviated man pages

    # Networking tools
    mtr
    iperf3
    dnsutils
    ldns
    aria2
    socat
    nmap
    ipcalc

    # Misc
    bat
    file
    which
    gawk
    zstd
    gnupg

    # Oddities
    cmatrix
    unimatrix
    fortune-kind

    # Monitoring
    btop # cool resource monitor
    nvtopPackages.nvidia # nvidia gpu monitor
    speedtest-cli # test ISP speed

    # System call monitoring
    strace
    ltrace
    lsof

    # System tools
    sysstat
    lm_sensors
    ethtool
    pciutils
    usbutils
    microfetch # very fast system info
    fastfetch # fast system info
    vulkan-tools # Vulkan driver info

    # Web broswers
    ungoogled-chromium # chrome, sans spyware

    # My Apps
    gh # Github CLI
    starship # custom shell prompt
    helix # code editor
    zed-editor # gui code editor
    obsidian # a second brain
    signal-desktop # secure comms
    rawtherapee # raw photo editor
    obs-studio # screencasting
    vlc # media player
    mpd # music player daemon
    rmpc # rusty music player client
    spotify # streaming music
    spicetify-cli # spice up spotify
    shotcut # video editor
    gimp3-with-plugins # image manipulation
    discord # voice and text chat
    halloy # irc client in Rust

    # Obligatory AI inclusion
    claude-code

  ];

}
