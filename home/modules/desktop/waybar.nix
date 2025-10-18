{ lib, ... }:

{
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

    # Font override
    style = lib.mkAfter ''
      * {
        font-size: 16px;
        font-family: MesloLGS Nerd Font Propo;
      }
    '';
  };
}
