{ ... }:

{
  programs.wofi = {
    enable = true;
    settings = {
      width = 600;
      height = 400;
      location = "center";
      show = "drun";
      prompt = "Search...";
      filter_rate = 100;
      allow_markup = true;
      no_actions = true;
      halign = "fill";
      orientation = "vertical";
      content_halign = "fill";
      insensitive = true;
      allow_images = true;
      image_size = 32;
    };
    style = ''
      window {
        margin: 0px;
        border: 2px solid #7aa2f7;
        border-radius: 10px;
        background-color: rgba(26, 27, 38, 0.95);
      }

      #input {
        margin: 5px;
        border: none;
        border-radius: 5px;
        color: #c0caf5;
        background-color: #1a1b26;
      }

      #inner-box {
        margin: 5px;
        border: none;
        background-color: transparent;
      }

      #outer-box {
        margin: 5px;
        border: none;
        background-color: transparent;
      }

      #scroll {
        margin: 0px;
        border: none;
      }

      #text {
        margin: 5px;
        border: none;
        color: #c0caf5;
      }

      #entry:selected {
        background-color: rgba(122, 162, 247, 0.3);
        border-radius: 5px;
      }

      #entry:selected #text {
        color: #7aa2f7;
      }
    '';
  };
}
