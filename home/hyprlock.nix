{ ... }:

{
  programs.hyprlock = {
    enable = true;
    settings = {
      general = {
        grace = 0;
        hide_cursor = true;
        no_fade_in = false;
      };

      background = [
        {
          monitor = "";
          path = "screenshot";
          blur_passes = 3;
          blur_size = 7;
          noise = 0.0117;
          contrast = 0.8916;
          brightness = 0.8172;
          vibrancy = 0.1696;
        }
      ];

      input-field = [
        {
          monitor = "";
          size = "300, 50";
          outline_thickness = 3;
          dots_size = 0.25;
          dots_spacing = 0.15;
          dots_center = true;
          outer_color = "rgba(122, 162, 247, 0.9)";
          inner_color = "rgba(26, 27, 38, 0.9)";
          font_color = "rgba(192, 202, 245, 1.0)";
          check_color = "rgba(158, 206, 106, 0.9)";
          fail_color = "rgba(247, 118, 142, 0.9)";
          capslock_color = "rgba(187, 154, 247, 0.9)";
          fade_on_empty = true;
          placeholder_text = "<span foreground=\"#7aa2f7\">Enter Password...</span>";
          rounding = 12;
          position = "0, -120";
          halign = "center";
          valign = "center";
        }
      ];

      label = [
        {
          monitor = "";
          text = "cmd[update:1000] echo \"<span foreground='#7aa2f7'>$(date +'%H:%M')</span>\"";
          font_size = 90;
          font_family = "JetBrains Mono";
          position = "0, 150";
          halign = "center";
          valign = "center";
        }
        {
          monitor = "";
          text = "cmd[update:1000] echo \"<span foreground='#bb9af7'>$(date +'%A, %B %d')</span>\"";
          font_size = 24;
          font_family = "JetBrains Mono";
          position = "0, 50";
          halign = "center";
          valign = "center";
        }
        {
          monitor = "";
          text = "<span foreground=\"#7dcfff\">$USER</span>";
          font_size = 18;
          font_family = "JetBrains Mono";
          position = "0, -180";
          halign = "center";
          valign = "center";
        }
      ];
    };
  };
}
