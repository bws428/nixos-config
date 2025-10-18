{ config, pkgs, lib, ... }:

{
  # TODO please change the username & home directory to your own
  home.username = "bws428";
  home.homeDirectory = "/home/bws428";

  # link the configuration file in current directory to the specified location in home directory
  # home.file.".config/i3/wallpaper.jpg".source = ./wallpaper.jpg;

  # link all files in `./scripts` to `~/.config/i3/scripts`
  # home.file.".config/i3/scripts" = {
  #   source = ./scripts;
  #   recursive = true;   # link recursively
  #   executable = true;  # make all files executable
  # };

  # encode the file content in nix configuration file directly
  # home.file.".xxx".text = ''
  #     xxx
  # '';

  # set cursor size and dpi for 4k monitor
  xresources.properties = {
    "Xcursor.size" = 16;
    "Xft.dpi" = 172;
  };

  # Packages that should be installed to the user profile.
  home.packages = with pkgs; [
    # here is some command line tools I use frequently
    # feel free to add your own or remove some of them

    fastfetch
    nnn # terminal file manager

    # archives
    zip
    xz
    unzip
    p7zip

    # utils
    ripgrep # recursively searches directories for a regex pattern
    jq # A lightweight and flexible command-line JSON processor
    yq-go # yaml processor https://github.com/mikefarah/yq
    eza # A modern replacement for ‘ls’
    fzf # A command-line fuzzy finder

    # networking tools
    mtr # A network diagnostic tool
    iperf3
    dnsutils  # `dig` + `nslookup`
    ldns # replacement of `dig`, it provide the command `drill`
    aria2 # A lightweight multi-protocol & multi-source command-line download utility
    socat # replacement of openbsd-netcat
    nmap # A utility for network discovery and security auditing
    ipcalc  # it is a calculator for the IPv4/v6 addresses

    # misc
    cowsay
    file
    which
    tree
    gnused
    gnutar
    gawk
    zstd
    gnupg

    # nix related
    #
    # it provides the command `nom` works just like `nix`
    # with more details log output
    nix-output-monitor

    # productivity
    hugo # static site generator
    glow # markdown previewer in terminal

    btop  # replacement of htop/nmon
    iotop # io monitoring
    iftop # network monitoring

    # system call monitoring
    strace # system call monitoring
    ltrace # library call monitoring
    lsof # list open files

    # system tools
    sysstat
    lm_sensors # for `sensors` command
    ethtool
    pciutils # lspci
    usbutils # lsusb
  ];

  # Waybar (enabling here for Stylix)
  programs.waybar = {
    enable = true;

    settings = {
      mainBar = {
        layer = "top";
        position = "top";
        height = 30;
        spacing = 4;

        modules-left = [ "hyprland/workspaces" ];
        modules-center = [ "hyprland/window" ];
        modules-right = [
          "backlight"
          "custom/check-online"
          "network"
          "cpu"
          "memory"
          "pulseaudio"
          "battery"
          "clock"
        ];

        "hyprland/workspaces" = {
          disable-scroll = true;
          all-outputs = true;
          on-click = "activate";
          format = "{name}";
        };

        clock = {
          tooltip-format = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
          format = "{:%Y-%m-%d  %H:%M}";
          format-alt = "{:%A, %B %d, %Y  %H:%M:%S}";
        };

        pulseaudio = {
          format = "  {volume}%";
          format-bluetooth = " {volume}%";
          format-muted = "  MUTE";
          format-muted-bluetooth = " MUTE";
          on-click = "pavucontrol";
        };

        backlight = {
          device = "intel_backlight";
          format = "🔆 {percent}%";
          on-scroll-up = "brightnessctl set 5%+";
          on-scroll-down = "brightnessctl set 5%-";
        };

        "custom/check-online" = {
          format = "{}";
          interval = 20;
          tooltip = true;
          tooltip-format = "Online Status";
          exec = "zsh /home/bws428/.config/waybar/scripts/check-online.sh";
        };

        network = {
          format-wifi = "  {essid} ({signalStrength}%)";
          format-ethernet = "󰈀  {bandwidthDownBytes}";
          tooltip-format = "{ifname} via {gwaddr} ";
          format-linked = "{ifname} (No IP) ";
          format-disconnected = "󰖪 ";
          format-alt = "{ifname}: {ipaddr}";
          on-click = "nm-connection-editor";
        };

        cpu = {
          format = " {usage}%";
          tooltip = false;
          on-click = "btop";
        };

        memory = {
          format = " {}%";
        };

        battery = {
          states = {
            warning = 30;
            critical = 15;
          };
          format = " {capacity}%";
          format-charging = " {capacity}%";
          format-plugged = " {capacity}%";
        };

        "custom/notifications" = {
          format = "🔔";
          tooltip = false;
          on-click = "makoctl invoke";
        };

        tray = {
          icon-size = 21;
          spacing = 10;
        };
      };
    };

    # Your font-size override
    style = lib.mkAfter ''
      * {
        font-size: 16px;
      }
    '';
  };

  # Zsh
  programs.zsh = {
    enable = true;
    shellAliases = {
        ls = "eza -lh --group-directories-first --icons=auto";
        rebuild = "sudo nixos-rebuild switch";
      };
  };
  programs.zsh.autosuggestion = {
    enable = true;
  };
  programs.zsh.syntaxHighlighting = {
    enable = true;
  };

  # starship - an customizable prompt for any shell
  programs.starship = {
    enable = true;
    # custom settings
    settings = {
      add_newline = false;
      aws.disabled = true;
      gcloud.disabled = true;
      line_break.disabled = true;
    };
  };

  # alacritty - a cross-platform, GPU-accelerated terminal emulator
  programs.alacritty = {
    enable = true;
    settings = {
      env.TERM = "xterm-256color";
      scrolling.multiplier = 5;
      selection.save_to_clipboard = true;
    };
  };

  # This value determines the Home Manager release that your
  # configuration is compatible with. This helps avoid breakage
  # when a new home Manager release introduces backwards
  # incompatible changes.
  #
  # You can update home Manager without changing this value. See
  # the home Manager release notes for a list of state version
  # changes in each release.
  home.stateVersion = "25.05";
}
