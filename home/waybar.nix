{ ... }:

{
  programs.waybar = {
    enable = true;
    settings = {
      mainBar = {
        layer = "top";
        position = "top";
        height = 30;
        spacing = 4;

        modules-left = [ "hyprland/workspaces" "hyprland/mode" ];
        modules-center = [ "clock" ];
        modules-right = [ "pulseaudio" "network" "cpu" "memory" "battery" "tray" ];

        "hyprland/workspaces" = {
          format = "{name}";
          on-click = "activate";
        };

        clock = {
          format = "{:%H:%M}";
          format-alt = "{:%Y-%m-%d %H:%M}";
          tooltip-format = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
        };

        cpu = {
          format = " {usage}%";
          tooltip = false;
        };

        memory = {
          format = " {}%";
        };

        battery = {
          states = {
            warning = 30;
            critical = 15;
          };
          format = "{icon} {capacity}%";
          format-charging = " {capacity}%";
          format-plugged = " {capacity}%";
          format-icons = [ "" "" "" "" "" ];
        };

        network = {
          format-wifi = " {signalStrength}%";
          format-ethernet = " {ipaddr}";
          format-disconnected = "Disconnected";
          tooltip-format = "{ifname}: {ipaddr}";
        };

        pulseaudio = {
          format = "{icon} {volume}%";
          format-bluetooth = " {volume}%";
          format-muted = "";
          format-icons = {
            default = [ "" "" "" ];
          };
          on-click = "pavucontrol";
        };

        tray = {
          spacing = 10;
        };
      };
    };

    style = ''
      * {
        font-family: JetBrainsMono Nerd Font;
        font-size: 13px;
      }

      window#waybar {
        background-color: rgba(26, 27, 38, 0.9);
        color: #c0caf5;
        border-bottom: 2px solid #7aa2f7;
      }

      #workspaces button {
        padding: 0 5px;
        color: #c0caf5;
        background: transparent;
        border: none;
        border-radius: 0;
      }

      #workspaces button:hover {
        background: rgba(122, 162, 247, 0.2);
      }

      #workspaces button.active {
        color: #7aa2f7;
        border-bottom: 2px solid #7aa2f7;
      }

      #clock,
      #battery,
      #cpu,
      #memory,
      #network,
      #pulseaudio,
      #tray {
        padding: 0 10px;
      }

      #battery.charging, #battery.plugged {
        color: #9ece6a;
      }

      #battery.critical:not(.charging) {
        color: #f7768e;
        animation: blink 0.5s linear infinite alternate;
      }

      @keyframes blink {
        to {
          color: #c0caf5;
        }
      }
    '';
  };
}
