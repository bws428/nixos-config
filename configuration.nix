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

  # Enable networking
  networking.networkmanager.enable = true;
  # networking.wireless.enable = true; # one or the other, NOT both!

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

  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # Enable the gnome-keyring secrets vault.
  # Will be exposed through DBus to programs willing to store secrets.
  services.gnome.gnome-keyring.enable = true;

  # Enable `tuigreet` and `greetd`
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.greetd.tuigreet}/bin/tuigreet -t --remember-session";
        user = "greeter";
      };
    };
  };

  # Enable Hyprland with UWSM
  # https://wiki.nixos.org/wiki/Hyprland
  programs.hyprland = {
    enable = true;
    withUWSM = true;
    xwayland.enable = true;
  };

  # Enable Mango window compositor
  # https://github.com/DreamMaoMao/mangowc
  programs.mango = {
    enable = true;
  };

  # Suggest Electron apps use Wayland
  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  # Let Stylix do the ricing... NOT
  stylix.enable = false;
  stylix.base16Scheme = "${pkgs.base16-schemes}/share/themes/gruvbox-dark-medium.yaml";
  stylix.image = ./themes/gruvbox-berries.jpg;

  # Updated font configuration for NixOS 25.05
  stylix.fonts = {
    monospace = {
      package = pkgs.nerd-fonts.meslo-lg;
      name = "MesloLGS Nerd Font Mono";
    };

    sansSerif = {
      package = pkgs.dejavu_fonts;
      name = "DejaVu Sans";
    };

    serif = {
      package = pkgs.dejavu_fonts;
      name = "DejaVu Serif";
    };

    sizes = {
      applications = 12;
      terminal = 14;
      desktop = 10;
      popups = 10;
    };
  };

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
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
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.bws428 = {
    isNormalUser = true;
    description = "Brian W.";
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [
      # Add these in Home Manager
    ];
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Install Firefox web browser
  programs.firefox.enable = true;

  # Install Steam + necessary firewall settings
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
    neovim # code editor
    wget # download files
    curl # download files
    kitty # terminal emulator
    zsh # the Z shell
    zsh-autosuggestions
    zsh-syntax-highlighting

    # Hyprland desktop
    mako # notification daemon
    walker # application launcher
    waybar # status bar
    hyprpaper # wallpaper
    hyprshot # screenshot
    hyprlock # lock screen
    hypridle
    hyprsunset # bluelight filter
    hyprnotify # notification daemon
    hyprcursor # mouse cursor

    # Mango desktop
    wmenu # does this even WORK?
    wl-clipboard
    grim # screenshot
    slurp # screenshot
    swaybg # wallpaper
    rofi-wayland # application launcher
    wev # Wayland event viewer (debugging)

  ];

  # Set the default editor to neovim
  environment.variables.EDITOR = "nvim";

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

  # Enable Flakes and new `nix-command`
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Enable nh
  programs.nh = {
    enable = true;
    clean.enable = true;
    clean.extraArgs = "--keep 3";
    flake = "/home/bws428/.nixos-config";
  };

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

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
