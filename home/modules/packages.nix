{ config, pkgs, ... }:

{
  home.packages = with pkgs; [

    # Terminal file management
    nnn
    yazi

    # Archives
    zip
    xz
    unzip
    p7zip

    # Utils
    ripgrep # search tool
    jq
    yq-go
    fzf # fuzzy finder
    tree # recursive directory listing
    eza # a better `ls`
    zoxide # a better `cd`
    alejandra # nix code formatter
    dconf2nix # convert dconf config to Nix
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
    gnused
    gnutar
    gawk
    zstd
    gnupg
    cmatrix
    unimatrix
    fortune-kind

    # Nix related
    nix-output-monitor

    # Productivity
    hugo
    glow

    # Monitoring
    btop # cool resource monitor
    iotop
    iftop
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

    # Rust development
    rustup

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

  ];
}
