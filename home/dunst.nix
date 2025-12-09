{ ... }:

{
  services.dunst = {
    enable = true;
    settings = {
      global = {
        width = 300;
        height = 300;
        offset = "30x50";
        origin = "top-right";
        transparency = 10;
        frame_color = "#7aa2f7";
        font = "JetBrainsMono Nerd Font 10";
        corner_radius = 10;
      };

      urgency_low = {
        background = "#1a1b26";
        foreground = "#c0caf5";
        timeout = 5;
      };

      urgency_normal = {
        background = "#1a1b26";
        foreground = "#c0caf5";
        timeout = 10;
      };

      urgency_critical = {
        background = "#1a1b26";
        foreground = "#f7768e";
        frame_color = "#f7768e";
        timeout = 0;
      };
    };
  };
}
