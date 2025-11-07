# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs,  ... }:

{
  imports = [];

  # Enable Bluetooth
  # https://nixos.wiki/wiki/Bluetooth
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings = {
      General = {
        Experimental = true;
        FastConnectable = true;
      };
      Policy = {
        AutoEnable = true;
      };
    };
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Add Brother printer drivers
  services.printing.drivers = [
    pkgs.brlaser
    pkgs.brgenml1lpr
    pkgs.brgenml1cupswrapper
  ];

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # Install Firefox web browser
  programs.firefox.enable = true;

  # Install LocalSend and firewall configs
  programs.localsend.enable = true;

  # Enable nh
  # https://github.com/nix-community/nh
  programs.nh = {
    enable = true;
    flake = "/home/bws428/.nixos-config";
  };

  # Install Steam and firewall configs
  # https://nixos.wiki/wiki/Steam
  programs.steam.enable = true;
  programs.steam = {
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
    localNetworkGameTransfers.openFirewall = true;
  };

  # List of packages installed in system profile
  environment.systemPackages = with pkgs; [

    # Required system utilities
    git # version control
    wget # download files
    curl # download files
    alacritty # terminal emulator
    zsh # the Z shell
    zsh-autosuggestions
    zsh-syntax-highlighting

    # Desktop helpers
    wl-clipboard # cli copy/paste
    loupe # simple photo viewer
    nautilus # gui file browser

  ];

  # Set the default shell to Zsh
  # https://nixos.wiki/wiki/Zsh
  programs.zsh.enable = true;

  # Add some Nerd Fonts
  # https://nixos.wiki/wiki/Fonts
  # https://mynixos.com/nixpkgs/packages/nerd-fonts
  fonts.packages = with pkgs.nerd-fonts; [
    droid-sans-mono
    fira-code
    hack
    inconsolata
    jetbrains-mono
    meslo-lg
    noto
    symbols-only
  ];

  # Automatic system upgrades (with flakes)
  # https://wiki.nixos.org/wiki/Automatic_system_upgrades
  system.autoUpgrade = {
    enable = true;
    flake = "/home/bws428/.nixos-config#";
    flags = ["--print-build-logs"];
    dates = "weekly";
  };

  # Automatic system cleanup
  # https://wiki.nixos.org/wiki/Storage_optimization
  nix.gc = {
    automatic = true;
    dates = "daily";
    options = "--delete-older-than 5d";
  };

  # Automatic system storage optimization
  # https://wiki.nixos.org/wiki/Storage_optimization
  nix.optimise.automatic = true;

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable OpenSSH
  # https://wiki.nixos.org/wiki/SSH
  services.openssh = {
    enable = true;
    ports = [ 22 ];
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";
    };
  };

  # Fail2ban to protect unauthorized SSH
  # https://wiki.nixos.org/wiki/Fail2ban
  services.fail2ban.enable = true;


}
