{ pkgs, ... }:

{
  home.packages = with pkgs; [
    # Terminal file management
    fastfetch
    nnn

    # Archives
    zip
    xz
    unzip
    p7zip

    # Utils
    ripgrep
    jq
    yq-go
    eza
    fzf

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
    cowsay
    file
    which
    tree
    gnused
    gnutar
    gawk
    zstd
    gnupg

    # Nix related
    nix-output-monitor

    # Productivity
    hugo
    glow

    # Monitoring
    btop
    iotop
    iftop

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
  ];
}
