# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  imports =
    [
      ./hardware-configuration.nix
      ./nvidia.nix
    ];

  # Bootloader (systemd)
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Use LTS kernel (so that NVIDIA drivers will build)
  # https://wiki.nixos.org/wiki/Linux_kernel
  boot.kernelPackages = pkgs.linuxPackages;

  # Define your hostname
  networking.hostName = "ghost";

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking (one or the other, NOT both)
  networking.networkmanager.enable = true;
  # networking.wireless.enable = true;

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

  # Bluetooth GUI for Mango
  services.blueman.enable = true;

  # Set your time zone.
  time.timeZone = "America/New_York";

  # Select internationalisation properties.
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

  # Keyboard layout
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Gnome Display Manager (NixOS 25.11+)
  # https://wiki.nixos.org/wiki/GNOME
  services.displayManager.gdm = {
    enable = true;
    wayland = true;
  };

  # Gnome Desktop Manager
  services.desktopManager.gnome.enable = true;

  # Gnome default application suite
  services.gnome = {
    games.enable = false;
    core-apps.enable = false;
    core-developer-tools.enable = false;
  };

  # Exclude unwanted Gnome packages
  environment.gnome.excludePackages = with pkgs; [
    gnome-tour gnome-user-docs
  ];

  # Enable Mango window compositor
  # https://github.com/DreamMaoMao/mangowc
  programs.mango.enable = true;

  # UWSM support for Mango
  programs.uwsm = {
    enable = true;
    waylandCompositors = {
      mango = {
        prettyName = "Mango";
        comment = "Mango compositor (UWSM)";
        binPath = "/run/current-system/sw/bin/mango";
      };
    };
  };

  # Add portal support for Mango
  xdg.portal = {
    enable = true;
    wlr.enable = true;  # wlroots-based portal (Mango uses wlroots)
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  };

  # Absolutely required for Mango
  services.dbus.implementation = "broker";

  # PolicyKit - needed for Mango? idk
  security.polkit.enable = true;

  # Suggest Electron apps use Wayland
  environment.sessionVariables.NIXOS_OZONE_WL = "1";

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
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Define a user account
  users.users.bws428 = {
    isNormalUser = true;
    description = "Brian W.";
    extraGroups = [ "networkmanager" "wheel" ];
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Install Firefox web browser
  programs.firefox.enable = true;

  # Install LocalSend and firewall configs
  programs.localsend.enable = true;

  # Enable nh
  # https://github.com/nix-community/nh
  programs.nh = {
    enable = true;
    clean.enable = true;
    clean.extraArgs = "--keep 3";
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
    kitty # terminal emulator
    zsh # the Z shell
    zsh-autosuggestions
    zsh-syntax-highlighting
    bluez # bluetooth protocol stack
    bluetui # bluetooth tui

    # Mango desktop
    wl-clipboard # cli copy/paste
    waybar # status bar
    grim # screenshot
    slurp # screenshot
    swaybg # wallpaper
    rofi # application launcher
    wev # Wayland event viewer (debugging)
    mako # notification daemon
    loupe # simple photo viewer
    nautilus # file browser gui
    wlogout # Wayland based logout menu

    # Gnome desktop extensions - rice it up!
    gnomeExtensions.space-bar
    gnomeExtensions.switcher
    gnomeExtensions.tactile
    gnomeExtensions.just-perfection

  ];

  # Set the default shell to Zsh
  # https://nixos.wiki/wiki/Zsh
  programs.zsh.enable = true;
  users.defaultUserShell = pkgs.zsh;

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

  # Enable Flakes and `nix-command` (experimental)
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Automatic system upgrades (with flakes)
  # https://wiki.nixos.org/wiki/Automatic_system_upgrades
  system.autoUpgrade = {
    enable = true;
    flake = inputs.self.outPath;
    flags = ["--print-build-logs"];
    dates = "weekly";
  };

  # Automatic system cleanup
  # https://wiki.nixos.org/wiki/Storage_optimization#Automation
  nix.gc = {
    automatic = true;
    dates = "daily";
    options = "--delete-older-than 10d";
  };
  nix.settings.auto-optimize-store = true;
  
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

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.05"; # Did you read the comment?
}
